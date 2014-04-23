#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de swift
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

if [ -f /etc/openstack-control-script-config/swift-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo ""
echo "Preparando recurso de filesystems"
echo ""

if [ ! -d "/srv/node" ]
then
	rm -f /etc/openstack-control-script-config/swift
	echo ""
	echo "ALERTA !. No existe el recurso de discos para swift - Abortando el"
	echo "resto de la instalación de swift"
	echo "Corrija la situación y vuelva a intentar ejecutar el módulo de"
	echo "instalación de swift"
	echo "El resto de la instalación de OpenStack continuará de manera normal,"
	echo "pero sin swift"
	echo "Se hará una pausa segundos para que lea este mensaje"
	echo ""
	sleep 10
	exit 0
fi

checkdevice=`mount|awk '{print $3}'|grep -c ^/srv/node/$swiftdevice$`

case $checkdevice in
1)
	echo ""
	echo "Punto de montaje /srv/node/$swiftdevice verificado"
	echo "continuando con la instalación"
	echo ""
	;;
0)
	rm -f /etc/openstack-control-script-config/swift
	rm -f /etc/openstack-control-script-config/swift-installed
	echo ""
	echo "ALERTA !. No existe el recurso de discos para swift - Abortando el"
	echo "resto de la instalación de swift"
	echo "Corrija la situación y vuelva a intentar ejecutar el módulo de"
	echo "instalación de swift"
	echo "El resto de la instalación de OpenStack continuará de manera normal,"
	echo "pero sin swift"
	echo "Se hará una pausa de 10 segundos para que lea este mensaje"
	echo ""
	sleep 10
	echo ""
	exit 0
	;;
esac

if [ $cleanupdeviceatinstall == "yes" ]
then
	rm -rf /srv/node/$swiftdevice/accounts
	rm -rf /srv/node/$swiftdevice/containers
	rm -rf /srv/node/$swiftdevice/objects
	rm -rf /srv/node/$swiftdevice/tmp
fi

echo ""
echo "Instalando paquetes para Swift"

aptitude -y install swift swift-account swift-container swift-doc swift-object swift-plugin-s3 swift-proxy memcached python-swift

# cp -v ./libs/swift/* /etc/swift/

stop swift-account
stop swift-account-auditor
stop swift-account-reaper
stop swift-account-replicator

stop swift-container
stop swift-container-auditor
stop swift-container-replicator
stop swift-container-updater

stop swift-object
stop swift-object-auditor
stop swift-object-replicator
stop swift-object-updater

killall -9 -u swift
killall -9 -u swift

echo "Listo"
echo ""

source $keystone_admin_rc_file

iptables -A INPUT -p tcp -m multiport --dports 6000,6001,6002,873 -j ACCEPT
/etc/init.d/iptables-persistent save

chown -R swift:swift /srv/node/

echo ""
echo "Configurando Swift"
echo ""

mkdir -p /var/lib/keystone-signing-swift
chown swift:swift /var/lib/keystone-signing-swift

echo "#" >> /etc/swift/swift.conf
echo "#" >> /etc/swift/object-server.conf
echo "#" >> /etc/swift/container-server.conf
echo "#" >> /etc/swift/proxy-server.conf

crudini --set /etc/swift/swift.conf swift-hash swift_hash_path_suffix $(openssl rand -hex 10)
# Ya no se necesita ???... esperando confirmación...
# crudini --set /etc/swift/swift.conf swift-hash swift_hash_path_prefix $(openssl rand -hex 10)
 
swiftworkers=`grep processor.\*: /proc/cpuinfo |wc -l`
 
crudini --set /etc/swift/object-server.conf DEFAULT bind_ip $swifthost
crudini --set /etc/swift/object-server.conf DEFAULT workers $swiftworkers
crudini --set /etc/swift/object-server.conf DEFAULT devices /srv/node
crudini --set /etc/swift/object-server.conf DEFAULT bind_port 6000
crudini --set /etc/swift/object-server.conf DEFAULT mount_check false
crudini --set /etc/swift/object-server.conf DEFAULT user swift
crudini --set /etc/swift/account-server.conf DEFAULT bind_ip $swifthost
crudini --set /etc/swift/account-server.conf DEFAULT workers $swiftworkers
crudini --set /etc/swift/account-server.conf DEFAULT devices /srv/node
crudini --set /etc/swift/account-server.conf DEFAULT bind_port 6002
crudini --set /etc/swift/account-server.conf DEFAULT mount_check false
crudini --set /etc/swift/account-server.conf DEFAULT user swift
crudini --set /etc/swift/container-server.conf DEFAULT bind_ip $swifthost
crudini --set /etc/swift/container-server.conf DEFAULT workers $swiftworkers
crudini --set /etc/swift/container-server.conf DEFAULT devices /srv/node
crudini --set /etc/swift/container-server.conf DEFAULT bind_port 6001
crudini --set /etc/swift/container-server.conf DEFAULT mount_check false
crudini --set /etc/swift/container-server.conf DEFAULT user swift


start swift-account
start swift-account-auditor
start swift-account-reaper
start swift-account-replicator

start swift-container
start swift-container-auditor
start swift-container-replicator
start swift-container-updater

start swift-object
start swift-object-auditor
start swift-object-replicator
start swift-object-updater

restart swift-account
restart swift-account-auditor
restart swift-account-reaper
restart swift-account-replicator

restart swift-container
restart swift-container-auditor
restart swift-container-replicator
restart swift-container-updater

restart swift-object
restart swift-object-auditor
restart swift-object-replicator
restart swift-object-updater

crudini --set /etc/swift/proxy-server.conf DEFAULT bind_port 8080
crudini --set /etc/swift/proxy-server.conf DEFAULT workers $swiftworkers
crudini --set /etc/swift/proxy-server.conf "pipeline:main" pipeline "healthcheck cache authtoken keystoneauth proxy-server"
crudini --set /etc/swift/proxy-server.conf "app:proxy-server" use "egg:swift#proxy"
crudini --set /etc/swift/proxy-server.conf "app:proxy-server" allow_account_management true
crudini --set /etc/swift/proxy-server.conf "app:proxy-server" account_autocreate true
crudini --set /etc/swift/proxy-server.conf "filter:keystoneauth" use "egg:swift#keystoneauth"
crudini --set /etc/swift/proxy-server.conf "filter:keystoneauth" operator_roles "Member,admin,swiftoperator"
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" paste.filter_factory "keystoneclient.middleware.auth_token:filter_factory"
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" delay_auth_decision true
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" admin_token $SERVICE_TOKEN
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" auth_token $SERVICE_TOKEN
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" admin_tenant_name $keystoneservicestenant
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" admin_user $swiftuser
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" admin_password $swiftpass
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" auth_host $keystonehost
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" auth_port 35357
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" auth_protocol http
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" auth_uri http://$keystonehost:5000
crudini --set /etc/swift/proxy-server.conf "filter:authtoken" signing_dir /var/lib/keystone-signing-swift
crudini --set /etc/swift/proxy-server.conf "filter:cache" use "egg:swift#memcache"
crudini --set /etc/swift/proxy-server.conf "filter:catch_errors" use "egg:swift#catch_errors"
crudini --set /etc/swift/proxy-server.conf "filter:healthcheck" use "egg:swift#healthcheck"

mkdir -p /var/lib/keystone-signing-swift
chown -R swift:swift /var/lib/keystone-signing-swift


if [ $ceilometerinstall == "yes" ]
then
        crudini --set /etc/swift/proxy-server.conf filter:ceilometer use "egg:ceilometer#swift"
	# El manual dice que hay que hacer el siguiente paso, pero esto impide que funcione swifg
	# se deja comentado hasta investigar mas
	# crudini --set /etc/swift/proxy-server.conf pipeline:main pipeline "healthcheck cache authtoken keystoneauth ceilometer proxy-server"
fi

start memcached
start swift-proxy

update-rc.d mencached enable

swift-ring-builder /etc/swift/object.builder create $partition_power $replica_count $partition_min_hours
swift-ring-builder /etc/swift/container.builder create $partition_power $replica_count $partition_min_hours
swift-ring-builder /etc/swift/account.builder create $partition_power $replica_count $partition_min_hours

swift-ring-builder /etc/swift/account.builder add z$swiftfirstzone-$swifthost:6002/$swiftdevice $partition_count
swift-ring-builder /etc/swift/container.builder add z$swiftfirstzone-$swifthost:6001/$swiftdevice $partition_count
swift-ring-builder /etc/swift/object.builder add z$swiftfirstzone-$swifthost:6000/$swiftdevice $partition_count

swift-ring-builder /etc/swift/account.builder rebalance
swift-ring-builder /etc/swift/container.builder rebalance
swift-ring-builder /etc/swift/object.builder rebalance


sync
stop swift-proxy
start swift-proxy
sync

iptables -A INPUT -p tcp -m multiport --dports 8080 -j ACCEPT
/etc/init.d/iptables-persistent save

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

sync
sleep 2
sync

for i in $swift_svc_start
do
	start $i
done

echo ""
echo "Listo"
echo ""

testswift=`dpkg -l swift-proxy 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testswift == "0" ]
then
	echo ""
	echo "Falló la instalación de swift - abortando el resto de la instalación"
	echo ""
	rm -f /etc/openstack-control-script-config/swift
	rm -f /etc/openstack-control-script-config/swift-installed
	exit 0
else
	date > /etc/openstack-control-script-config/swift-installed
	date > /etc/openstack-control-script-config/swift
fi

echo ""
echo "Instalación básica de SWIFT terminada"
echo ""

