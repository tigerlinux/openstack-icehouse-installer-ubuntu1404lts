#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de ceilometer
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

if [ -f /etc/openstack-control-script-config/db-installed ]
then
	echo ""
	echo "Proceso de BD verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende de que el proceso de base de datos"
	echo "haya sido exitoso, pero aparentemente no lo fue"
	echo "Abortando el módulo"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/keystone-installed ]
then
	echo ""
	echo "Proceso principal de Keystone verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende del proceso principal de keystone"
	echo "pero no se pudo verificar que dicho proceso haya sido"
	echo "completado exitosamente - se abortará el proceso"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/ceilometer-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo ""
echo "Instalando paquetes para Ceilometer"
echo ""

echo "Instalando y configurando backend de base de datos MongoDB"
echo ""
aptitude -y install mongodb mongodb-clients mongodb-dev mongodb-server
aptitude -y install libsnappy1 libgoogle-perftools4
# dpkg -i libs/mongodb/*.deb

restart mongodb


echo "ceilometer-api ceilometer/register-endpoint boolean false" > /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/region-name string $endpointsregion" >> /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/endpoint-ip string $ceilometerhost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/keystone-ip string $keystonehost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_password password $brokerpass" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_userid string $brokeruser" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_host string $messagebrokerhost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-password password $keystoneadminpass" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-user string $keystoneadminuser" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/auth-host string $keystonehost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-tenant-name string $keystoneadmintenant" >> /tmp/ceilometer-seed.txt

debconf-set-selections /tmp/ceilometer-seed.txt

echo ""
echo "Instalando paquetes de Ceilometer"
echo ""

aptitude -y install ceilometer-agent-central ceilometer-agent-compute ceilometer-api \
	ceilometer-collector ceilometer-common python-ceilometer python-ceilometerclient \
	libnspr4 libnspr4-dev python-libxslt1

if [ $ceilometeralarms == "yes" ]
then
	aptitude -y install ceilometer-alarm-evaluator ceilometer-alarm-notifier ceilometer-agent-notification
fi

echo "Listo"
echo ""

stop ceilometer-agent-central
stop ceilometer-agent-compute
stop ceilometer-api
stop ceilometer-collector

if [ $ceilometeralarms == "yes" ]
then
	stop ceilometer-alarm-evaluator
	stop ceilometer-alarm-notifier
	stop ceilometer-agent-notification
fi

source $keystone_admin_rc_file

rm /tmp/ceilometer-seed.txt

echo ""
echo "Configurando Ceilometer"
echo ""

crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_port 35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_protocol http
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user $ceilometeruser
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password $ceilometerpass
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$keystonehost:5000/
 
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_url "http://$keystonehost:35357/v2.0"
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_tenant_name $keystoneservicestenant
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_password $ceilometerpass
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_username $ceilometeruser
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_region $endpointsregion
 
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username $ceilometeruser
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password $ceilometerpass
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name $keystoneservicestenant
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$keystonehost:5000/v2.0/
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name $endpointsregion
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type publicURL
 
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT metering_api_port 8777
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT logdir /var/log/ceilometer
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_region $endpointsregion
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT host $ceilometerhost
 
crudini --del /etc/ceilometer/ceilometer.conf DEFAULT sql_connection
 
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT nova_control_exchange nova
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT glance_control_exchange glance
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT neutron_control_exchange neutron
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT cinder_control_exchange cinder
# Cambios para Icehouse
# crudini --set /etc/ceilometer/ceilometer.conf DEFAULT metering_secret $metering_secret
crudini --set /etc/ceilometer/ceilometer.conf publisher metering_secret $metering_secret
 
# crudini --set /etc/ceilometer/ceilometer.conf publisher_rpc metering_secret $SERVICE_TOKEN
# crudini --set /etc/ceilometer/ceilometer.conf publisher_rpc metering_topic metering

kvm_possible=`grep -E 'svm|vmx' /proc/cpuinfo|uniq|wc -l`
if [ $kvm_possible == "0" ]
then
        crudini --set /etc/ceilometer/ceilometer.conf DEFAULT libvirt_type qemu
else
        crudini --set /etc/ceilometer/ceilometer.conf DEFAULT libvirt_type kvm
fi

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT debug false
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose false
crudini --set /etc/ceilometer/ceilometer.conf database connection "mongodb://$mondbhost:$mondbport/$mondbname"
# crudini --set /etc/ceilometer/ceilometer.conf DEFAULT metering_secret $metering_secret
# crudini --set /etc/ceilometer/ceilometer.conf DEFAULT metering_secret $SERVICE_TOKEN
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT log_dir /var/log/ceilometer
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT notification_topics notifications,glance_notifications
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT policy_file policy.json
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT policy_default_rule default
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT dispatcher database
 
case $brokerflavor in
"qpid")
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_qpid
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_hostname $messagebrokerhost
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_port 5672
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_username $brokeruser
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_password $brokerpass
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_heartbeat 60
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_protocol tcp
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_tcp_nodelay true
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_topology_version 1
	;;
 
"rabbitmq")
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_kombu
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_host $messagebrokerhost
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_port 5672
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_use_ssl false
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_userid $brokeruser
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_password $brokerpass
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_virtual_host $brokervhost
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_retry_interval 1
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_retry_backoff 2
	crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_max_retries 0
	;;
esac
 
 
# Nuevo para Icehouse
crudini --set /etc/ceilometer/ceilometer.conf alarm evaluation_service ceilometer.alarm.service.SingletonAlarmService
crudini --set /etc/ceilometer/ceilometer.conf alarm partition_rpc_topic alarm_partition_coordination
crudini --set /etc/ceilometer/ceilometer.conf alarm evaluation_interval 60
crudini --set /etc/ceilometer/ceilometer.conf alarm record_history True
crudini --set /etc/ceilometer/ceilometer.conf api port 8777
crudini --set /etc/ceilometer/ceilometer.conf api host 0.0.0.0
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT heat_control_exchange heat
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT control_exchange ceilometer
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT http_control_exchanges nova
sed -r -i 's/http_control_exchanges\ =\ nova/http_control_exchanges=nova\nhttp_control_exchanges=glance\nhttp_control_exchanges=cinder\nhttp_control_exchanges=neutron\n/' /etc/ceilometer/ceilometer.conf
crudini --set /etc/ceilometer/ceilometer.conf publisher_rpc metering_topic metering
crudini --set /etc/ceilometer/ceilometer.conf rpc_notifier2 topics notifications

#
# Esto no sabemos si todavía funciona - esperando por confirmación
# grep -v format_string /etc/nova/nova.conf > /etc/ceilometer-collector.conf



echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 8777,$mondbport -j ACCEPT
/etc/init.d/iptables-persistent save

echo "Listo"

stop mongodb

sync
sleep 5
sync

start mongodb

rm -f /var/lib/ceilometer/ceilometer.sqlite

sync
sleep 5
sync

start ceilometer-agent-compute
start ceilometer-agent-central
start ceilometer-api
start ceilometer-collector

if [ $ceilometeralarms == "yes" ]
then
	start ceilometer-alarm-notifier
	start ceilometer-alarm-evaluator
	start ceilometer-agent-notification
fi

testceilometer=`dpkg -l ceilometer-api 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testceilometer == "0" ]
then
	echo ""
	echo "Falló la instalación de ceilometer - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/ceilometer-installed
	date > /etc/openstack-control-script-config/ceilometer
	if [ $ceilometeralarms == "yes" ]
	then
		date > /etc/openstack-control-script-config/ceilometer-installed-alarms
	fi
fi

echo ""
echo "Ceilometer Instalado"
echo ""



