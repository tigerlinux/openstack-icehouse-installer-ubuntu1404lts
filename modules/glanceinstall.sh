#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de glance
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

if [ -f /etc/openstack-control-script-config/glance-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi


echo ""
echo "Instalando paquetes para Glance"

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

aptitude -y install glance glance-api glance-common glance-registry

echo "Listo"
echo ""

rm -f /tmp/glance-seed.txt
rm -f /tmp/keystone-seed.txt

stop glance-registry
stop glance-api
stop glance-registry
stop glance-api

source $keystone_admin_rc_file

echo ""
echo "Configurando Glance"

sync
sleep 5
sync

crudini --set /etc/glance/glance-api.conf DEFAULT verbose False
crudini --set /etc/glance/glance-api.conf DEFAULT debug False
crudini --set /etc/glance/glance-api.conf DEFAULT default_store file
crudini --set /etc/glance/glance-api.conf DEFAULT bind_host 0.0.0.0
crudini --set /etc/glance/glance-api.conf DEFAULT bind_port 9292
crudini --set /etc/glance/glance-api.conf DEFAULT log_file /var/log/glance/api.log
crudini --set /etc/glance/glance-api.conf DEFAULT backlog 4096
crudini --set /etc/glance/glance-api.conf DEFAULT use_syslog False

case $dbflavor in
"mysql")
        crudini --set /etc/glance/glance-api.conf DEFAULT sql_connection mysql://$glancedbuser:$glancedbpass@$dbbackendhost:$mysqldbport/$glancedbname
        crudini --set /etc/glance/glance-api.conf database connection mysql://$glancedbuser:$glancedbpass@$dbbackendhost:$mysqldbport/$glancedbname
        crudini --set /etc/glance/glance-registry.conf DEFAULT sql_connection mysql://$glancedbuser:$glancedbpass@$dbbackendhost:$mysqldbport/$glancedbname
        crudini --set /etc/glance/glance-registry.conf database connection mysql://$glancedbuser:$glancedbpass@$dbbackendhost:$mysqldbport/$glancedbname
        ;;
"postgres")
        crudini --set /etc/glance/glance-api.conf DEFAULT sql_connection postgresql://$glancedbuser:$glancedbpass@$dbbackendhost:$psqldbport/$glancedbname
        crudini --set /etc/glance/glance-api.conf database connection postgresql://$glancedbuser:$glancedbpass@$dbbackendhost:$psqldbport/$glancedbname
        crudini --set /etc/glance/glance-registry.conf DEFAULT sql_connection postgresql://$glancedbuser:$glancedbpass@$dbbackendhost:$psqldbport/$glancedbname
        crudini --set /etc/glance/glance-registry.conf database connection postgresql://$glancedbuser:$glancedbpass@$dbbackendhost:$psqldbport/$glancedbname
        ;;
esac

glanceworkers=`grep processor.\*: /proc/cpuinfo |wc -l`

crudini --set /etc/glance/glance-api.conf DEFAULT sql_idle_timeout 3600
crudini --set /etc/glance/glance-api.conf DEFAULT workers $glanceworkers
crudini --set /etc/glance/glance-api.conf DEFAULT registry_host 0.0.0.0
crudini --set /etc/glance/glance-api.conf DEFAULT registry_port 9191
crudini --set /etc/glance/glance-api.conf DEFAULT registry_client_protocol http
crudini --set /etc/glance/glance-api.conf DEFAULT filesystem_store_datadir /var/lib/glance/images/
crudini --set /etc/glance/glance-api.conf DEFAULT delayed_delete False
crudini --set /etc/glance/glance-api.conf DEFAULT scrub_time 43200


case $brokerflavor in
"qpid")
	crudini --set /etc/glance/glance-api.conf DEFAULT notifier_strategy qpid
	crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver glance.openstack.common.notifier.rpc_notifier
	crudini --set /etc/glance/glance-api.conf DEFAULT qpid_notification_exchange glance
	crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend glance.openstack.common.rpc.impl_qpid
	crudini --set /etc/glance/glance-api.conf DEFAULT qpid_notification_topic notifications
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_hostname $messagebrokerhost
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_port 5672
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_username $brokeruser
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_password $brokerpass
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_reconnect_timeout 0
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_reconnect_limit 0
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_reconnect_interval_min 0
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_reconnect_interval_max 0
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_reconnect_interval 0
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_heartbeat 5
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_protocol tcp
        crudini --set /etc/glance/glance-api.conf DEFAULT qpid_tcp_nodelay True
        ;;

"rabbitmq")
	crudini --set /etc/glance/glance-api.conf DEFAULT notifier_strategy rabbitmq
	crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver glance.openstack.common.notifier.rpc_notifier
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_host $messagebrokerhost
	crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend glance.openstack.common.rpc.impl_kombu
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_port 5672
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_use_ssl false
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_userid $brokeruser
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_password $brokerpass
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_virtual_host $brokervhost
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_notification_exchange glance
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_notification_topic notifications
	crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_durable_queues False
        ;;
esac

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_port 35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_user $glanceuser
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_password $glancepass
# crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$keystonehost:5000/

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-registry.conf DEFAULT verbose False
crudini --set /etc/glance/glance-registry.conf DEFAULT debug False
crudini --set /etc/glance/glance-registry.conf DEFAULT bind_host 0.0.0.0
crudini --set /etc/glance/glance-registry.conf DEFAULT bind_port 9191
crudini --set /etc/glance/glance-registry.conf DEFAULT log_file /var/log/glance/registry.log
crudini --set /etc/glance/glance-registry.conf DEFAULT backlog 4096

crudini --set /etc/glance/glance-registry.conf DEFAULT sql_idle_timeout 3600
crudini --set /etc/glance/glance-registry.conf DEFAULT api_limit_max 1000
crudini --set /etc/glance/glance-registry.conf DEFAULT limit_param_default 25

crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_user $glanceuser
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_password $glancepass
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$keystonehost:5000/

crudini --set /etc/glance/glance-cache.conf DEFAULT verbose False
crudini --set /etc/glance/glance-cache.conf DEFAULT debug False
crudini --set /etc/glance/glance-cache.conf DEFAULT log_file /var/log/glance/image-cache.log
crudini --set /etc/glance/glance-cache.conf DEFAULT image_cache_dir /var/lib/glance/image-cache/
crudini --set /etc/glance/glance-cache.conf DEFAULT image_cache_stall_time 86400
crudini --set /etc/glance/glance-cache.conf DEFAULT image_cache_invalid_entry_grace_period 3600
crudini --set /etc/glance/glance-cache.conf DEFAULT image_cache_max_size 10737418240
crudini --set /etc/glance/glance-cache.conf DEFAULT registry_host 0.0.0.0
crudini --set /etc/glance/glance-cache.conf DEFAULT registry_port 9191
crudini --set /etc/glance/glance-cache.conf DEFAULT admin_tenant_name $keystoneservicestenant
crudini --set /etc/glance/glance-cache.conf DEFAULT admin_user $glanceuser
crudini --set /etc/glance/glance-cache.conf DEFAULT filesystem_store_datadir /var/lib/glance/images/


mkdir -p /var/lib/glance/image-cache/
chown -R glance.glance /var/lib/glance/image-cache

echo "Listo"

su glance -s /bin/sh -c "glance-manage db_sync"

sync
sleep 5
sync

echo ""
echo "Aplicando reglas de IPTABLES"
iptables -A INPUT -p tcp -m multiport --dports 9292 -j ACCEPT
/etc/init.d/iptables-persistent save
echo "Listo"
echo ""

echo "Activando Servicios de GLANCE"

start glance-registry
start glance-api

sleep 5

restart glance-registry
sleep 2
restart glance-api
sleep 2


if [ $glance_use_swift == "yes" ]
then
        if [ -f /etc/openstack-control-script-config/swift-installed ]
        then
                crudini --set /etc/glance/glance-api.conf DEFAULT default_store swift
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_auth_address http://$keystonehost:5000/v2.0/
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_user $keystoneservicestenant:$swiftuser
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_key $swiftpass
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_create_container_on_put True
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_auth_version 2
                crudini --set /etc/glance/glance-api.conf DEFAULT swift_store_container glance
                crudini --set /etc/glance/glance-cache.conf DEFAULT default_store swift
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_auth_address http://$keystonehost:5000/v2.0/
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_user $keystoneservicestenant:$swiftuser
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_key $swiftpass
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_create_container_on_put True
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_auth_version 2
                crudini --set /etc/glance/glance-cache.conf DEFAULT swift_store_container glance
                echo ""
                echo "Bajando servicios de Glance"
                echo ""

                stop glance-registry
                stop glance-api

                swift_svc_start='
                        swift-account
                        swift-account-auditor
                        swift-account-reaper
                        swift-account-replicator
                        swift-container
                        swift-container-auditor
                        swift-container-replicator
                        swift-container-updater
                        swift-object
                        swift-object-auditor
                        swift-object-replicator
                        swift-object-updater
                        swift-proxy
                '
                swift_svc_stop=`echo $swift_svc_start|tac -s' '`

                echo ""
                echo "Reiniciando servicios de Swift"
                echo ""

                for i in $swift_svc_stop
                do
                        stop $i
                done

		killall -9 -u swift

                sync
                sleep 2
                sync

                for i in $swift_svc_start
                do
                        start $i
                done

                sync
                sleep 5
                sync

                echo ""
                echo "Subiendo servicios de Glance con Swift como Backend"
                echo ""

                start glance-api
                start glance-registry
        fi
fi


testglance=`dpkg -l glance-api 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testglance == "0" ]
then
	echo ""
	echo "Falló la instalación de glance - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/glance-installed
	date > /etc/openstack-control-script-config/glance
fi

echo ""
echo "Glance Instalado"
echo ""

if [ $glancecirroscreate == "yes" ]
then
	echo ""
	echo "Creando imágenes Cirros para pruebas de OpenStack"
	echo ""
	source $keystone_admin_rc_file

	sync
	sleep 10
	sync

	glance image-create --name="Cirros 0.3.2 32 bits" \
		--disk-format=qcow2 \
		--is-public true \
		--container-format bare < ./libs/cirros/cirros-0.3.2-i386-disk.img

	sync
	sleep 10
	sync

	glance image-create --name="Cirros 0.3.2 64 bits" \
		--disk-format=qcow2 \
		--is-public true \
		--container-format bare < ./libs/cirros/cirros-0.3.2-x86_64-disk.img

	sync
	sleep 5
	sync

	glance image-list

	echo ""
	echo "Imágenes de cirros 0.3.2 para 32 y 64 bits creadas"
	echo ""
fi


