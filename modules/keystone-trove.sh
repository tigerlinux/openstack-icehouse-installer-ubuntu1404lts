#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de indentidades Keystone para Trove
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
echo "Creando Identidades para TROVE"
echo ""

echo "Creando Usuario para Trove"
keystone user-create --name=$troveuser --pass=$trovepass --email=$troveemail
sync
sleep 5
sync

echo "Creando Tenant para Trove"
keystone tenant-create --name=$troveuser

echo "Agregando Role para usuario de Trove en tenants $troveuser y $keystoneservicestenant"
keystone user-role-add --user=$troveuser --tenant=$troveuser --role=$keystoneadminuser
keystone user-role-add --user=$troveuser --tenant=$keystoneservicestenant --role=$keystoneadminuser
sync
sleep 5
sync

echo "Creando Servicios para Trove"
keystone service-create --name=$trovesvce --type=database --description="OpenStack Database Service"
sync
sleep 5
sync

keystonetroveserviceid=`keystone service-get $trovesvce|grep id|awk '{print $4}'`

echo "Creando Endpoints para Trove"

keystone endpoint-create --region=$endpointsregion \
  --service-id=$keystonetroveserviceid \
  --publicurl="http://$trovehost:8779/v1.0/\$(tenant_id)s" \
  --internalurl="http://$trovehost:8779/v1.0/\$(tenant_id)s" \
  --adminurl="http://$trovehost:8779/v1.0/\$(tenant_id)s"

echo "Listo"

echo ""
echo "Todas las identidades para Trove han sido creadas"
echo ""
