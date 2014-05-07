#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de pre-requisitos extras
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

if [ -f /etc/openstack-control-script-config/requeriments-extras-installed ]
then
	echo ""
	echo "Requisitos extras previamente instalados"
	echo ""
	exit 0
fi

echo ""
echo "Instalando requerimientos adicionales" 
echo ""
aptitude -y install python-sqlalchemy python-sqlalchemy-ext \
	python-psycopg2 python-mysqldb python-keystoneclient python-keystone \
	python-argparse

aptitude -y install python-py \
	python-configparser \
	dh-python \
	python-flask \
	subunit \
	libcppunit-subunit0 \
	libsubunit0 \
	python-tox \
	node-uglify \
	python-waitress \
	python-webtest \
	pep8 \
	pyflakes \
	python-bson \
	python-gridfs \
	python-pybabel \
	python-colorama

aptitude -y install python-flake8 \
	python-psutil \
	python-pyftpdlib \
	python-selenium \
	python-testscenarios \
	python-thrift \
	cliff-tablib \
	python-factory-boy \
	python-ftp-cloudfs \
	python-oslo.sphinx \
	python-openstack.nose-plugin \
	python-sphinxcontrib-httpdomain \
	python-sphinxcontrib-pecanwsme

aptitude -y install python-couleur \
	python-ddt \
	python-falcon \
	python-hacking \
	python-happybase \
	python-httpretty \
	python-jsonpath-rw \
	python-mockito \
	python-nosehtmloutput \
	python-proboscis \
	python-pycadf \
	python-pyghmi \
	python-pystache \
	python-sockjs-tornado

aptitude -y install python-imaging \
	python-imaging \
	msgpack-python \
	python-jinja2 \
	python-simplegeneric \
	python-docutils \
	python-bson \
	python-bson-ext \
	python-pymongo \
	python-flask \
	python-werkzeug \
	python-webtest \
	python-pecan \
	python-sphinx \
	python-wsme


initiallist='
	python-keystoneclient
	python-sqlalchemy
	python-keystoneclient
	python-psycopg2
	python-mysqldb
'
	
for mypack in $initiallist
do
	testpackinstalled=`dpkg -l $mypack 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $testpackinstalled == "1" ]
	then
		echo "Paquete $mypack verificado"
	else
		echo "El paquete $mypack no aparece instalado - abortando instalación"
		exit 0
	fi
done

date > /etc/openstack-control-script-config/requeriments-extras-installed

echo ""
echo "Listo"
echo ""
