#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de indentidades Keystone para Cinder
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

if [ -f /etc/openstack-control-script-config/keystone-extra-idents ]
then
	echo ""
	echo "Aparentemente todas las identidades ya fueron creadas"
	echo "Saliendo del módulo"
	echo ""
	exit 0
fi

source $keystone_admin_rc_file

echo ""
echo "Creando Identidades para swift"
echo ""

echo "Creando usuario para swift"
keystone user-create --name $swiftuser --pass $swiftpass --email $swiftemail
sync
sleep 5
sync

keystoneswiftuserid=`keystone user-list|grep $swiftuser|awk '{print $2}'`
keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Asignando roles para usuario de swift"
keystone user-role-add --user-id $keystoneswiftuserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
sync
sleep 5
sync

echo "Creando servicio para swift"
keystone service-create --name $swiftsvce --type object-store --description "Swift Object Store Service"
sync
sleep 5
sync

keystoneswiftserviceid=`keystone service-get $swiftsvce|grep id|awk '{print $4}'`

echo "Creando endpoint para swift"
keystone endpoint-create --region $endpointsregion --service-id $keystoneswiftserviceid --publicurl "http://$swifthost:8080/v1/AUTH_\$(tenant_id)s" --adminurl "http://$swifthost:8080/v1" --internalurl "http://$swifthost:8080/v1/AUTH_\$(tenant_id)s"

echo "Listo"

echo ""
echo "Identidades para swift Creadas"
echo ""
