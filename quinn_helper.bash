#!/bin/bash

set -u
set -e

hostname=$( hostname )

[[ root != $( whoami ) ]] && {
	echo "no root priviliges"
	exit
}

function show_title {
echo "[31;1m"
echo "===================="
echo "= $1"
echo "===================="
echo "[0m"
}

########################################
show_title "Fix Network"

grep -q 'eth0' /etc/network/interfaces || {
{
	echo "auto eth0"
	echo "iface eth0 inet dhcp"
} >> /etc/network/interfaces
service networking restart
}

########################################
# adapt the sources to the fit version of ubuntu, the default version is for 14.04
show_title "Configure apt-get for Ubuntu 14.04"
cat <<EOF >/etc/apt/sources.list
deb http://ftp.nankai.edu.cn/ubuntu/ trusty main multiverse restricted universe
deb http://ftp.nankai.edu.cn/ubuntu/ trusty-backports main multiverse restricted universe
deb http://ftp.nankai.edu.cn/ubuntu/ trusty-proposed main multiverse restricted universe
deb http://ftp.nankai.edu.cn/ubuntu/ trusty-security main multiverse restricted universe
deb http://ftp.nankai.edu.cn/ubuntu/ trusty-updates main multiverse restricted universe
deb-src http://ftp.nankai.edu.cn/ubuntu/ trusty main multiverse restricted universe
deb-src http://ftp.nankai.edu.cn/ubuntu/ trusty-backports main multiverse restricted universe
deb-src http://ftp.nankai.edu.cn/ubuntu/ trusty-proposed main multiverse restricted universe
deb-src http://ftp.nankai.edu.cn/ubuntu/ trusty-security main multiverse restricted universe
deb-src http://ftp.nankai.edu.cn/ubuntu/ trusty-updates main multiverse restricted universe
EOF
apt-get update

########################################
show_title "Install proftpd"
apt-get install -y proftpd

########################################
show_title "adjusting time"
apt-get install -y rdate
rdate -n ntp.sjtu.edu.cn

########################################
# other softwares could be added here
show_title "Install softwares"
apt-get install -y g++ gcc gfortran make build-essential binutils vim expect sl sysvbanner gawk sysv-rc-conf beep icewm tightvncserver xterm flex bison openvpn cpanminus unzip unrar lm-sensors gftp x11-apps pm-utils bsdgames lftp ethtool

########################################
show_title "Install openjdk"
apt-get install -y openjdk-7-dbg openjdk-7-demo openjdk-7-doc openjdk-7-jdk
grep -q 'JAVA_HOME' /etc/environment || {
echo 'JAVA_HOME="/usr/lib/jvm/java-1.6.0-openjdk"' >>/etc/environment
}

########################################
show_title "Configure vim"
grep -q 'quinn' /etc/vim/vimrc || {
echo -n '
" Added by quinn
syntax on
set hlsearch
set incsearch
set autoindent
set tabstop=4
filetype indent on
' >> /etc/vim/vimrc
}
sed -i.bak 's/c.vim/cpp.vim/' /usr/share/vim/vim74/syntax/cuda.vim

########################################
show_title "Configure Apache2"
grep -q 'ServerName' /etc/apache2/apache2.conf || {
echo -n "
# Added by quinn
ServerName $hostname-HTTP
"  >> /etc/apache2/apache2.conf
a2enmod userdir
service apache2 restart
}

########################################
show_title "Configure sshd"
grep -q 'UseDNS' /etc/ssh/sshd_config || {
echo -n "
# Added by quinn
UseDNS no
"  >> /etc/ssh/sshd_config
service ssh restart
}
sed -i.bak '/^session.*motd/s/^/# /' /etc/pam.d/sshd

rm -rf /home/$LOGNAME/.ssh
sudo -u $LOGNAME ssh-keygen -t rsa -f /home/$LOGNAME/.ssh/id_rsa -P ''

########################################
show_title "Add users"

function add_user {
	local username="$1"
	local desc="$2"
	local pass="${3:-password}"
	local sudo="${4:+sudo,}"
	id "$username" &>/dev/null || {
		echo "Adding user: $username ..."
		useradd -m -s /bin/bash -G "adm,cdrom,${sudo}dip,plugdev,lpadmin,sambashare" -c "$desc" "$username"
		echo -e "$pass\n$pass\n" | passwd "$username"
	}
}

add_user quinn		'Quinn'			'quinn'		'sudo'
add_user hadoop		'Hadoop User'		'password'
add_user parallel	'Guest User'		'parallel'

########################################
show_title "Configure sudo"
echo -n '/^%sudo/c
%sudo ALL=NOPASSWD: ALL
.
wq
' | EDITOR=ed visudo

########################################
show_title "Adding aliases and functions"

cat <<EOF >/etc/profile.d/alias.sh
alias +='pushd .'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias /='cd /'
alias Beep='sudo /usr/bin/beep'
alias dh='df -h'
alias duh='du -h'
alias duhd='du -h --max-depth=1'
alias dir='ls -l'
alias g2u='iconv -c -f GBK -t UTF-8'
alias l='ls -alF'
alias la='ls -la'
alias ll='ls -l'
alias md='mkdir -p'
alias o='less'
alias r='fc -s'
alias rd='rmdir'
alias rr='rm -r'
alias u2g='iconv -c -f UTF-8 -t GBK'
alias bl='bc -l'
EOF

cat <<EOF >/etc/profile.d/function.sh
# For customize vim new file
v () {
  (( \$# < 4 )) && {
    echo 'Usage: v <extension> <file-mode> <vim-offset> <initial-content> <file-name>...'
    return 1
  }
  local    ext=\$1; shift
  local  fmode=\$1; shift
  local offset=\$1; shift
  local     ic=\$1; shift

  (( \$# == 0 )) && {
    vim
  }

  while [ -n "\$1" ]; do
    local fn
    if [ -z "\$ext" ]; then
      fn="\$1"
    else
      fn="\${1%\${ext}}"
      fn="\${fn%.}.\$ext"
    fi
    if [ -e "\$fn" ]; then
      if [ -f "\$fn" -a -w "\$fn" ]; then
        vim "\$offset" "\$fn"
      else
        echo "Error: cannot write \$fn" > 2
        read -n 1 -s
      fi
    else
      touch "\$fn" || {
        echo "Error: cannot create \$fn" > 2
        read -n 1 -s
        shift
        continue
      }
      echo -n "\$ic" >> "\$fn"
      chmod "\$fmode" "\$fn"
      vim "\$offset" "\$fn"
    fi
    shift
  done
}

alias vperl="v pl 755 + \\"#!\$( which perl ) -w

############################
# Created by $LOGNAME
############################

use 5.010;
use utf8;

\\""

alias vphp="v php 644 +6 '<!DOCTYPE html PUBLIC \\"-//W3C//DTD XHTML 1.0 Transitional//EN\\"
	\\"http://www.w3.ort/TR/xhtml1/DTE/xhtml1-transitional.dtd\\">
<html xmlns=\\"http://www.w3.ort/1999/xhtml\\" xml:lang=\\"en\\" lang=\\"en\\">
<head>
  <meta http-equiv=\\"content-type\\" content=\\"text/html; charset=UTF-8\\">
  <title></title>
</head>

<body>
<?php

?>
</body>
</html>
'"

alias vawk="v awk 755 +8 \\"#!\$( which awk ) -f

############################
# Created by $LOGNAME
############################

# \$( date +%F\\ %T )
# This script is used to 
\\""

alias vbash="v \\"\\" 755 +8 \\"#!\$( which bash )

############################
# Created by $LOGNAME
############################

# \$( date +%F\\ %T )
# This script is used to 
\\""

alias vhtml="v html 644 +6 '<!DOCTYPE html PUBLIC \\"-//W3C//DTD XHTML 1.0 Transitional//EN\\"
	\\"http://www.w3.ort/TR/xhtml1/DTE/xhtml1-transitional.dtd\\">
<html xmlns=\\"http://www.w3.ort/1999/xhtml\\" xml:lang=\\"en\\" lang=\\"en\\">
<head>
  <meta http-equiv=\\"content-type\\" content=\\"text/html; charset=UTF-8\\">
  <title></title>
</head>

<body>
</body>
</html>
'"

alias vc="v c 644 +'set cin' \\"#include <stdio.h>

int main ( ) {
	int i, j;

	return 0;
}
\\""

alias vcc="v cpp 644 +'set cin' \\"#include <stdio.h>

int main ( ) {
	int i, j;

	return 0;
}
\\""

alias vcpp="v cpp 644 +'set cin' \\"#include <cstdio>

using namespace std;

int main ( ) {
	int i, j;

	return 0;
}
\\""

alias vcuda="v cu 644 +'set cin' \\"#include <cstdio>

using namespace std;

__global__ void kernel ( ) {
}

int main ( ) {
	int i, j;

	return 0;
}
\\""

alias vtex="v tex 644 +3 \\"\\\\documentclass[]{article}
\\\\begin{document}

\\\\end{document}
\\""

manpdf () {
  while (( \$# )); do
    LANG=C man -Tdvi "\$1" > "\$1".dvi 2> /dev/null || {
      echo "manpdf error: \$1"
      shift
      continue
    }
    dvipdf "\$1".dvi || {
      echo "manpdf error: \$1.dvi"
      shift
      continue
    }
    rm -f "\$1".dvi
    shift
  done
}

function beeppp {
	local count=\${1:-3}
	local rest1=\${3:-0.25}
	local group=\${2:-\$(( count + 1 ))}
	local rest2=\${3:-0.25}
	local     j
	for (( j = 1; j <= count; ++j )); do
		beep
		sleep \$rest1
		(( j % \$group )) || sleep \$rest2
	done
}
EOF

########################################
show_title "Configure services"
#update-rc.d tomcat6 disable
update-rc.d ssh defaults

########################################
show_title "Writing hosts"

cat <<EOF >/etc/hosts
127.0.0.1       localhost

192.168.1.100   boa
192.168.1.101   lark
192.168.1.102   yak
192.168.1.103   cat
192.168.1.104   calf
192.168.1.105   pony

192.168.1.1	gateway
192.168.1.200 	elk
EOF

#######################################
show_title "configure hibernate"

cat <<EOF >/usr/bin/hibernate
#!/bin/bash
nohup sudo bash -c 'sleep 2; pm-hibernate' &>/dev/null &
exit
EOF
chmod +x /usr/bin/hibernate

########################################
show_title "Configuration Finished"
