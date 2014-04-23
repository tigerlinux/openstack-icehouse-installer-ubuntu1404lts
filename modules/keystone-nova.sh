#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de indentidades Keystone para Nova
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
echo "Creando Identidades para NOVA"
echo ""

echo "Creando Usuario para Nova"
keystone user-create --name $novauser --pass $novapass --email $novaemail
sync
sleep 5
sync

keystonenovauserid=`keystone user-list|grep $novauser|awk '{print $2}'`
keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Agregando roll al usuario de Nova"
keystone user-role-add --user-id $keystonenovauserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
sync
sleep 5
sync

echo "Creando servicio para Nova"
keystone service-create --name $novasvce --type compute --description "Nova Compute Service"
sync
sleep 5
sync

echo "Creando servicio para EC2"
keystone service-create --name $novaec2svce --type ec2 --description 'EC2 Nova OpenStack Service'
sync
sleep 5
sync

keystonenovaserviceid=`keystone service-get $novasvce|grep id|awk '{print $4}'`
keystonenovaec2serviceid=`keystone service-get $novaec2svce|grep id|awk '{print $4}'`

echo "Creando endpoint para EC2"
keystone endpoint-create --region $endpointsregion --service-id $keystonenovaec2serviceid --publicurl "http://$novahost:8773/services/Cloud" --adminurl "http://$novahost:8773/services/Admin" --internalurl "http://$novahost:8773/services/Cloud"

echo "Creando endpoint para Nova"
keystone endpoint-create --region $endpointsregion --service-id $keystonenovaserviceid --publicurl "http://$novahost:8774/v2/\$(tenant_id)s" --adminurl "http://$novahost:8774/v2/\$(tenant_id)s" --internalurl "http://$novahost:8774/v2/\$(tenant_id)s"

echo "Listo"
echo ""
echo "Han sido creadas las identidades para NOVA"
echo ""
