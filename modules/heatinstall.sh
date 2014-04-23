#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de Heat
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

if [ -f /etc/openstack-control-script-config/heat-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

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

echo "neutron-common neutron/admin-password password $keystoneadminpass" > /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-password password $keystoneadminpass" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/keystone-ip string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/local_ip string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/register-endpoint boolean false" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tunnel_id_ranges string 0" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/endpoint-ip string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "openswan openswan/install_x509_certificate boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_password password $brokerpass" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_userid string $brokeruser" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_host string $messagebrokerhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tunnel_id_ranges string 1" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/plugin-select select OpenVSwitch" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/local_ip string $neutronhost" >> /tmp/neutron-seed.txt

debconf-set-selections /tmp/neutron-seed.txt

echo "nova-common nova/admin-password password $keystoneadminpass" > /tmp/nova-seed.txt
echo "nova-common nova/configure_db boolean false" >> /tmp/nova-seed.txt
echo "nova-consoleproxy nova-consoleproxy/daemon_type select spicehtml5" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit-host string 127.0.0.1" >> /tmp/nova-seed.txt
echo "nova-api nova/register-endpoint boolean false" >> /tmp/nova-seed.txt
echo "nova-common nova/my-ip string $novahost" >> /tmp/nova-seed.txt
echo "nova-common nova/start_services boolean false" >> /tmp/nova-seed.txt
echo "nova-common nova/admin-user string $keystoneadminuser" >> /tmp/nova-seed.txt
echo "nova-api nova/region-name string $endpointsregion" >> /tmp/nova-seed.txt
echo "nova-common nova/admin-tenant-name string $keystoneadmintenant" >> /tmp/nova-seed.txt
echo "nova-api nova/endpoint-ip string $novahost" >> /tmp/nova-seed.txt
echo "nova-api nova/keystone-ip string $keystonehost" >> /tmp/nova-seed.txt
echo "nova-common nova/active-api multiselect ec2, osapi_compute, metadata" >> /tmp/nova-seed.txt
echo "nova-common nova/auth-host string $keystonehost" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_host string $messagebrokerhost" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_password password $brokerpass" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_userid string $brokeruser" >> /tmp/nova-seed.txt
echo "nova-common nova/neutron_url string http://$neutronhost:9696" >> /tmp/nova-seed.txt
echo "nova-common nova/neutron_admin_password password $neutronpass" >> /tmp/nova-seed.txt

debconf-set-selections /tmp/nova-seed.txt

#
# Debconf para HEAT - NOTA: Se hace la config inicial con la BD de sqlite
# para no tener problemas con el Postinstall del paquete. Luego se cambia a la
# base de datos correcta y se hace el "db_sync"
#

echo "heat-common heat-common/internal/skip-preseed boolean true" > /tmp/heat-seed.txt
echo "heat-common heat/rabbit_password password $brokerpass" >> /tmp/heat-seed.txt
echo "heat-common heat/rabbit_userid string $brokeruser" >> /tmp/heat-seed.txt
echo "heat-common heat/admin-password password $heatpass" >> /tmp/heat-seed.txt
echo "heat-common heat/rabbit_userid string openstack" >> /tmp/heat-seed.txt
echo "heat-common heat-common/dbconfig-upgrade boolean true" >> /tmp/heat-seed.txt
echo "heat-common heat/auth-host string $keystonehost" >> /tmp/heat-seed.txt
echo "heat-common heat/configure_db boolean true" >> /tmp/heat-seed.txt
echo "heat-common heat/rabbit_host string $messagebrokerhost" >> /tmp/heat-seed.txt
echo "heat-common heat-common/dbconfig-install boolean true" >> /tmp/heat-seed.txt
echo "heat-common heat-common/upgrade-backup boolean true" >> /tmp/heat-seed.txt
echo "heat-common heat-common/database-type select sqlite3" >> /tmp/heat-seed.txt
echo "heat-common heat-common/dbconfig-reinstall boolean false" >> /tmp/heat-seed.txt
echo "heat-common heat/register-endpoint boolean false" >> /tmp/heat-seed.txt

debconf-set-selections /tmp/heat-seed.txt

echo ""
echo "Instalando paquetes para Heat"

aptitude -y install heat-api heat-api-cfn heat-engine
aptitude -y install heat-cfntools

echo "Listo"
echo ""

rm -f /tmp/*.seed.txt

source $keystone_admin_rc_file

echo ""
echo "Configurando Heat"
echo ""

stop heat-api
stop heat-api-cfn
stop heat-engine

mkdir -p /etc/heat/environment.d

# Temporal - aparentemente el paquete no instala el api-paste.ini

cat ./libs/heat/api-paste.ini > /etc/heat/api-paste.ini

chown -R heat.heat /etc/heat

# if [ -f /etc/heat/api-paste.ini ]
#then
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" paste.filter_factory "heat.common.auth_token:filter_factory"
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" auth_host $keystonehost
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" auth_port 35357
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" auth_protocol http
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" admin_tenant_name $keystoneservicestenant
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" admin_user $heatuser
#	crudini --set /etc/heat/api-paste.ini "filter:authtoken" admin_password $heatpass
#fi

echo "# Heat Main Config" >> /etc/heat/heat.conf

case $dbflavor in
"mysql")
	crudini --set /etc/heat/heat.conf database connection mysql://$heatdbuser:$heatdbpass@$dbbackendhost:$mysqldbport/$heatdbname
;;
"postgres")
	crudini --set /etc/heat/heat.conf database connection postgresql://$heatdbuser:$heatdbpass@$dbbackendhost:$psqldbport/$heatdbname
;;
esac
 
crudini --set /etc/heat/heat.conf DEFAULT host $heathost
crudini --set /etc/heat/heat.conf DEFAULT debug false
crudini --set /etc/heat/heat.conf DEFAULT verbose false
crudini --set /etc/heat/heat.conf DEFAULT log_dir /var/log/heat
 
# Nuevo para Icehouse
crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://$heathost:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://$heathost:8000/v1/waitcondition
crudini --set /etc/heat/heat.conf DEFAULT heat_watch_server_url http://$heathost:8003
crudini --set /etc/heat/heat.conf DEFAULT heat_stack_user_role heat_stack_user
crudini --set /etc/heat/heat.conf DEFAULT auth_encryption_key $heatencriptionkey
crudini --set /etc/heat/heat.conf DEFAULT use_syslog False
crudini --set /etc/heat/heat.conf DEFAULT heat_api_cloudwatch bind_host 0.0.0.0
crudini --set /etc/heat/heat.conf DEFAULT heat_api_cloudwatch bind_port 8003

crudini --del /etc/heat/heat.conf keystone_authtoken admin_tenant_name
crudini --del /etc/heat/heat.conf keystone_authtoken admin_user
crudini --del /etc/heat/heat.conf keystone_authtoken admin_password
crudini --del /etc/heat/heat.conf keystone_authtoken auth_host
crudini --del /etc/heat/heat.conf keystone_authtoken auth_port
crudini --del /etc/heat/heat.conf keystone_authtoken auth_protocol
crudini --del /etc/heat/heat.conf keystone_authtoken auth_uri
crudini --del /etc/heat/heat.conf keystone_authtoken signing_dir

crudini --del /etc/heat/heat.conf keystone_authtoken admin_tenant_name
crudini --del /etc/heat/heat.conf keystone_authtoken admin_user
crudini --del /etc/heat/heat.conf keystone_authtoken admin_password
crudini --del /etc/heat/heat.conf keystone_authtoken auth_host
crudini --del /etc/heat/heat.conf keystone_authtoken auth_port
crudini --del /etc/heat/heat.conf keystone_authtoken auth_protocol
crudini --del /etc/heat/heat.conf keystone_authtoken auth_uri
crudini --del /etc/heat/heat.conf keystone_authtoken signing_dir

crudini --set /etc/heat/heat.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/heat/heat.conf keystone_authtoken admin_user $heatuser
crudini --set /etc/heat/heat.conf keystone_authtoken admin_password $heatpass
crudini --set /etc/heat/heat.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/heat/heat.conf keystone_authtoken auth_port 35357
crudini --set /etc/heat/heat.conf keystone_authtoken auth_protocol http
crudini --set /etc/heat/heat.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
crudini --set /etc/heat/heat.conf keystone_authtoken signing_dir /tmp/keystone-signing-heat

crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://$keystonehost:5000/v2.0/
 
crudini --set /etc/heat/heat.conf DEFAULT control_exchange openstack
 
case $brokerflavor in
"qpid")
	crudini --set /etc/heat/heat.conf DEFAULT rpc_backend heat.openstack.common.rpc.impl_qpid
	crudini --set /etc/heat/heat.conf DEFAULT qpid_reconnect_interval_min 0
	crudini --set /etc/heat/heat.conf DEFAULT qpid_username $brokeruser
	crudini --set /etc/heat/heat.conf DEFAULT qpid_tcp_nodelay True
	crudini --set /etc/heat/heat.conf DEFAULT qpid_protocol tcp
	crudini --set /etc/heat/heat.conf DEFAULT qpid_hostname $messagebrokerhost
	crudini --set /etc/heat/heat.conf DEFAULT qpid_password $brokerpass
	crudini --set /etc/heat/heat.conf DEFAULT qpid_port 5672
	crudini --set /etc/heat/heat.conf DEFAULT qpid_topology_version 1
	;;
 
"rabbitmq")
	crudini --set /etc/heat/heat.conf DEFAULT rpc_backend heat.openstack.common.rpc.impl_kombu
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_host $messagebrokerhost
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_userid $brokeruser
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_password $brokerpass
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_port 5672
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_use_ssl false
	crudini --set /etc/heat/heat.conf DEFAULT rabbit_virtual_host $brokervhost
	;;
esac

echo ""
echo "Heat Configurado"
echo ""

#
# Se aprovisiona la base de datos
echo ""
echo "Aprovisionando/inicializando BD de HEAT"
echo ""
chown -R heat.heat /var/log/heat /etc/heat
# su - heat -c "heat-manage db_sync"
heat-manage db_sync
chown -R heat.heat /var/log/heat /etc/heat

echo ""
echo "Listo"
echo ""

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 8000,8004 -j ACCEPT
/etc/init.d/iptables-persistent save

echo "Listo"

echo ""
echo "Activando Servicios"
echo ""

start heat-api
start heat-api-cfn
start heat-engine

testheat=`dpkg -l heat-api 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testheat == "0" ]
then
	echo ""
	echo "Falló la instalación de heat - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/heat-installed
	date > /etc/openstack-control-script-config/heat
fi


echo ""
echo "Heat Instalado"
echo ""



