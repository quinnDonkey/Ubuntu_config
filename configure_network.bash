#!/bin/bash

set -u
set -e

[[root != $( whoami ) ]] && {
	echo "you are not root user, no root priviliges"
	exit
}

function show_title {
	echo ""
	echo "==================="
	echo "=$1"
	echo "==================="
	echo ""	
}

show_title "configure network"

grep -q 'eth0' /etc/network/interfaces || {
{
	echo "auto eth0"
	echo "iface eth0 inet dhcp"
} >> /etc/network/interfaces
service networking restart
}

show_title "configure dnsservier"

grep -q 'nameserver' /etc/resolv.conf || {
{
	echo "nameserver 192.168.1.1"
} >> /etc/resolv.conf
/etc/init.d/networking restart
}
