#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de indentidades Keystone para Ceilometer
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
echo "Creando Identidades para CEILOMETER"
echo ""

echo "Creando Usuario para ceilometer"
keystone user-create --name $ceilometeruser --pass $ceilometerpass --email $ceilometeremail
sync
sleep 5
sync

keystoneceilometeruserid=`keystone user-list|grep $ceilometeruser|awk '{print $2}'`
keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Agregando Rol para usuario de ceilometer"
keystone user-role-add --user-id $keystoneceilometeruserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
sync
sleep 5
sync

echo "Creando Servicio para ceilometer"
keystone service-create --name $ceilometersvce --type metering --description "Ceilometer Metering Service"
sync
sleep 5
sync

keystoneceilometerserviceid=`keystone service-get $ceilometersvce|grep id|awk '{print $4}'`

echo "Creando Endpoint para ceilometer"
keystone endpoint-create --region $endpointsregion --service-id $keystoneceilometerserviceid --publicurl "http://$ceilometerhost:8777" --adminurl "http://$ceilometerhost:8777" --internalurl "http://$ceilometerhost:8777"

echo "Creando el role $keystonereselleradminrole"
keystone role-create --name $keystonereselleradminrole
keystoneresellerroleid=`keystone role-list|grep $keystonereselleradminrole|awk '{print $2}'`
keystone user-role-add --user-id $keystoneceilometeruserid --role-id $keystoneresellerroleid --tenant-id $keystoneservicetenantid



echo "Listo"

echo ""
echo "Todas las identidades para ceilometer han sido creadas"
echo ""
