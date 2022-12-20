#!/bin/bash

USER_FOLDER="/home/$USER"
BASE_CONF="$USER_FOLDER/opt/corporate_proxy"
BIN_FOLDER="$USER_FOLDER/bin"

# conf files
CNTLM_CONFIG="$BASE_CONF/cntlm.conf"

DIRECT_PAC="$BASE_CONF/direct.pac"
CNTLM_PAC="$BASE_CONF/cntlm.pac"
TUNNEL_PAC="$BASE_CONF/tunnel.pac"
SOCKS5_PAC="$BASE_CONF/socks5.pac"

CNTLM_APT="$BASE_CONF/apt-proxy"
TUNNEL_APT="$BASE_CONF/apt-tunnel"
SOCKS_APT="$BASE_CONF/apt-socks5"

CNTLM_PIP="$BASE_CONF/pip-cntlm"
TUNNEL_PIP="$BASE_CONF/pip-tunnel"
NEXUS_PIP="$BASE_CONF/pip-nexus"

CNTLM_CURL="$BASE_CONF/curlrc-cntlm"
TUNNEL_CURL="$BASE_CONF/curlrc-tunnel"

CNTLM_GIT="$BASE_CONF/gitconfig-proxy"
TUNNEL_GIT="$BASE_CONF/gitconfig-tunnel"
NO_PROXY_GIT="$BASE_CONF/gitconfig-no-proxy"

CNTLM_NPM="$BASE_CONF/npmrc-cntlm"
TUNNEL_NPM="$BASE_CONF/npmrc-tunnel"
NEXUS_NPM="$BASE_CONF/npmrc-nexus"

CNTLM_TERMINAL="$BASE_CONF/terminal-cntlm"
TUNNEL_TERMINAL="$BASE_CONF/terminal-tunnel"
SOCKS5_TERMINAL="$BASE_CONF/terminal-socks5"

CNTLM_ON="$BASE_CONF/cntlm_on"
TUNNEL_ON="$BASE_CONF/tunnel_on"
SOCKS5_ON="$BASE_CONF/socks5_on"
NEXUS_ON="$BASE_CONF/nexus_on"
CLEAN_PROXY="$BASE_CONF/clean_proxy"


SYSTEM_COPY="cp -rf"
SYSTEM_DEL="rm -rf"
SYSTEM_LINK="ln -svf"

SYSTEM_CNTLM_CONF="/etc/cntlm.conf"
SYSTEM_CNTLM_LOG="/tmp/cntlm.log"
SYSTEM_PROXY_APT="/etc/apt/apt.conf.d/99_proxy"
SYSTEM_PROXY_CURL="$USER_FOLDER/.curlrc"
SYSTEM_PROXY_NPM="$USER_FOLDER/.npmrc"
SYSTEM_PROXY_GIT="$USER_FOLDER/.gitconfig"
SYSTEM_PROXY_PIP="$USER_FOLDER/.config/pip"
SYSTEM_PROXY_PAC="$USER_FOLDER/proxy.pac"

SYSTEM_BIN_CNTLM="$BIN_FOLDER/cntlm-on"
SYSTEM_BIN_TUNNEL="$BIN_FOLDER/tunnel-on"
SYSTEM_BIN_SOCKS5="$BIN_FOLDER/socks5-on"
SYSTEM_BIN_NEXUS="$BIN_FOLDER/nexus-on"
SYSTEM_BIN_CLEAN="$BIN_FOLDER/proxy-off"

check_depends () {

	mkdir -p $BIN_FOLDER
	mkdir -p $BASE_CONF

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

}

get_user_info() {

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

}

set_cntlm() {

echo "$CNTLM_CONFIG"

cat >$CNTLM_CONFIG <<EOF
Username	$USER_CNTLM
Domain		$DOMAIN
Proxy		$DOMAIN_IP_PORT
NoProxy		$NO_PROXY_LIST
Listen		$CNTLM_HTTP_LISTEN_PORT
Password    $PASSWORD
EOF

}

set_proxy_pack(){

echo "$DIRECT_PAC"
cat >$DIRECT_PAC <<EOF
 function FindProxyForURL (url, host) {
  return 'DIRECT';
 }
EOF

echo "$CNTLM_PAC"
cat >$CNTLM_PAC <<EOF
 function FindProxyForURL (url, host) {
  if (isResolvable('cuota.uci.cu')) {
    return 'PROXY 127.0.0.1:$CNTLM_HTTP_LISTEN_PORT; DIRECT';
  }
  return 'DIRECT';
 }
EOF

echo "$TUNNEL_PAC"
cat >$TUNNEL_PAC <<EOF
 function FindProxyForURL (url, host) {
  return 'PROXY 127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT; DIRECT';
 }
EOF

echo "$TUNNEL_PAC"
cat >$TUNNEL_PAC <<EOF
 function FindProxyForURL (url, host) {
  return 'PROXY 127.0.0.1:$TUNNEL_SOCKS_LISTEN_PORT; DIRECT'; 
 }
EOF
}

echo "$CNTLM_APT"

cat >$CNTLM_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT/";
EOF


echo "$TUNNEL_APT"

cat >$TUNNEL_APT <<EOF
Acquire::http::proxy "http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
Acquire::ftp::proxy "ftp://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
Acquire::https::proxy "https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT/";
EOF


echo "$SOCKS_APT"

cat >$SOCKS_APT<<EOF
Acquire::http::proxy "socks5h://127.0.0.1:$SOCKS_LISTEN_PORT/";
EOF



echo "$CNTLM_PIP"

cat >$CNTLM_PIP <<EOF
[global]
proxy = https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF

echo "$TUNNEL_PIP"

cat >$TUNNEL_PIP <<EOF
[global]
proxy = https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF


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



echo  "$CNTLM_CURL"

cat >$CNTLM_CURL <<EOF
proxy=http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF


echo  "$TUNNEL_CURL"

cat >$TUNNEL_CURL <<EOF
proxy=http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF


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



echo "$NO_PROXY_GIT"

cat >$NO_PROXY_GIT <<EOF
[user]
	name = $NAME
	email = $EMAIL
EOF



echo "$CNTLM_NPM"

cat >$CNTLM_NPM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
https-proxy=https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF


echo "$TUNNEL_NPM"

cat >$TUNNEL_NPM <<EOF
strict-ssl=false
proxy=http://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
https-proxy=https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF


echo "$NEXUS_NPM"
cat >$NEXUS_NPM <<EOF
strict-ssl=false
registry=http://nexus.prod.uci.cu/repository/npm-all
EOF



echo "$CNTLM_TERMINAL"

cat >$CNTLM_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=https://127.0.0.1:$CNTLM_HTTP_LISTEN_PORT
EOF


echo "$TUNNEL_TERMINAL"

cat >$TUNNEL_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=https://127.0.0.1:$TUNNEL_HTTP_LISTEN_PORT
EOF



echo "$SOCKS5_TERMINAL"

cat >$SOCKS5_TERMINAL <<EOF
export no_proxy="$NO_PROXY_LIST"
export all_proxy=http://127.0.0.1:$SOCKS_LISTEN_PORT
EOF


echo "===Write cntlm_on==="


echo "$CNTLM_ON"
cat >"$CNTLM_ON" <<EOF
#!/bin/bash
echo "Copy cntlm configuration files"

sudo $SYSTEM_COPY $CNTLM_CONFIG $SYSTEM_CNTLM_CONF
sudo service cntlm restart >> $SYSTEM_CNTLM_LOG
echo "$SYSTEM_CNTLM_CONF"
cat "$SYSTEM_CNTLM_LOG"

echo ""
sudo $SYSTEM_COPY $CNTLM_PAC $SYSTEM_PROXY_PAC
echo "$SYSTEM_PROXY_PAC"
echo ""

sudo $SYSTEM_COPY $CNTLM_APT $SYSTEM_PROXY_APT
echo "$SYSTEM_PROXY_APT"

$SYSTEM_COPY $CNTLM_PIP $SYSTEM_PROXY_PIP
echo "$SYSTEM_PROXY_PIP"

$SYSTEM_COPY $CNTLM_CURL $SYSTEM_PROXY_CURL
echo "$SYSTEM_PROXY_CURL"

$SYSTEM_COPY $CNTLM_GIT $SYSTEM_PROXY_GIT
echo "$SYSTEM_PROXY_GIT"

$SYSTEM_COPY $CNTLM_NPM $SYSTEM_PROXY_NPM
echo "$SYSTEM_PROXY_NPM"


echo "Load global proxy terminal settings"
source $CNTLM_TERMINAL

#Close
bin_proxy_off=$(command -v proxy-off)
[ "\$bin_proxy_off" != "" ] && proxy-off

EOF


echo "===Write tunnel_on==="


echo "$TUNNEL_ON"
cat >"$TUNNEL_ON" <<EOF
#!/bin/bash
echo "Copy configuration files"

echo ""
sudo $SYSTEM_COPY $TUNNEL_PAC $SYSTEM_PROXY_PAC
echo "$SYSTEM_PROXY_PAC"
echo ""

sudo $SYSTEM_COPY $TUNNEL_APT $SYSTEM_PROXY_APT
echo "$SYSTEM_PROXY_APT"

$SYSTEM_COPY $TUNNEL_PIP $SYSTEM_PROXY_PIP
echo "$SYSTEM_PROXY_PIP"

$SYSTEM_COPY $TUNNEL_CURL $SYSTEM_PROXY_CURL
echo "$SYSTEM_PROXY_CURL"

$SYSTEM_COPY $TUNNEL_GIT $SYSTEM_PROXY_GIT
echo "$SYSTEM_PROXY_GIT"

$SYSTEM_COPY $TUNNEL_NPM $SYSTEM_PROXY_NPM
echo "$SYSTEM_PROXY_NPM"

echo "Load global proxy terminal settings"
source $TUNNEL_TERMINAL

#Close
bin_proxy_off=$(command -v proxy-off)
[ "\$bin_proxy_off" != "" ] && proxy-off

EOF


echo "===Write socks5_on==="


echo "$SOCKS5_ON"
cat >"$SOCKS5_ON" <<EOF
#!/bin/bash
echo "Copy  configuration files"

echo ""
sudo $SYSTEM_COPY $TUNNEL_PAC $SYSTEM_PROXY_PAC
echo "$SYSTEM_PROXY_PAC"
echo ""


sudo $SYSTEM_COPY $SOCKS_APT $SYSTEM_PROXY_APT
echo "$SYSTEM_PROXY_APT"

$SYSTEM_COPY $TUNNEL_PIP $SYSTEM_PROXY_PIP
echo "$SYSTEM_PROXY_PIP"

$SYSTEM_COPY $TUNNEL_CURL $SYSTEM_PROXY_CURL
echo "$SYSTEM_PROXY_CURL"

$SYSTEM_COPY $TUNNEL_GIT $SYSTEM_PROXY_GIT
echo "$SYSTEM_PROXY_GIT"

$SYSTEM_COPY $TUNNEL_NPM $SYSTEM_PROXY_NPM
echo "$SYSTEM_PROXY_NPM"

echo "Load global proxy terminal settings"
source $SOCKS5_TERMINAL

#Close
bin_proxy_off=$(command -v proxy-off)
[ "\$bin_proxy_off" != "" ] && proxy-off

EOF


echo "===Write nexus_on==="


echo "$NEXUS_ON"
cat >"$NEXUS_ON" <<EOF
#!/bin/bash
echo "Copy  configuration files"

echo ""
sudo $SYSTEM_COPY $DIRECT_PAC $SYSTEM_PROXY_PAC
echo "$SYSTEM_PROXY_PAC"
echo ""

$SYSTEM_COPY $NEXUS_PIP $SYSTEM_PROXY_PIP
echo "$SYSTEM_PROXY_PIP"

$SYSTEM_COPY $NO_PROXY_GIT $SYSTEM_PROXY_GIT
echo "$SYSTEM_PROXY_GIT"

$SYSTEM_COPY $NEXUS_NPM $SYSTEM_PROXY_NPM
echo "$SYSTEM_PROXY_NPM"

#Close
bin_proxy_off=$(command -v proxy-off)
[ "\$bin_proxy_off" != "" ] && proxy-off

EOF

echo "===Write clean_proxy==="


echo "$CLEAN_PROXY"
cat >"$CLEAN_PROXY" <<EOF
#!/bin/bash
echo "Remove configuration files"

sudo $SYSTEM_DEL $SYSTEM_CNTLM_CONF
sudo service cntlm stop >> $SYSTEM_CNTLM_LOG
echo "$SYSTEM_CNTLM_CONF"
cat "$SYSTEM_CNTLM_LOG"

sudo $SYSTEM_COPY $DIRECT_PAC $SYSTEM_PROXY_PAC
echo "$SYSTEM_PROXY_PAC"

sudo $SYSTEM_DEL $SYSTEM_PROXY_APT
echo "$SYSTEM_PROXY_APT"

$SYSTEM_DEL $SYSTEM_PROXY_PIP
echo "$SYSTEM_PROXY_PIP"

$SYSTEM_DEL $SYSTEM_PROXY_CURL
echo "$SYSTEM_PROXY_CURL"

$SYSTEM_COPY $NO_PROXY_GIT $SYSTEM_PROXY_GIT
echo "$SYSTEM_PROXY_GIT"

$SYSTEM_DEL $SYSTEM_PROXY_NPM
echo "$SYSTEM_PROXY_NPM"

export all_proxy=""
echo "clean terminal proxy"

EOF

BINARIES="$CNTLM_ON $TUNNEL_ON $SOCKS5_ON $NEXUS_ON $CLEAN_PROXY"

for bin in $BINARIES; do
	chmod +x $bin
	done;

$SYSTEM_LINK $CNTLM_ON $SYSTEM_BIN_CNTLM
$SYSTEM_LINK $TUNNEL_ON $SYSTEM_BIN_TUNNEL
$SYSTEM_LINK $SOCKS5_ON $SYSTEM_BIN_SOCKS5
$SYSTEM_LINK $NEXUS_ON $SYSTEM_BIN_NEXUS
$SYSTEM_LINK $CLEAN_PROXY $SYSTEM_BIN_CLEAN

echo "

Helper

cntlm-on	configure cntlm
tunnel-on	configure psiphon http
socks5-on	congigure socks5 psiphon
nexus-on	set nexus portals
proxy-off	clean all conf files"

[ "$1" == "remove" ] && {

echo "Clean all conf files"


exit
}

echo "Configure corporate proxy"
check_depends
get_user_info
echo "=====Writing configuration settings files====="
set_cntlm
set_proxy_pack
exit