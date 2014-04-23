#!/bin/bash
#
# Instalador desatendido para Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de Post-Instalación
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

if [ -f /etc/openstack-control-script-config/postinstall-done ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

cp -v ./libs/openstack-control.sh /usr/local/bin/
cp -v ./libs/openstack-log-cleaner.sh /usr/local/bin/
cp -v ./libs/openstack-vm-boot-start.sh /usr/local/bin/
cp -v ./libs/openstack-keystone-tokenflush.sh /usr/local/bin/
cp -v ./libs/keystone-flush-crontab /etc/cron.d/
cp -v ./libs/nova-start-vms.conf /etc/openstack-control-script-config/
 
chmod 755 /usr/local/bin/openstack-control.sh
chmod 755 /usr/local/bin/openstack-log-cleaner.sh
chmod 755 /usr/local/bin/openstack-keystone-tokenflush.sh
chmod 755 /usr/local/bin/openstack-vm-boot-start.sh

service cron reload

echo ""
echo "Reiniciando todos los servicios y limpiando los logs"
echo ""

/usr/local/bin/openstack-control.sh stop
sleep 1
sync
/usr/local/bin/openstack-log-cleaner.sh auto
sync
sleep 1
/usr/local/bin/openstack-control.sh start

echo ""
echo "Post Install Finalizado"
echo ""
echo "Recuerde usar el script /usr/local/bin/openstack-control.sh para administrar"
echo "los servicios de OpenStack"
echo ""
/usr/local/bin/openstack-control.sh status
echo ""

