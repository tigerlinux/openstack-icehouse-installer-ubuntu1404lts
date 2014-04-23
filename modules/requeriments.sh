#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de pre-requisitos
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador/módulos en el directorio correcto"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

#
# Verificaciones iniciales para evitar "opppss"
#

rm -rf /tmp/keystone-signing-*
rm -rf /tmp/cd_gen_*

apt-get -y install aptitude

osreposinstalled=`aptitude search python-openstackclient|grep python-openstackclient|head -n1|wc -l`
amiroot=` whoami|grep root|wc -l`
amiubuntu1404=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*14.\*LTS|head -n1|wc -l`
internalbridgepresent=`ovs-vsctl show|grep -i -c bridge.\*$integration_bridge`
kernel64installed=`uname -p|grep x86_64|head -n1|wc -l`

echo ""
echo "Realizando pre-verificaciones"
echo ""

if [ $amiubuntu1404 == "1" ]
then
	echo ""
	echo "Ejecutando en un S/O UBUNTU 14.04 LTS - continuando"
	echo ""
else
	echo ""
	echo "No se pudo verificar que el sistema operativo es un UBUNTU 14.04 LTS"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $amiroot == "1" ]
then
	echo ""
	echo "Ejecutando como root - continuando"
	echo ""
else
	echo ""
	echo "ALERTA !!!. Este script debe ser ejecutado por el usuario root"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $kernel64installed == "1" ]
then
	echo ""
	echo "Kernel x86_64 (amd64) detectado - continuando"
	echo ""
else
	echo ""
	echo "ALERTA !!!. Este servidor no tiene el Kernel x86_64 (amd64)"
	echo "Abortando"
	echo ""
	exit 0
fi


echo ""
echo "Continuando con las verificaciones"
echo ""

searchtestceilometer=`aptitude search ceilometer-api|grep -ci "ceilometer-api"`

if [ $osreposinstalled == "1" ]
then
	echo ""
	echo "Repositorio de OpenStack Icehouse Instalado - continuando"
else
	echo ""
	echo "Prerequisito inexistente: Repositorio OpenStack Icehouse no instalado"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $searchtestceilometer == "1" ]
then
	echo ""
	echo "Repositorios APT para OpenStack aparentemente en orden - continuando"
	echo ""
else
	echo ""
	echo "No se pudo verificar el correcto funcionamiento del repo para OpenStack"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $internalbridgepresent == "1" ]
then
	echo ""
	echo "Bridge de integracion Presente - Continuando"
	echo ""
else
	echo ""
	echo "No se pudo encontrar el bridge de integracion"
	echo "Abortando"
	echo ""
	exit 0
fi

echo "Instalando paquetes iniciales"
echo ""

# Se instalan las dependencias principales vía apt
#
apt-get -y update
apt-get -y install crudini python-iniparse debconf-utils

echo "libguestfs0 libguestfs/update-appliance boolean false" > /tmp/libguest-seed.txt
debconf-set-selections /tmp/libguest-seed.txt

aptitude -y install pm-utils saidar sysstat iotop ethtool iputils-arping libsysfs2 btrfs-tools \
	cryptsetup cryptsetup-bin febootstrap jfsutils libconfig8-dev \
	libcryptsetup4 libguestfs0 libhivex0 libreadline5 reiserfsprogs scrub xfsprogs \
	zerofree zfs-fuse virt-top curl nmon fuseiso9660 libiso9660-8 genisoimage sudo sysfsutils \
	glusterfs-client glusterfs-common nfs-client nfs-common libguestfs-tools

rm -r /tmp/libguest-seed.txt


if [ -f /etc/openstack-control-script-config/libvirt-installed ]
then
	echo ""
	echo "Pre-requisitos ya instalados"
	echo ""
else
	echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" > /tmp/iptables-seed.txt
	echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" >> /tmp/iptables-seed.txt
	debconf-set-selections /tmp/iptables-seed.txt
	aptitude -y install iptables iptables-persistent
	/etc/init.d/iptables-persistent flush
	/etc/init.d/iptables-persistent save
	update-rc.d iptables-persistent enable
	# iptables -A INPUT -p tcp -m multiport --dports 22 -j ACCEPT
	/etc/init.d/iptables-persistent save
	rm -f /tmp/iptables-seed.txt
	aptitude -y install qemu kvm qemu-kvm libvirt-bin libvirt-doc
	rm -f /etc/libvirt/qemu/networks/default.xml
	rm -f /etc/libvirt/qemu/networks/autostart/default.xml
	/etc/init.d/libvirt-bin stop
	update-rc.d libvirt-bin enable
	ifconfig virbr0 down
	aptitude -y install dnsmasq dnsmasq-utils
	/etc/init.d/dnsmasq stop
	update-rc.d dnsmasq disable
	killall -9 dnsmasq
	sed -r -i 's/ENABLED\=1/ENABLED\=0/' /etc/default/dnsmasq
	/etc/init.d/iptables-persistent flush
	iptables -A INPUT -p tcp -m multiport --dports 22 -j ACCEPT
	/etc/init.d/iptables-persistent save
	/etc/init.d/libvirt-bin start
fi

cp ./libs/ksm.sh /etc/init.d/ksm
chmod 755 /etc/init.d/ksm
/etc/init.d/ksm restart
/etc/init.d/ksm status
update-rc.d ksm enable

testlibvirt=`dpkg -l libvirt-bin 2>/dev/null|tail -n 1|grep -ci ^ii`

if [ $testlibvirt == "1" ]
then
	echo ""
	echo "Libvirt correctamente instalado"
	date > /etc/openstack-control-script-config/libvirt-installed
	echo ""
else
	echo ""
	echo "Falló la instalación de libvirt - abortando el resto de la instalación"
	exit 0
fi


