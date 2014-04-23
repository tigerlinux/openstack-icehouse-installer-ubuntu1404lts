#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de keystone
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
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

if [ $keystoneinstall == "no" ]
then
	SERVICE_ENDPOINT="http://$keystonehost:35357/v2.0"
	OS_USERNAME=$keystoneadminuser
	OS_TENANT_NAME=$keystoneadminuser
	OS_PASSWORD=$keystoneadminpass
	# OS_AUTH_URL="http://$keystonehost:35357/v2.0/"
	OS_AUTH_URL="http://$keystonehost:5000/v2.0/"

	echo "# export SERVICE_ENDPOINT=$SERVICE_ENDPOINT" > $keystone_admin_rc_file
	echo "# export SERVICE_TOKEN=$SERVICE_TOKEN" >> $keystone_admin_rc_file
	echo "# export OS_SERVICE_TOKEN=$SERVICE_TOKEN" >> $keystone_admin_rc_file
	echo "export OS_USERNAME=$OS_USERNAME" >> $keystone_admin_rc_file
	echo "export OS_PASSWORD=$OS_PASSWORD" >> $keystone_admin_rc_file
	echo "export OS_TENANT_NAME=$OS_TENANT_NAME" >> $keystone_admin_rc_file
	echo "export OS_AUTH_URL=$OS_AUTH_URL" >> $keystone_admin_rc_file
	echo "PS1='[\u@\h \W(keystone_admin)]\$ '" >> $keystone_admin_rc_file

	mkdir -p /etc/openstack-control-script-config
	date > /etc/openstack-control-script-config/keystone-installed
	date > /etc/openstack-control-script-config/keystone-extra-idents

	echo ""
	echo "En la configuración, el valor de la variable de instalación de keystone"
	echo "está en \"no\", por lo tanto no se instaló ni configuró Keystone en este"
	echo "host, pero si se dejó configurado el archivo \"$keystone_admin_rc_file\""
	echo ""
	exit 0
fi

echo "Instalando Paquetes para Keystone"

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

aptitude -y install keystone keystone-doc python-keystone python-keystoneclient python-psycopg2

stop keystone

rm -f /tmp/keystone-seed.txt

echo "Listo"

echo $SERVICE_TOKEN > /root/ks_admin_token
export SERVICE_TOKEN
OS_SERVICE_TOKEN=$SERVICE_TOKEN
export OS_SERVICE_TOKEN

echo ""
echo "Configurando Keystone"

crudini --set /etc/keystone/keystone.conf DEFAULT admin_token $SERVICE_TOKEN
crudini --set /etc/keystone/keystone.conf DEFAULT bind_host 0.0.0.0
crudini --set /etc/keystone/keystone.conf DEFAULT public_port 5000
crudini --set /etc/keystone/keystone.conf DEFAULT admin_port 35357
crudini --set /etc/keystone/keystone.conf DEFAULT compute_port 8774
crudini --set /etc/keystone/keystone.conf DEFAULT debug False
crudini --set /etc/keystone/keystone.conf DEFAULT verbose False
crudini --set /etc/keystone/keystone.conf DEFAULT log_file /var/log/keystone/keystone.log
crudini --set /etc/keystone/keystone.conf DEFAULT use_syslog False


case $dbflavor in
"mysql")
	crudini --set /etc/keystone/keystone.conf database connection mysql://$keystonedbuser:$keystonedbpass@$dbbackendhost:$mysqldbport/$keystonedbname
	;;
"postgres")
	crudini --set /etc/keystone/keystone.conf database connection postgresql://$keystonedbuser:$keystonedbpass@$dbbackendhost:$psqldbport/$keystonedbname
	;;
esac

crudini --set /etc/keystone/keystone.conf sql idle_timeout 200
crudini --set /etc/keystone/keystone.conf catalog driver keystone.catalog.backends.sql.Catalog
crudini --set /etc/keystone/keystone.conf token provider keystone.token.providers.pki.Provider
crudini --set /etc/keystone/keystone.conf token expiration 86400
crudini --set /etc/keystone/keystone.conf token driver keystone.token.backends.sql.Token

chown -R keystone:keystone /var/log/keystone

keystone-manage pki_setup --keystone-user keystone --keystone-group keystone

chown -R keystone:keystone /var/log/keystone /etc/keystone/ssl

rm -f /var/lib/keystone/keystone.db

su keystone -s /bin/sh -c "keystone-manage db_sync"

echo "Listo"
echo ""

echo "Activando Servicios de Keystone"

start keystone

echo "Listo"

sync
sleep 5
sync

echo ""

echo "Creando entrada para el servicio keystone"
export SERVICE_ENDPOINT="http://$keystonehost:35357/v2.0"
keystone service-create --name=$keystoneservicename --type=identity --description="Keystone Identity Service"
keystoneserviceid=`keystone service-list|grep $keystoneservicename|awk '{print $2}'`

sync
sleep 5
sync

echo "Creando endpoint V 2.0 para servicio keystone"
keystone endpoint-create --region $endpointsregion --service_id $keystoneserviceid --publicurl "http://$keystonehost:5000/v2.0" --adminurl "http://$keystonehost:35357/v2.0" --internalurl "http://$keystonehost:5000/v2.0"

sync
sleep 5
sync

echo "Creando usuario administrativo para keystone: $keystoneadminuser"
keystone user-create --name $keystoneadminuser --pass $keystoneadminpass --email $keystoneadminuseremail
keystoneadminuserid=`keystone user-list|grep $keystoneadminuser|awk '{print $2}'`

sync
sleep 5
sync

echo "Creando role administrativo $keystoneadminuser"
keystone role-create --name $keystoneadminuser
keystoneadminroleid=`keystone role-list|grep $keystoneadminuser|awk '{print $2}'`

sync
sleep 5
sync

echo "Creando tenant administrativo $keystoneadminuser"
keystone tenant-create --name $keystoneadminuser
keystoneadmintenantid=`keystone tenant-list|grep $keystoneadminuser|awk '{print $2}'`

sync
sleep 5
sync

echo "Agregando role administrativo al usuario $keystoneadminuser"
keystone user-role-add --user-id $keystoneadminuserid --role-id $keystoneadminroleid --tenant-id $keystoneadmintenantid

sync
sleep 5
sync

echo "Creando el tenant $keystoneservicetenant"
keystone tenant-create --name $keystoneservicestenant

# Para el dashboard
echo "Creando el role $keystonememberrole"
keystone role-create --name $keystonememberrole
keystonememberroleid=`keystone role-list|grep $keystonememberrole|awk '{print $2}'`

keystone user-role-add --user-id $keystoneadminuserid --role-id $keystonememberroleid --tenant-id $keystoneadmintenantid

sync
sleep 5
sync

SERVICE_ENDPOINT="http://$keystonehost:35357/v2.0"
OS_USERNAME=$keystoneadminuser
OS_TENANT_NAME=$keystoneadminuser
OS_PASSWORD=$keystoneadminpass
# OS_AUTH_URL="http://$keystonehost:35357/v2.0/"
OS_AUTH_URL="http://$keystonehost:5000/v2.0/"

echo "# export SERVICE_ENDPOINT=$SERVICE_ENDPOINT" > $keystone_admin_rc_file
echo "# export SERVICE_TOKEN=$SERVICE_TOKEN" >> $keystone_admin_rc_file
echo "# export OS_SERVICE_TOKEN=$SERVICE_TOKEN" >> $keystone_admin_rc_file
echo "export OS_USERNAME=$OS_USERNAME" >> $keystone_admin_rc_file
echo "export OS_PASSWORD=$OS_PASSWORD" >> $keystone_admin_rc_file
echo "export OS_TENANT_NAME=$OS_TENANT_NAME" >> $keystone_admin_rc_file
echo "export OS_AUTH_URL=$OS_AUTH_URL" >> $keystone_admin_rc_file
echo "PS1='[\u@\h \W(keystone_admin)]\$ '" >> $keystone_admin_rc_file

source $keystone_admin_rc_file

echo "Datos configurados a continuacion:"
keystone tenant-list
keystone user-list
keystone service-list
keystone endpoint-list

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 5000,35357 -j ACCEPT
/etc/init.d/iptables-persistent save

keystonetest=`dpkg -l keystone 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $keystonetest == "0" ]
then
	echo ""
	echo "Falló la instalación de Keystone - saliendo del módulo"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/keystone-installed
	date > /etc/openstack-control-script-config/keystone
fi

checkadmincreate=`keystone user-list|awk '{print $4}'|grep -ci ^$keystoneadminuser$`

if [ $checkadmincreate == "0" ]
then
	echo ""
	echo "Falló la creación del usuario administrativo - abortando el módulo"
	echo ""
	rm -f /etc/openstack-control-script-config/keystone-installed
	rm -f /etc/openstack-control-script-config/keystone
	exit 0
fi

echo ""
echo "Se procederá a crear las identidades, roles, servicios y endpoints para Swift, Glance, Cinder, Neutron, Nova y Ceilometer"
echo ""


if [ $swiftinstall == "yes" ]
then
        ./modules/keystone-swift.sh
fi

if [ $glanceinstall == "yes" ]
then
        ./modules/keystone-glance.sh
fi

if [ $cinderinstall == "yes" ]
then
        ./modules/keystone-cinder.sh
fi

if [ $neutroninstall == "yes" ]
then
        ./modules/keystone-neutron.sh
fi

if [ $novainstall == "yes" ]
then
        ./modules/keystone-nova.sh
fi

if [ $ceilometerinstall == "yes" ]
then
        ./modules/keystone-ceilometer.sh
fi

if [ $heatinstall == "yes" ]
then
	./modules/keystone-heat.sh
fi

./modules/keystone-extratenants.sh

date > /etc/openstack-control-script-config/keystone-extra-idents

echo ""
echo "Listo"

echo ""
echo "Keystone y dependencias instalados"
echo ""

echo "A continuación la lista completa de tenants, usuarios, servicios y roles"
echo ""
echo "Tenants:"
keystone tenant-list
sleep 5
echo "Users:"
keystone user-list
sleep 5
echo "Services:"
keystone service-list
sleep 5
echo "Roles:"
keystone role-list
sleep 5
echo "Endpoints:"
keystone endpoint-list
sleep 5
echo ""
echo "Proceso de identidades finalizado"
echo ""


