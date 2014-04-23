#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script para instalacion de Message Broker
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

if [ -f /etc/openstack-control-script-config/broker-installed ]
then
	echo ""
	echo "Aparentemente este módulo ya se ejecutó de manera exitosa"
	echo "Message Broker previamente instalado"
	echo ""
	exit 0
fi

echo ""
echo "Instalando paquetes para el Messagebroker"

case $brokerflavor in
"qpid")

	echo "qpidd qpidd/password1 password $messagebrokeradminpass" > /tmp/qpidd-seed.txt	
	echo "qpidd qpidd/password2 password $messagebrokeradminpass" >> /tmp/qpidd-seed.txt

	debconf-set-selections /tmp/qpidd-seed.txt

	useradd -m -d /var/run/qpid -r -s /bin/false qpidd
	aptitude -y install qpidd python-cqpid python-qpid python-qpid-extras-qmf qpid-client qpid-tools  sasl2-bin

	echo "DAEMON_OPTS=\"--auth yes --config /etc/qpid/qpidd.conf\"" > /etc/default/qpidd

	echo ""
	echo "Listo"
	echo ""

	echo "$brokerpass"|saslpasswd2 -f /etc/qpid/qpidd.sasldb -u QPID $brokeruser -p

	sed -r -i 's/START=no/START=yes/' /etc/default/saslauthd
	/etc/init.d/saslauthd restart
	update-rc.d saslauthd enable

	echo "Configurando el messagebroker"

	echo "cluster-mechanism=DIGEST-MD5 ANONYMOUS" > /etc/qpid/qpidd.conf
	echo "auth=yes" >> /etc/qpid/qpidd.conf
	echo "log-to-syslog=yes" >> /etc/qpid/qpidd.conf
	echo "log-to-stderr=no" >> /etc/qpid/qpidd.conf
	echo "log-time=no" >> /etc/qpid/qpidd.conf
	echo "pid-dir=/var/run/qpid" >> /etc/qpid/qpidd.conf
	echo "data-dir=/var/spool/qpid" >> /etc/qpid/qpidd.conf
	echo "mgmt-enable=yes" >> /etc/qpid/qpidd.conf
	echo "realm=QPID" >> /etc/qpid/qpidd.conf

	/etc/init.d/qpidd restart

	update-rc.d qpidd enable

	rm -f /tmp/qpidd-seed.txt

	qpidtest=`dpkg -l qpidd 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $qpidtest == "0" ]
	then
		echo ""
		echo "Falló la instalación de qpid - abortando el resto de la instalación"
		echo ""
		exit 0
	else
		date > /etc/openstack-control-script-config/broker-installed
	fi

	;;

"rabbitmq")

	aptitude -y install rabbitmq-server

	echo "RABBITMQ_NODE_IP_ADDRESS=0.0.0.0" > /etc/rabbitmq/rabbitmq-env.conf

	/etc/init.d/rabbitmq-server restart

	update-rc.d rabbitmq-server enable

	rabbitmqctl add_vhost $brokervhost
	rabbitmqctl list_vhosts

	rabbitmqctl add_user $brokeruser $brokerpass
	rabbitmqctl list_users

	rabbitmqctl set_permissions -p $brokervhost $brokeruser ".*" ".*" ".*"
	rabbitmqctl list_permissions -p $brokervhost

	rabbitmqtest=`dpkg -l rabbitmq-server 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $rabbitmqtest == "0" ]
	then
		echo ""
		echo "Falló la instalación de RabbitMQ - abortando el resto de la instalación"
		echo ""
		exit 0
	else
		date > /etc/openstack-control-script-config/broker-installed
	fi

	;;

esac


echo "Aplicando reglas de IPTABLES"

iptables -I INPUT -p tcp -m tcp --dport 5672 -j ACCEPT
/etc/init.d/iptables-persistent save


echo "Listo"

echo ""
echo "Servicio de Message Broker Instalado"
echo ""


