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

echo "Name" && read NAME
echo "Email" && read EMAIL
echo "Username" && read USER_CNTLM
echo "Password" && read PASSWORD
echo "Proxy domain" && read DOMAIN
echo "ip:port" && read DOMAIN_IP_PORT
echo "Listen ports:"
echo "Cntlm http" && read CNTLM_HTTP_LISTEN_PORT
echo "Tunnel http" && read TUNNEL_HTTP_LISTEN_PORT
echo "Tunnel socks5" && read TUNNEL_SOCKS_LISTEN_PORT
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
Listen		$CNTLM_HTTP_LISTEN_PORT
Password    $PASSWORD
EOF


CNTLM_PAC="$BASE_CONF/cntlm.pac"
echo "$CNTLM_PAC"
cat >$CNTLM_PAC <<EOF
 function FindProxyForURL (url, host) {
     
  if (isResolvable('cuota.uci.cu')) {
    return 'PROXY 127.0.0.1:$CNTLM_HTTP_LISTEN_PORT; DIRECT';
  }
  
  return 'DIRECT';
  
 }
EOF


TUNNEL_PAC="$BASE_CONF/tunnel.pac"
echo "$TUNNEL_PAC"
cat >$TUNNEL_PAC <<EOF
 function FindProxyForURL (url, host) {

  return 'PROXY 127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT; DIRECT';
  
 }
EOF

CNTLM_APT="$BASE_CONF/apt-proxy"
echo "$CNTLM_APT"

cat >$CNTLM_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
EOF

TUNNEL_APT="$BASE_CONF/apt-tunnel"
echo "$TUNNEL_APT"

cat >$TUNNEL_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
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
proxy = https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

TUNNEL_PIP="$BASE_CONF/pip-tunnel"
echo "$TUNNEL_PIP"

cat >$TUNNEL_PIP <<EOF
[global]
proxy = https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
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


CNTLM_CURL="$BASE_CONF/curlrc-cntlm"
echo  "$CNTLM_CURL"

cat >$CNTLM_CURL <<EOF
proxy=http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

TUNNEL_CURL="$BASE_CONF/curlrc-tunnel"
echo  "$TUNNEL_CURL"

cat >$TUNNEL_CURL <<EOF
proxy=http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF

CNTLM_GIT="$BASE_CONF/gitconfig-proxy"
echo "$CNTLM_GIT"

cat >$CNTLM_GIT <<EOF
[user]
	name = $NAME
	email = $EMAIL
[http]
	proxy = http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
[https]
	proxy = https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

TUNNEL_GIT="$BASE_CONF/gitconfig-tunnel"
echo "$TUNNEL_GIT"

cat >$TUNNEL_GIT <<EOF
[user]
	name = $NAME
	email = $EMAIL
[http]
	proxy = http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
[https]
	proxy = https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF


NO_PROXY_GIT="$BASE_CONF/gitconfig-no-proxy"
echo "$NO_PROXY_GIT"

cat >$NO_PROXY_GIT <<EOF
[user]
	name = $NAME
	email = $EMAIL
EOF


CNTLM_NPM="$BASE_CONF/npmrc-cntlm"
echo "$CNTLM_NPM"

cat >$CNTLM_NPM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
https-proxy=https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

TUNNEL_NPM="$BASE_CONF/npmrc-tunnel"
echo "$TUNNEL_NPM"

cat >$TUNNEL_NPM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
https-proxy=https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
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
export all_proxy=https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

TUNNEL_TERMINAL="$BASE_CONF/terminal-tunnel"
echo "$TUNNEL_TERMINAL"

cat >$TUNNEL_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF


SOCKS5_TERMINAL="$BASE_CONF/terminal-socks5"
echo "$SOCKS5_TERMINAL"

cat >$SOCKS5_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=http://127.0.0.1:$SOCKS_LISTEN_PORT
EOF

SYSTEM_COPY="cp -rf"
SYSTEM_DEL="rm -rf"

SYSTEM_CNTLM_CONF="/etc/cntlm.conf"

SYSTEM_CNTLM_LOG="/tmp/cntlm.log"

SYSTEM_CNTLM_APT="/etc/apt/apt.conf.d/99_proxy"

SYSTEM_CNTLM_CURL="/home/$USER/.curlrc"

SYSTEM_CNTLM_NPM="/home/$USER/.npmrc"

SYSTEM_CNTLM_GIT="/home/$USER/.gitconfig"

SYSTEM_CNTLM_PIP="/home/$USER/.config/pip"

echo "===Write cntlm_on==="

CNTLM_ON="$BASE_CONF/cntlm_on"
echo "$CNTLM_ON"
cat >"$CNTLM_ON" <<EOF
#!/bin/bash
echo "Copy cntlm configuration files"

sudo $SYSTEM_COPY $CNTLM_CONFIG $SYSTEM_CNTLM_CONF
sudo service cntlm restart >> $SYSTEM_CNTLM_LOG
echo "$SYSTEM_CNTLM_CONF"
cat "$SYSTEM_CNTLM_LOG"

echo ""
echo "$CNTLM_PAC"
cat "$CNTLM_PAC"
echo ""

sudo $SYSTEM_COPY $CNTLM_APT $SYSTEM_CNTLM_APT
echo "$SYSTEM_CNTLM_APT"

$SYSTEM_COPY $CNTLM_PIP $SYSTEM_CNTLM_PIP
echo "$SYSTEM_CNTLM_PIP"

$SYSTEM_COPY $CNTLM_CURL $SYSTEM_CNTLM_CURL
echo "$SYSTEM_CNTLM_CURL"

$SYSTEM_COPY $CNTLM_GIT $SYSTEM_CNTLM_GIT
echo "$SYSTEM_CNTLM_GIT"

$SYSTEM_COPY $CNTLM_NPM $SYSTEM_CNTLM_NPM
echo "$SYSTEM_CNTLM_NPM"


echo "Load global proxy terminal settings"
source $CNTLM_TERMINAL

EOF


echo "===Write tunnel_on==="

TUNNEL_ON="$BASE_CONF/tunnel_on"
echo "$TUNNEL_ON"
cat >"$TUNNEL_ON" <<EOF
#!/bin/bash
echo "Copy configuration files"

echo ""
echo "$TUNNEL_PAC"
cat "$TUNNEL_PAC"
echo ""

sudo $SYSTEM_COPY $TUNNEL_APT $SYSTEM_CNTLM_APT
echo "$SYSTEM_CNTLM_APT"

$SYSTEM_COPY $TUNNEL_PIP $SYSTEM_CNTLM_PIP
echo "$SYSTEM_CNTLM_PIP"

$SYSTEM_COPY $TUNNEL_CURL $SYSTEM_CNTLM_CURL
echo "$SYSTEM_CNTLM_CURL"

$SYSTEM_COPY $TUNNEL_GIT $SYSTEM_CNTLM_GIT
echo "$SYSTEM_CNTLM_GIT"

$SYSTEM_COPY $TUNNEL_NPM $SYSTEM_CNTLM_NPM
echo "$SYSTEM_CNTLM_NPM"

echo "Load global proxy terminal settings"
source $TUNNEL_TERMINAL

EOF


echo "===Write socks5_on==="

SOCKS5_ON="$BASE_CONF/socks5_on"
echo "$SOCKS5_ON"
cat >"$SOCKS5_ON" <<EOF
#!/bin/bash
echo "Copy  configuration files"

echo ""
echo "$TUNNEL_PAC"
cat "$TUNNEL_PAC"
echo ""

sudo $SYSTEM_COPY $SOCKS_APT $SYSTEM_CNTLM_APT
echo "$SYSTEM_CNTLM_APT"

$SYSTEM_COPY $TUNNEL_PIP $SYSTEM_CNTLM_PIP
echo "$SYSTEM_CNTLM_PIP"

$SYSTEM_COPY $TUNNEL_CURL $SYSTEM_CNTLM_CURL
echo "$SYSTEM_CNTLM_CURL"

$SYSTEM_COPY $TUNNEL_GIT $SYSTEM_CNTLM_GIT
echo "$SYSTEM_CNTLM_GIT"

$SYSTEM_COPY $TUNNEL_NPM $SYSTEM_CNTLM_NPM
echo "$SYSTEM_CNTLM_NPM"

echo "Load global proxy terminal settings"
source $SOCKS5_TERMINAL

EOF


echo "===Write nexus_on==="

NEXUS_ON="$BASE_CONF/nexus_on"
echo "$NEXUS_ON"
cat >"$NEXUS_ON" <<EOF
#!/bin/bash
echo "Copy  configuration files"

$SYSTEM_COPY $NEXUS_PIP $SYSTEM_CNTLM_PIP
echo "$SYSTEM_CNTLM_PIP"

$SYSTEM_COPY $NO_PROXY_GIT $SYSTEM_CNTLM_GIT
echo "$SYSTEM_CNTLM_GIT"

$SYSTEM_COPY $NEXUS_NPM $SYSTEM_CNTLM_NPM
echo "$SYSTEM_CNTLM_NPM"

EOF

echo "===Write clean_proxy==="

CLEAN_PROXY="$BASE_CONF/clean_proxy"
echo "$CLEAN_PROXY"
cat >"$CLEAN_PROXY" <<EOF
#!/bin/bash
echo "Remove configuration files"

sudo $SYSTEM_DEL $SYSTEM_CNTLM_CONF
sudo service cntlm stop >> $SYSTEM_CNTLM_LOG
echo "$SYSTEM_CNTLM_CONF"
cat "$SYSTEM_CNTLM_LOG"

sudo $SYSTEM_DEL $SYSTEM_CNTLM_APT
echo "$SYSTEM_CNTLM_APT"

$SYSTEM_DEL $SYSTEM_CNTLM_PIP
echo "$SYSTEM_CNTLM_PIP"

$SYSTEM_DEL $SYSTEM_CNTLM_CURL
echo "$SYSTEM_CNTLM_CURL"

$SYSTEM_COPY $NO_PROXY_GIT $SYSTEM_CNTLM_GIT
echo "$SYSTEM_CNTLM_GIT"

$SYSTEM_DEL $SYSTEM_CNTLM_NPM
echo "$SYSTEM_CNTLM_NPM"

export all_proxy=""
echo "clean terminal proxy"

EOF




exit
sudo chmod +x $bin/cntlm_on
sudo chmod +x $bin/cntlm_off

echo "Helper

cntlm_on || cntlm_off
"

## Make logic
bin="/home/$USER/bin"
mkdir -p $bin