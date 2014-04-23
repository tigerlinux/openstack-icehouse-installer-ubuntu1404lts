#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Script para limpieza de tokens de Keystone
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

mysourcerc="/root/keystonerc_admin"
mykeystonecommand="keystone-manage"
mykeystoneoption="token_flush"

echo ""
echo -n "Starting Keystone Old Tokens FLush. Date/Time: "
date

echo ""

source $mysourcerc
$mykeystonecommand $mykeystoneoption

echo ""
echo -n "Keystone Old Tokens Flush Ended. Date/Time: "
date

echo ""
