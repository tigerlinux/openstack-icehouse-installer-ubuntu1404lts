#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script para monitoreo de CPU. Cuatro variables:
#
# Variable 1: % de uso de CPU "user"
# Variable 2: % de uso de CPU "system"
# Variable 3: % de uso de CPU "idle"
# Variable 4: % de uso de CPU "waiting-for-I/O"
# 

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

mystats=`mpstat 1 4 |grep -i "Average:"`

usercpu=`echo $mystats|awk '{print $3}'`
systemcpu=`echo $mystats|awk '{print $5}'`
idlecpu=`echo $mystats|awk '{print $11}'`
wiocpu=`echo $mystats|awk '{print $6}'`


echo $usercpu
echo $systemcpu
echo $idlecpu
echo $wiocpu
