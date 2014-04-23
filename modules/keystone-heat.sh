#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de indentidades Keystone para Heat
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
echo "Creando Identidades para HEAT"
echo ""

echo "Creando Usuario para Heat"
keystone user-create --name=$heatuser --pass=$heatpass --email=$heatemail
sync
sleep 5
sync

# Ya esto no es necesario
# keystoneheatuserid=`keystone user-list|grep $heatuser|grep -v $heatcfnuser|awk '{print $2}'`
# keystoneheatcfnuserid=`keystone user-list|grep $heatcfnuser|awk '{print $2}'`
# keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
# keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Agregando Role para usuario de Heat"
# keystone user-role-add --user-id $keystoneheatuserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
# keystone user-role-add --user-id $keystoneheatcfnuserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
# Nuevo método de hacer las cosas en Keystone - no usamos mas los ID's... ahora usamos los Nombres.
keystone user-role-add --user=$heatuser --tenant=$keystoneservicestenant --role=$keystoneadminuser
sync
sleep 5
sync

echo "Creando Servicios para Heat y Heat-CloudFormation"
keystone service-create --name=$heatsvce --type=orchestration --description="Heat Orchestration API"
keystone service-create --name=$heatcfnsvce --type=cloudformation --description="Heat CloudFormation API"
sync
sleep 5
sync

keystoneheatserviceid=`keystone service-get $heatsvce|grep id|awk '{print $4}'`
keystoneheatcfnserviceid=`keystone service-get $heatcfnsvce|grep id|awk '{print $4}'`

echo "Creando Endpoints para Heat y Heat-Cloudformation"

keystone endpoint-create --region=$endpointsregion \
  --service-id=$keystoneheatserviceid \
  --publicurl="http://$heathost:8004/v1/\$(tenant_id)s" \
  --internalurl="http://$heathost:8004/v1/\$(tenant_id)s" \
  --adminurl="http://$heathost:8004/v1/\$(tenant_id)s"

keystone endpoint-create --region=$endpointsregion \
  --service-id=$keystoneheatcfnserviceid \
  --publicurl="http://$heathost:8000/v1" \
  --internalurl="http://$heathost:8000/v1" \
  --adminurl="http://$heathost:8000/v1"


echo "Listo"

echo ""
echo "Todas las identidades para Heat han sido creadas"
echo ""
