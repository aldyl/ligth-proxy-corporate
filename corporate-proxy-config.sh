#!/bin/bash
echo "Configure corporate proxy"

#Installer localpath
BASE_CONF=/home/$USER/opt/corporate_proxy
mkdir -p $BASE_CONF && cd $BASE_CONF

#Install the cntlm
bin_cntlm=$(command -v cntlm)
[ "$bin_cntlm" == "" ] && sudo apt install -y cntlm

#Install the psiphon
bin_psiphon=$(command -v psiphon)
[ "$bin_psiphon" == "" ] && sudo apt install -y psiphon

echo "==Check depends" 
echo "=>Is cntlm present: $bin_cntlm"
echo "=>Is psiphon present: $bin_psiphon"

# On bad cntlm installer
[ $bin_cntlm == "" ] && echo "CNTLM is neccesary"

echo "=====Basic account information====="

echo "Name" && read name
echo "Email" && read email
echo "Username" && read USER_CNTLM
echo "Password" && read PASSWORD
echo "Domain" && read DOMAIN
echo "ip:port" && read DOMAIN_IP_PORT
echo "Direct Cntlm listen port" && read CNTLM_LISTEN_PORT
echo "Tunel HTTP listen port" && read HTTP_LISTEN_PORT
echo "Tunel Socks5 listen port" && read SOCKS_LISTEN_PORT
echo "Write a exclude from proxy line" 
echo "localhost, 127.0.0.*, 10.*, 192.168.*, *.uci.cu"
read NO_PROXY_LIST

echo "=====Writing configuration settings files====="

CNTLM_CONFIG="$BASE_CONF/cntlm.conf"
echo "$CNTLM_CONFIG"

cat >$CNTLM_CONFIG <<EOF
Username	$USER_CNTLM
Domain		$DOMAIN
Proxy		$DOMAIN_IP_PORT
NoProxy		$NO_PROXY_LIST
Listen		$CNTLM_LISTEN_PORT
Password    $PASSWORD
EOF


CNTLM_PAC="$BASE_CONF/proxy.pac"
echo "$CNTLM_PAC"
cat >$CNTLM_PAC <<EOF
 function FindProxyForURL (url, host) {
     
  if (isResolvable('cuota.uci.cu')) {
    return 'PROXY 127.0.0.1:3128; DIRECT';
  }
  
  return 'DIRECT';
  
 }
EOF


CNTLM_APT="$BASE_CONF/apt-proxy"
echo "$CNTLM_APT"

cat >$CNTLM_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$CNTLM_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$CNTLM_LISTEN_PORT/";
EOF


SOCKS_APT="$BASE_CONF/apt-socks5"
echo "$SOCKS_APT"

cat >$SOCKS_APT<<EOF
Acquire::http::proxy "socks5h://127.0.0.1:$SOCKS_LISTEN_PORT/";
EOF


CNTLM_PIP="$BASE_CONF/pip-cntlm"
echo "$CNTLM_PIP"

cat >$CNTLM_PIP <<EOF
[global]
proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF


NEXUS_PIP="$BASE_CONF/pip-nexus"
echo "$NEXUS_PIP"

cat >$NEXUS_PIP <<EOF
[global]
timeout = 120
index = http://nexus.prod.uci.cu/repository/pypi-all/pypi
index-url = http://nexus.prod.uci.cu/repository/pypi-all/simple
[install]
trusted-host = nexus.prod.uci.cu

; Extra index to private pypi dependencies
; extra-index-url = http://nexus.prod.uci.cu/repository/pypi-all/simple
EOF


CNTLM_CURL="$BASE_CONF/curlrc"
echo  "$CNTLM_CURL"

cat >$CNTLM_CURL <<EOF
proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF


CNTLM_GIT="$BASE_CONF/gitconfig-proxy"
echo "$CNTLM_GIT"

cat >$CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email
[http]
	proxy = http://127.0.0.1:$CNTLM_LISTEN_PORT
[https]
	proxy = https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF


NO_CNTLM_GIT="$BASE_CONF/gitconfig-no-proxy"
echo "$NO_CNTLM_GIT"

cat >$NO_CNTLM_GIT <<EOF
[user]
	name = $name
	email = $email
EOF


CNTLM_NPM="$BASE_CONF/npmrc-cntlm"
echo "$CNTLM_NPM"

cat >$CNTLM_NPM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$CNTLM_LISTEN_PORT
https-proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF

NEXUS_NPM="$BASE_CONF/npmrc-nexus"
echo "$NEXUS_NPM"
cat >$NEXUS_NPM <<EOF
strict-ssl=false
registry=http://nexus.prod.uci.cu/repository/npm-all
EOF


CNTLM_TERMINAL="$BASE_CONF/terminal-cntlm"
echo "$CNTLM_TERMINAL"

cat >$CNTLM_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=https://127.0.0.1:$CNTLM_LISTEN_PORT
EOF


SOCKS5_TERMINAL="$BASE_CONF/terminal-socks5"
echo "$SOCKS5_TERMINAL"

cat >$SOCKS5_TERMINAL <<EOF
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
[ \$NPM_NEXUS = 'npm' ] && cp -rf $CNTLM_NPM /home/$USER/.npmrc
[ \$NPM_NEXUS = 'nexus' ] && cp -rf $NEXUS_NPM /home/$USER/.npmrc

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

rm -rf $CNTLM_NPM /home/$USER/.npmrc

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
