#!/bin/bash
#
# Script para instalacion y autoconfiguracion de cliente Puppet
# Reynaldo R. Martinez P.
# TigerLinux@gmail.com
# Julio 08, 2013
# 

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -z $1 ]
then
	echo "Debe especificar el nombre del servidor Puppet"
	echo "Abortando"
	exit 0
else
	echo ""
	echo "Configurando para Cliente para conectarse al servidor Puppet:"
	echo "$1"
	echo ""
fi

flavor=""


if [ -f /etc/redhat-release ]
then
	testrh5=`cat /etc/redhat-release|grep -c -i release.\*5.`
	testrh6=`cat /etc/redhat-release|grep -c -i release.\*6.`

	if [ $testrh5 == 1 ]
	then
		flavor="rh5"
	fi

	if [ $testrh6 == 1 ]
	then
		flavor="rh6"
	fi
fi

if [ -f /etc/debian_version ]
then
	testdeb6=`cat /etc/debian_version|grep -c -i ^6.`
	testdeb7=`cat /etc/debian_version|grep -c -i ^7.`

	if [ $testdeb6 == 1 ]
	then
		flavor="deb6"
	fi

	if [ $testdeb7 == 1 ]
	then
		flavor="deb7"
	fi	
fi

echo ""

case $flavor in
	"rh5"|"rh6")
		if [ ! -z $2 ]
		then
			echo "Instalando EPEL desde la fuente $2"
			rpm -ivh $2
			echo ""
		fi

		testepelpresent=`rpm -qa epel*|grep -c -i epel-release`
		if [ $testepelpresent == 1 ]
		then
			echo "Epel Instalando - continuando con el proceso"
			echo ""
		else
			echo "ALERTA !!. El repositorio EPEL no esta instalado"
			echo "Debe instalarlo para RH5/RH6"
			echo "Abortando el proceso"
			echo ""
			exit 0
		fi
		;;
esac

case $flavor in
	"rh5")
		echo "Instalando cliente puppet para RHEL5/CENTOS5/SL5"
		rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-7.noarch.rpm
		yum clean all
		yum -y install puppet
		;;
	"rh6")
		echo "Instalando cliente puppet para RHEL6/CENTOS6/SL6"
		rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
		yum clean all
		yum -y install puppet
		;;
	"deb6")
		echo "Instalando cliente puppet para Debian 6 (squeeze)"
		cd /tmp
		wget http://apt.puppetlabs.com/puppetlabs-release-squeeze.deb
		dpkg -i puppetlabs-release-squeeze.deb
		rm -f puppetlabs-release-squeeze.deb
		apt-get -y update
		apt-get -y install puppet
		;;
	"deb7")
		echo "Instalando cliente puppet para Debian 7 (wheezy)"
		cd /tmp
		wget http://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
		dpkg -i puppetlabs-release-wheezy.deb
		rm -f puppetlabs-release-wheezy.deb
		apt-get -y update
		apt-get -y install puppet
		;;
	*)
		echo "No se pudo determinar el tipo de O/S... abortando !"
		echo ""
		exit 0
		;;
esac

echo ""

if [ -f /etc/puppet/puppet.conf ]
then
	echo "Reconfigurando cliente puppet"

	echo "[main]" > /etc/puppet/puppet.conf
	echo "logdir=/var/log/puppet" >> /etc/puppet/puppet.conf
	echo "vardir=/var/lib/puppet" >> /etc/puppet/puppet.conf
	echo "ssldir=/var/lib/puppet/ssl" >> /etc/puppet/puppet.conf
	echo "rundir=/var/run/puppet" >> /etc/puppet/puppet.conf
	echo "factpath=$vardir/lib/facter" >> /etc/puppet/puppet.conf
	echo "templatedir=$confdir/templates" >> /etc/puppet/puppet.conf
	echo "" >> /etc/puppet/puppet.conf
	echo "[agent]" >> /etc/puppet/puppet.conf
	echo "server=$1" >> /etc/puppet/puppet.conf
else
	echo "Falla en la instalacion de puppet - abortando"
	echo ""
	exit 0
fi

case $flavor in
	"rh5"|"rh6")
		echo "PUPPET_SERVER=$1" > /etc/sysconfig/puppet
		echo "PUPPET_PORT=8140" >> /etc/sysconfig/puppet
		echo "PUPPET_LOG=/var/log/puppet/puppet.log" >> /etc/sysconfig/puppet
		echo "#PUPPET_EXTRA_OPTS=--waitforcert=500" >> /etc/sysconfig/puppet
		;;
	"deb6"|"deb7")
		echo "START=yes" > /etc/default/puppet
		echo -e "DAEMON_OPTS=\"--server $1 --logdest=/var/log/puppet/puppet.log --masterport=8140\"" >> /etc/default/puppet
		;;
esac

myhostnameis=`hostname`

echo ""
echo "Cliente puppet instalado y configurado para el interactuar"
echo "con el servidor $1"
echo "Se recomienda hacer una primera ejecucion del cliente para"
echo "registrarlo en el servidor y firmar el certificado con las"
echo "siguientes linea de comando:"
echo ""
echo "En el cliente Puppet:"
echo "puppet agent --server $1 --test --waitforcert=300"
echo ""
echo "En el servidor Puppet:"
echo "puppet cert list"
echo "puppet cert sign $myhostnameis"
echo ""
