#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de cinder
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

if [ -f /etc/openstack-control-script-config/cinder-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo "Instalando paquetes para Cinder"

echo "keystone keystone/auth-token password $SERVICE_TOKEN" > /tmp/keystone-seed.txt
echo "keystone keystone/admin-password password $keystoneadminpass" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-password-confirm password $keystoneadminpass" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-user string admin" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-tenant-name string $keystoneadminuser" >> /tmp/keystone-seed.txt
echo "keystone keystone/region-name string $endpointsregion" >> /tmp/keystone-seed.txt
echo "keystone keystone/endpoint-ip string $keystonehost" >> /tmp/keystone-seed.txt
echo "keystone keystone/register-endpoint boolean false" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-email string $keystoneadminuseremail" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-role-name string $keystoneadmintenant" >> /tmp/keystone-seed.txt
echo "keystone keystone/configure_db boolean false" >> /tmp/keystone-seed.txt
echo "keystone keystone/create-admin-tenant boolean false" >> /tmp/keystone-seed.txt

debconf-set-selections /tmp/keystone-seed.txt

echo "glance-common glance/admin-password password $glancepass" > /tmp/glance-seed.txt
echo "glance-common glance/auth-host string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-api glance/keystone-ip string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-common glance/paste-flavor select keystone" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-tenant-name string $keystoneadmintenant" >> /tmp/glance-seed.txt
echo "glance-api glance/endpoint-ip string $glancehost" >> /tmp/glance-seed.txt
echo "glance-api glance/region-name string $endpointsregion" >> /tmp/glance-seed.txt
echo "glance-api glance/register-endpoint boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-user	string $keystoneadminuser" >> /tmp/glance-seed.txt
echo "glance-common glance/configure_db boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_host string $messagebrokerhost" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_password password $brokerpass" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_userid string $brokeruser" >> /tmp/glance-seed.txt

debconf-set-selections /tmp/glance-seed.txt

echo "cinder-common cinder/admin-password password $cinderpass" > /tmp/cinder-seed.txt
echo "cinder-api cinder/region-name string $endpointsregion" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/configure_db boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-tenant-name string $keystoneadmintenant" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/register-endpoint boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/auth-host string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/start_services boolean false" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/endpoint-ip string $cinderhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/volume_group string cinder-volumes" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/keystone-ip string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-user string $keystoneadminuser" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_password password $brokerpass" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_host string $messagebrokerhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_userid string $brokeruser" >> /tmp/cinder-seed.txt

debconf-set-selections /tmp/cinder-seed.txt

aptitude -y install libzookeeper-mt2 libcfg6 libcpg4 sheepdog

aptitude -y install cinder-api cinder-common cinder-scheduler cinder-volume python-cinderclient tgt open-iscsi

sed -r -i 's/CINDER_ENABLE\=false/CINDER_ENABLE\=true/' /etc/default/cinder-common

source $keystone_admin_rc_file

echo "Listo"

stop cinder-api
stop cinder-api
stop cinder-scheduler
stop cinder-scheduler
stop cinder-volume
stop cinder-volume


rm -f /tmp/cinder-seed.txt
rm -f /tmp/glance-seed.txt
rm -f /tmp/keystone-seed.txt

echo ""
echo "Configurando Cinder"

crudini --set /etc/cinder/api-paste.ini filter:authtoken paste.filter_factory keystoneclient.middleware.auth_token:filter_factory
crudini --set /etc/cinder/api-paste.ini filter:authtoken service_protocol http
crudini --set /etc/cinder/api-paste.ini filter:authtoken service_host $keystonehost
crudini --set /etc/cinder/api-paste.ini filter:authtoken service_port 5000
crudini --set /etc/cinder/api-paste.ini filter:authtoken auth_protocol http
crudini --set /etc/cinder/api-paste.ini filter:authtoken auth_host $keystonehost
crudini --set /etc/cinder/api-paste.ini filter:authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/cinder/api-paste.ini filter:authtoken admin_user $cinderuser
crudini --set /etc/cinder/api-paste.ini filter:authtoken admin_password $cinderpass
crudini --set /etc/cinder/api-paste.ini filter:authtoken auth_port 35357
# crudini --set /etc/cinder/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000/v2.0/
crudini --set /etc/cinder/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000


crudini --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen 0.0.0.0
crudini --set /etc/cinder/cinder.conf DEFAULT api_paste_config /etc/cinder/api-paste.ini
crudini --set /etc/cinder/cinder.conf DEFAULT glance_host $glancehost
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf DEFAULT debug False
crudini --set /etc/cinder/cinder.conf DEFAULT verbose False
crudini --set /etc/cinder/cinder.conf DEFAULT use_syslog False


case $brokerflavor in
"qpid")
	crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_hostname $messagebrokerhost
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_username $brokeruser
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_password $brokerpass
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_limit 0
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect true
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_interval_min 0
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_interval_max 0
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_heartbeat 60
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_protocol tcp
	crudini --set /etc/cinder/cinder.conf DEFAULT qpid_tcp_nodelay True
	;;
 
"rabbitmq")
	crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_kombu
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host $messagebrokerhost
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_port 5672
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_use_ssl false
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_userid $brokeruser
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password $brokerpass
	crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_virtual_host $brokervhost
	;;
esac

crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm
crudini --set /etc/cinder/cinder.conf DEFAULT volume_group cinder-volumes
crudini --set /etc/cinder/cinder.conf DEFAULT volume_driver cinder.volume.drivers.lvm.LVMISCSIDriver
crudini --set /etc/cinder/cinder.conf DEFAULT logdir /var/log/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT state_path /var/lib/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT lock_path /var/lib/cinder/tmp
crudini --set /etc/cinder/cinder.conf DEFAULT volumes_dir /var/lib/cinder/volumes
crudini --set /etc/cinder/cinder.conf DEFAULT rootwrap_config /etc/cinder/rootwrap.conf
crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_ip_address $cinder_iscsi_ip_address



case $dbflavor in
"mysql")
	crudini --set /etc/cinder/cinder.conf database connection mysql://$cinderdbuser:$cinderdbpass@$dbbackendhost:$mysqldbport/$cinderdbname
        ;;
"postgres")
	crudini --set /etc/cinder/cinder.conf database connection postgresql://$cinderdbuser:$cinderdbpass@$dbbackendhost:$psqldbport/$cinderdbname
        ;;
esac

crudini --set /etc/cinder/cinder.conf database idle_timeout 3600
 
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user $cinderuser
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password $cinderpass
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_port 35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol http
crudini --set /etc/cinder/cinder.conf keystone_authtoken signing_dirname /tmp/keystone-signing-cinder
 
crudini --set /etc/cinder/cinder.conf DEFAULT notification_driver cinder.openstack.common.notifier.rpc_notifier


if [ $ceilometerinstall == "yes" ]
then
        crudini --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
fi

rm -f /var/lib/cinder/cinder.sqlite

sync
sleep 2
sync
sleep 2

su cinder -s /bin/sh -c "cinder-manage db sync"

echo ""
echo "Levantando servicios de Cinder"

update-rc.d open-iscsi enable

start cinder-api
start cinder-scheduler
start cinder-volume

restart cinder-api
restart cinder-scheduler
restart cinder-volume
restart tgt
/etc/init.d/open-iscsi restart


echo "Listo"

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 3260,8776 -j ACCEPT
/etc/init.d/iptables-persistent save

testcinder=`dpkg -l cinder-api 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testcinder == "0" ]
then
	echo ""
	echo "Falló la instalación de cinder - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/cinder-installed
	date > /etc/openstack-control-script-config/cinder
fi

echo "Listo"

echo ""
echo "Cinder Instalado"
echo ""

