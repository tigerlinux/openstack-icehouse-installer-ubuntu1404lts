#!/bin/bash
#
# Script para autoconfiguracion de personalidad del servidor
#
#
# Para uso en: Centos 5, Centos 6, Debian 6 y Debian 7
# Reynaldo R. Martinez P.
# TigerLinux@gmail.com
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Secuencias
# 1.- Determinar que S/O: Debian, Centos o RHEL, Unknown
# 2.- Determinar la IP (si es que no hay solo localhost)
# 3.- Determinar el nombre basado en la IP
# 4.- Cambiar el hostname basado en la IP
# 5.- Actualizar el archivo /etc/hosts


# Se determina el S/O. Si no es centos o debian se aborta el proceso

OSFlavor='unknown'

if [ -f /etc/redhat-release ]
then
	OSFlavor='redhat-based'
fi

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
fi

if [ -f /etc/debian_version ]
then
	OSFlavor='debian-based'
fi

echo "OS Flavor is: $OSFlavor"

if [ $OSFlavor == "unknown" ]
then
	echo "Unknown OS Flavor - Aborting"
	exit 0
fi

autoconfigoptionsfile='/etc/autoconfig-server-options.conf'
autoconfigfirstrunfile='/etc/autoconfig-server-alreadyran.txt'
RUNPUPPET="no"
FIRSTRUNONLY="no"
NETWORK=""
INTERFACE=""
PUPPETSERVER=""
IPADDRESS=""
MYFQDN=""

# Si existe el archivo de configuracion manual, se hace el source
# Este archivo puede contener los siguientes parametros
#
# NETWORK=x.y.z - Hace que el script verifique la IP existente en dicha red
# INTERFACE=ethX - Hace que el script verifique la IP existente en dicha interfaz
# RUNPUPPET=yes|no - Si RUNPUPPET=yes el script tratara de ejecutar el cliente puppet
# PUPPETSERVER=servidor - Obligatorio si se usa RUNPUPPET=yes - servidor PUPPET
# FIRSTRUNONLY=yes|no - Si es YES solo se ejecutara una vez y creara un archivo 
#                       llamado /etc/autoconfig-server-alreadyran.txt para prevenir
#                       futuras re-ejecuciones.

if [ -f $autoconfigoptionsfile ]
then
	echo "Reading autoconfig options from $autoconfigoptionsfile"
	source $autoconfigoptionsfile
else
	echo "No autoconfig file found"
fi

case $FIRSTRUNONLY in
yes)
	if [ -f $autoconfigfirstrunfile ]
	then
		echo "First Run already done - aborting script"
		exit 0
	fi
	;;
*)
	echo "No first run config found - lets continue with autoconfig"
	;;
esac

# NETWORK="192.168.56"
# NETWORK="none-jaja"
# INTERFACE="eth1"
# INTERFACE="lo"

if [ ! -z "$NETWORK" ]
then
	echo "Determining IP for Network $NETWORK"
	IPADDRESS=`ifconfig|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|grep $NETWORK|head -n 1`
elif [ ! -z "$INTERFACE" ]
then
	echo "Determining IP for interface $INTERFACE"
	IPADDRESS=`ifconfig $INTERFACE|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|head -n1`
else
	echo "Determining IP the normal way"
	IPADDRESS=`ifconfig|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|head -n1`
fi

if [ -z "$IPADDRESS" ]
then
	IPADDRESS="127.0.0.1"
fi

echo "My IP Address is $IPADDRESS"


MYFQDN=`host $IPADDRESS|grep -i -v NXDOMAIN|awk '{print $5}'|sed 's/.$//'`

if [ -z $MYFQDN ]
then
	echo "Could not resolve the FQDN using DNS - Constructing new FQDN"
	SHORTHOSTNAME=`echo $IPADDRESS|sed 's/\./\-/g'`
	MYFQDN=$SHORTHOSTNAME.localdomain
fi

if [ $IPADDRESS == "127.0.0.1" ]
then
	MYFQDN="localhost.localdomain"
fi

echo "My FQDN is: $MYFQDN"

# Aqui empezamos a escribir cosas.

case $OSFlavor in
redhat-based|centos-based)
	echo "Changing Server personality for $OSFlavor"
	cat /etc/sysconfig/network|grep -v HOSTNAME > /etc/sysconfig/network-temp
	sleep 1
	sync
	cat /etc/sysconfig/network-temp > /etc/sysconfig/network
	sleep 1
	sync
	echo "HOSTNAME=$MYFQDN" >> /etc/sysconfig/network
	rm /etc/sysconfig/network-temp
	sync
	hostname $MYFQDN
	;;
debian-based)
	echo "Changing Server personality for $OSFlavor"
	echo $MYFQDN > /etc/hostname
	sleep 1
	sync
	if [ -f /etc/init.d/hostname.sh ]
	then
		/etc/init.d/hostname.sh stop
		/etc/init.d/hostname.sh start
	elif [ -f /etc/init.d/hostname ]
	then
		/etc/init.d/hostname stop
		/etc/init.d/hostname start
	fi
	hostname $MYFQDN
	;;
*)
	echo "OS Flavor unknown - aborting changes"
	exit 0
	;;
esac

if [ $MYFQDN == "localhost.localdomain" ]
then
	echo "FQDN is localhost based - removing any old reference"
	cat /etc/hosts | grep -v "# Host added by autoconfig" > /etc/hosts.temporal.autoconfig
	cat /etc/hosts.temporal.autoconfig > /etc/hosts
	rm /etc/hosts.temporal.autoconfig
	if [ $OSFlavor == "debian-based" ]
	then
		cat /etc/hosts | grep -v "localhost" > /etc/hosts.temporal.autoconfig
		cat /etc/hosts.temporal.autoconfig > /etc/hosts
		rm /etc/hosts.temporal.autoconfig
		echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts
	fi
else
	echo "Setting entry on /etc/hosts"
	cat /etc/hosts | grep -v "# Host added by autoconfig" > /etc/hosts.temporal.autoconfig
	cat /etc/hosts.temporal.autoconfig > /etc/hosts
	rm /etc/hosts.temporal.autoconfig
	MYSHORTNAME=`hostname -s`
	echo "$IPADDRESS $MYSHORTNAME $MYFQDN # Host added by autoconfig" >> /etc/hosts
fi

case $FIRSTRUNONLY in
yes)
	echo "Setting first run flag on $autoconfigfirstrunfile"
	echo "YES" > $autoconfigfirstrunfile
	echo "script done"
	;;
*)
	echo "No flag for first run - script done"
	;;
esac

if [ $RUNPUPPET == "yes" ]
then
	echo ""
	echo "Calling Puppet Agent with server $PUPPETSERVER"
	puppet agent --server $PUPPETSERVER --test --waitforcert=300
	echo ""
fi

# END Script secuence


