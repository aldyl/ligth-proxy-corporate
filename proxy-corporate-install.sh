#!/bin/bash
echo "Usage: Install the proxy helper scripts"
name="Ing. Aldy Leon Garcia"
email="aldyleongarcia@gmail.com"
echo $name
echo $email

BASE_CONF=/home/$USER/opt/corporate_proxy
mkdir -p $BASE_CONF && cd $BASE_CONF

#Install the cntlm
sudo apt install -y cntlm

#Basic account information
echo "Username" && read USER_CNTLM
echo "Password" && read PASSWORD
echo "Domain" && read DOMAIN
echo "Domain ip:port" && read DOMAIN_IP_PORT
echo "Cntlm listen port" && read CNTLM_LISTEN_PORT
echo "Exclude from Proxy" 
echo "localhost, 127.0.0.*, 10.*, 192.168.*"
read NO_PROXY_LIST

## Proxy auto configuration settings | CNTLM_CONFIG
CNTLM_CONFIG="$BASE_CONF/cntlm.conf"
cat >$CNTLM_CONFIG <<EOF
Username	$USER_CNTLM
Domain		$DOMAIN
Proxy		$DOMAIN_IP_PORT
NoProxy		$NO_PROXY_LIST
Listen		$CNTLM_LISTEN_PORT
Password    $PASSWORD
EOF

## Proxy auto configuration settings
CNTLM_PAC="$BASE_CONF/proxy.pac"
cat >$CNTLM_PAC <<EOF
function FindProxyForURL (url, host) {
    if (isResolvable('youtube.com')) {
        return 'SOCKS5 127.0.0.1:1081; PROXY 127.0.0.1:8081; DIRECT';  //psiphon
    }
    if (isResolvable('cuota.uci.cu')) {//UCI
        return 'PROXY 127.0.0.1:$CNTLM_LISTEN_PORT; PROXY $DOMAIN_IP_PORT; DIRECT';   //cntlm
    }
    return 'DIRECT'; //no service
}
EOF

## Proxy auto configuration settings | APT
CNTLM_APT="$BASE_CONF/apt-proxy"
cat >$CNTLM_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$CNTLM_LISTEN_PORT/";
EOF

CNTLM_APT_SOCKS="$BASE_CONF/apt-socks5"
cat >$CNTLM_APT_SOCKS <<EOF
Acquire::http::proxy "socks5h://127.0.0.1:1081/";
EOF

## Proxy auto configuration settings | PIP
CNTLM_PIP="$BASE_CONF/pip.conf"
cat >$CNTLM_PIP <<EOF
[global]
proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

## Proxy auto configuration settings | CURL
CNTLM_CURL="$BASE_CONF/.curlrc"
cat >$CNTLM_CURL <<EOF
proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

## Proxy auto configuration settings | GIT
CNTLM_GIT="$BASE_CONF/.gitconfig_proxy"
cat >$CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email

[http]
	proxy = http://127.0.0.1:$CNTLM_LISTEN_PORT
[https]
	proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

NO_CNTLM_GIT="$BASE_CONF/.gitconfig_no_proxy"
cat >$NO_CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email
EOF

## Proxy auto configuration settings | NPM
NPM_CNTLM="$BASE_CONF/.npmrc_proxy"
cat >$NPM_CNTLM <<EOF
proxy=http://127.0.0.1:$CNTLM_LISTEN_PORT
https-proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

NEXUS="http://nexus.prod.uci.cu"
NPM_NEXUX=$NEXUS"/repository/npm-all"

NPM_CNTLM_NEXUS="$BASE_CONF/.npmrc_proxy_nexus"
cat >$NPM_CNTLM_NEXUS <<EOF
strict-ssl=false
registry=$NPM_NEXUX
EOF

## Make logic
bin="/home/$USER/bin"
mkdir -p $bin

## Copy proxy files
cat >"$bin/cntlm_on" <<EOF

#!/bin/bash

echo "Creating cntlm_on connection"

sudo cp -rf $CNTLM_CONFIG /etc/cntlm.conf
sudo service cntlm restart >> /tmp/cntlm_on.log

sudo cp -rf $CNTLM_APT /etc/apt/apt.conf.d/99_proxy
cp -rf $CNTLM_CURL /home/$USER/.curlrc

echo "Write [npm|nexus]"
read NPM_NEXUS
[ \$NPM_NEXUS = 'npm' ] && cp -rf $NPM_CNTLM /home/$USER/.npmrc
[ \$NPM_NEXUS = 'nexus' ] && cp -rf $NPM_CNTLM_NEXUS /home/$USER/.npmrc

cp -rf $CNTLM_GIT /home/$USER/.gitconfig

cp -rf $CNTLM_PIP /home/$USER/.config/pip

cp -rf  /home/$USER/.bashrc /home/$USER/.bashrc.bak

## Proxy auto configuration settings | TERMINAL
cat >> /home/$USER/.bashrc <<EOFa
export http_proxy=http://127.0.0.1:$CNTLM_LISTEN_PORT
export https_proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
export ftp_proxy=\$http_proxy
export no_proxy="$NO_PROXY_LIST"
export all_proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOFa

echo "cntlm_on ready"
EOF

## Remove proxy files
cat >"$bin/cntlm_off" <<EOF
#!/bin/bash
echo "Creating cntlm_off desconnection"

sudo rm -rf /etc/cntlm.conf
sudo service cntlm stop >> /tmp/cntlm_off.log

sudo rm -rf /etc/apt/apt.conf.d/99_proxy
rm -rf /home/$USER/.curlrc

rm -rf $NPM_CNTLM /home/$USER/.npmrc

rm -rf /home/$USER/.gitconfig
cp -rf $NO_CNTLM_GIT /home/$USER/.gitconfig

rm -rf /home/$USER/.config/pip

rm -rf  /home/$USER/.bashrc
mv /home/$USER/.bashrc.bak /home/$USER/.bashrc

echo "cntlm_off finished successfully"
EOF

sudo chmod +x $bin/cntlm_on
sudo chmod +x $bin/cntlm_off

echo "Helper

cntlm_on || cntlm_off
"
