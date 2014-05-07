#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS y DEBIAN
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Script de limpieza de LOGS de OpenStack
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

case $1 in
auto|AUTO)
	echo ""
	echo "Modo automático activado - Limpiando contenido de los LOGS de OpenStack"
	echo ""
	;;
*)
	echo ""
	echo "Este programa limpiará todo el contenido de los LOGS de OpenStack"
	echo -n "Desea continuar ? [y/n]:"
	read -n 1 answer
	echo ""
	case $answer in
	y|Y)
		echo ""
		echo "Procediendo a limpiar los LOGS de OpenStack"
		echo ""
		;;
	*)
		echo ""
		echo "Abortando a petición del usuario/admin !!!"
		echo ""
		exit 0
		;;
	esac
	;;
esac

logdirs='
	/var/log/swift
	/var/log/glance
	/var/log/cinder
	/var/log/neutron
	/var/log/nova
	/var/log/ceilometer
	/var/log/horizon
	/var/log/keystone
	/var/log/heat
	/var/log/trove
'

for logdirectory in $logdirs
do
	if [ -d $logdirectory ]
	then
		echo "Limpiando logs en $logdirectory"
		cd $logdirectory
		loglist=`ls *.log 2>/dev/null`
		for mylogfile in $loglist
		do
			echo "Limpiando log $mylogfile"
			echo "" > $mylogfile
		done
	fi
done

echo ""
echo "Limpieza Completada"
echo ""
