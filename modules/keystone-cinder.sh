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
echo "Creando Identidades para CINDER"
echo ""

echo "Creando usuario para Cinder"
keystone user-create --name $cinderuser --pass $cinderpass --email $cinderemail
sync
sleep 5
sync

keystonecinderuserid=`keystone user-list|grep $cinderuser|awk '{print $2}'`
keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Asignando roles para usuario de Cinder"
keystone user-role-add --user-id $keystonecinderuserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
sync
sleep 5
sync

echo "Creando servicio para Cinder V1 y V2"
keystone service-create --name $cindersvce --type volume --description "Cinder Block Storage Service V1"
keystone service-create --name $cindersvcev2 --type volumev2 --description "Cinder Block Storage Service V2"
sync
sleep 5
sync

keystonecinderserviceid=`keystone service-get $cindersvce|grep id|awk '{print $4}'`
keystonecinderv2serviceid=`keystone service-get $cindersvcev2|grep id|awk '{print $4}'`

echo "Creando endpoint para Cinder V1"
keystone endpoint-create --region $endpointsregion --service-id $keystonecinderserviceid --publicurl "http://$cinderhost:8776/v1/\$(tenant_id)s" --adminurl "http://$cinderhost:8776/v1/\$(tenant_id)s" --internalurl "http://$cinderhost:8776/v1/\$(tenant_id)s"

echo "Creando endpoint para Cinder V2"
keystone endpoint-create --region $endpointsregion --service-id $keystonecinderv2serviceid --publicurl "http://$cinderhost:8776/v2/\$(tenant_id)s" --adminurl "http://$cinderhost:8776/v2/\$(tenant_id)s" --internalurl "http://$cinderhost:8776/v2/\$(tenant_id)s"

echo "Listo"

echo ""
echo "Identidades para CINDER Creadas"
echo ""
