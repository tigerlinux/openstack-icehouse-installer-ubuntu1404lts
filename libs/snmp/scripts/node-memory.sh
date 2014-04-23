#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script para monitoreo de CPU. Seis variables:
#
# Variable 1 = MemBuffers
# Variable 2 = MemCached
# Variable 3 = MemOther
# Variable 4 = MemFree
# Variable 5 = SwapTotal
# Variable 6 = SwapFree
#
# Todas las variables reportan en bytes
#

PATH=$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin

mainusedkb=`free|grep -i mem:|awk '{print $3}'`
mainfreekb=`free|grep -i mem:|awk '{print $4}'`

bufferskb=`free|grep -i mem:|awk '{print $6}'`
cachedkb=`free|grep -i mem:|awk '{print $7}'`

bplusfkb=$[bufferskb+cachedkb]

otherkb=$[mainusedkb-bplusfkb]

swapusedkb=`free|grep -i swap:|awk '{print $3}'`
swapfreekb=`free|grep -i swap:|awk '{print $4}'`

echo $[bufferskb*1024]
echo $[cachedkb*1024]
echo $[otherkb*1024]
echo $[mainfreekb*1024]
echo $[swapusedkb*1024]
echo $[swapfreekb*1024]
