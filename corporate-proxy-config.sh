#!/bin/bash
echo "Script to play with work/school proxy"
name="!Ghost!"
email="aldyleongarcia@gmail.com"
echo "Autor: "$name
echo "Contact me: "$email

#Installer localpath
BASE_CONF=/home/$USER/opt/corporate_proxy
mkdir -p $BASE_CONF && cd $BASE_CONF

#Install the cntlm
bin_cntlm=$(command -v cntlm)
[ $bin_cntlm == "" ] && sudo apt install -y cntlm

echo "Check depends" 
echo "Is cntlm present: $bin_cntlm"

# Exit on bad cntlm installer
[ $bin_cntlm == "" ] && exit


echo "Basic account information"

echo "Username" && read USER_CNTLM
echo "Password" && read PASSWORD
echo "Domain" && read DOMAIN
echo "ip:port" && read DOMAIN_IP_PORT
echo "Direct Cntlm listen port" && read CNTLM_LISTEN_PORT
echo "Tunel HTTP listen port" && read HTTP_LISTEN_PORT
echo "Tunel Socks5 listen port" && read SOCKS_LISTEN_PORT
echo "Exclude from Proxy" 
echo "localhost, 127.0.0.*, 10.*, 192.168.*, *.uci.cu"
read NO_PROXY_LIST


echo "Proxy auto configuration settings"

echo "CNTLM_CONFIG"

echo "Write cntlm.conf"

CNTLM_CONFIG="$BASE_CONF/cntlm.conf"
cat >$CNTLM_CONFIG <<EOF
Username	$USER_CNTLM
Domain		$DOMAIN
Proxy		$DOMAIN_IP_PORT
NoProxy		$NO_PROXY_LIST
Listen		$CNTLM_LISTEN_PORT
Password    $PASSWORD
EOF

echo "CNTLM_PAC"

CNTLM_PAC="$BASE_CONF/proxy.pac"
cat >$CNTLM_PAC <<EOF
function FindProxyForURL (url, host) {
    if (isResolvable('youtube.com')) {
        return 'SOCKS5 127.0.0.1:$SOCKS_LISTEN_PORT; PROXY 127.0.0.1:$HTTP_LISTEN_PORT; DIRECT';  //vpn
    }
    if (isResolvable('cuota.uci.cu')) {
        return 'PROXY 127.0.0.1:$CNTLM_LISTEN_PORT; PROXY $DOMAIN_IP_PORT; DIRECT';   //cntlm
    }
    return 'DIRECT'; //no service
}
EOF


echo "CNTLM_APT"

CNTLM_APT="$BASE_CONF/apt-proxy"
cat >$CNTLM_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$CNTLM_LISTEN_PORT/";
EOF

echo "CNTLM_APT_SOCKS"

CNTLM_APT_SOCKS="$BASE_CONF/apt-socks5"
cat >$CNTLM_APT_SOCKS <<EOF
Acquire::http::proxy "socks5h://127.0.0.1:$SOCKS_LISTEN_PORT/";
EOF

echo "CNTLM_PIP"

CNTLM_PIP="$BASE_CONF/pip-cntlm"
cat >$CNTLM_PIP <<EOF
[global]
proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

echo "NEXUS_PIP"

CNTLM_PIP="$BASE_CONF/pip-nexus"
cat >$CNTLM_PIP <<EOF
[global]
timeout = 120
index = http://nexus.prod.uci.cu/repository/pypi-all/pypi
index-url = http://nexus.prod.uci.cu/repository/pypi-all/simple
[install]
trusted-host = nexus.prod.uci.cu

; Extra index to private pypi dependencies
; extra-index-url = http://nexus.prod.uci.cu/repository/pypi-all/simple
EOF

echo  "CNTLM_CURL"

CNTLM_CURL="$BASE_CONF/curlrc"
cat >$CNTLM_CURL <<EOF
proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

echo "CNTLM_GIT"

CNTLM_GIT="$BASE_CONF/gitconfig-proxy"
cat >$CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email

[http]
	proxy = http://127.0.0.1:$CNTLM_LISTEN_PORT
[https]
	proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

echo "NO_CNTLM_GIT"

NO_CNTLM_GIT="$BASE_CONF/gitconfig-no-proxy"
cat >$NO_CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email
EOF

echo "NPM_CNTLM"

NPM_CNTLM="$BASE_CONF/npmrc-proxy"
cat >$NPM_CNTLM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$CNTLM_LISTEN_PORT
https-proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

echo "NPM_NEXUS"

NEXUS="http://nexus.prod.uci.cu"
NPM_NEXUX=$NEXUS"/repository/npm-all"

NPM_CNTLM_NEXUS="$BASE_CONF/npmrc-proxy-nexus"
cat >$NPM_CNTLM_NEXUS <<EOF
strict-ssl=false
registry=$NPM_NEXUX
EOF

echo "CNTLM_TERMINAL"

CNTLM_TERMINAL="$BASE_CONF/cntlm-terminal"
cat >$CNTLM_TERMINAL <<EOF
export http_proxy=http://127.0.0.1:$CNTLM_LISTEN_PORT
export https_proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
export ftp_proxy=\$http_proxy
export no_proxy="$NO_PROXY_LIST"
export all_proxy=\$https_proxy
EOF


echo "CNTLM_TUNNEL_TERMINAL"

CNTLM_TUNNEL_TERMINAL="$BASE_CONF/cntlm-socks-terminal"
cat >$CNTLM_TUNNEL_TERMINAL <<EOF
export http_proxy=http://127.0.0.1:$HTTP_LISTEN_PORT
export https_proxy=\$http_proxy
export ftp_proxy=\$http_proxy
export no_proxy="$NO_PROXY_LIST"
export all_proxy=http://127.0.0.1:$SOCKS_LISTEN_PORT
EOF

exit

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
