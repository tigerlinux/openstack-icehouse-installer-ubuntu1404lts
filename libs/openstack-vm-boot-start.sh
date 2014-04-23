#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Script para arranque controlado de máquinas virtuales
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

myvmlist='/etc/openstack-control-script-config/nova-start-vms.conf'
mydelay="10"
keystonefile="/root/keystonerc_admin"

if [ ! -f $myvmlist ]
then
	echo ""
	echo "VM List Missing - Aborting !"
	echo ""
	exit 0
fi

if [ ! -f $keystonefile ]
then
	echo ""
	echo "Keystone File Missing - Aborting !"
	echo ""
	exit 0
fi

source $keystonefile

cat $myvmlist|grep -v ^#|while read LINE
do
	echo ""
	echo "Starting VM $LINE"
	nova start "$LINE"
	echo "Sleeping $mydelay seconds"
	echo ""
	sleep $mydelay
done
