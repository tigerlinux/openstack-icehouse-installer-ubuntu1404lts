#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script para monitoreo de la cantidad de VM's en distintos
# estados
#
# Primera variable: VM's ejecutandose
# Segunda variable: VM's apagadas
# Tercera variable: VM's pausadas
# Cuarta variable: VM's en otros estados
# Quinta variable: Total de VM's


PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin

vmrun=`virsh list --all|grep -ci "running"`
vmoff=`virsh list --all|grep -ci "shut off"`
vmpsd=`virsh list --all|grep -ci "paused"`
vmoth=`virsh list --all|grep -ci "other"`
vmtot=$[vmrun+vmoff+vmpsd+vmoth]

echo $vmrun
echo $vmoff
echo $vmpsd
echo $vmoth
echo $vmtot
