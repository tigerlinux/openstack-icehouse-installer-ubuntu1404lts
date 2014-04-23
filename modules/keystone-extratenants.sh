#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de extra user/tenants de Keystone
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

#
# Se crean los tenants y usuarios extras
#

keystonememberroleid=`keystone role-get $keystonememberrole|grep id|awk '{print $4}'`

for myidentityname in $extratenants
do
	keystone tenant-create --name $myidentityname
	sync
	sleep 5
	sync
	mytenantid=`keystone tenant-get $myidentityname|grep id|awk '{print $4}'`
	keystone user-create --name $myidentityname --pass "$myidentityname-$extratenantbasepass" --email "$myidentityname@$domainextratenants"
	sync
	sleep 5
	sync
	myuserid=`keystone user-list|grep $myidentityname|awk '{print $2}'`
	# Finalmente agregamos el usuario nuevo con su tenant al role de Member declarado en
	# la variable keystonememberrole
	keystone user-role-add --user-id $myidentityname --role-id $keystonememberroleid --tenant-id $myidentityname
	sync
	sleep 5
	sync
done

