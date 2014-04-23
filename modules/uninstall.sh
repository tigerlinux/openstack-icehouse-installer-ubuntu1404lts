#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de desinstalacion de OpenStack para Ubuntu
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador en su directorio"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

clear

echo "Bajando y desactivando Servicios de OpenStack"

/usr/local/bin/openstack-control.sh stop
/usr/local/bin/openstack-control.sh disable

rm -rf /tmp/keystone-signing-*
rm -rf /tmp/cd_gen_*


if [ $ceilometerinstall == "yes" ]
then
	/etc/init.d/mongodb force-stop
	/etc/init.d/mongodb force-stop
	killall -9 -u mongodb
	aptitude -y purge mongodb mongodb-clients mongodb-dev mongodb-server
	aptitude -y purge mongodb-10gen
	userdel -f -r mongodb
	rm -rf 	/var/lib/mongodb /var/log/mongodb
fi

killall -9 dnsmasq

echo ""
echo "Eliminando Paquetes de OpenStack"
echo ""


if [ $horizoninstall == "yes" ]
then
	echo ""
	echo "Limpiando Apache de referencias del Dashboard"
	echo ""
	# a2dissite openstack-dashboard.conf
	# a2dissite openstack-dashboard-ssl.conf
	# a2dissite openstack-dashboard-ssl-redirect.conf
	# a2ensite default

	# a2dismod wsgi

	# service apache2 restart

	# cp -v ./libs/openstack-dashboard* /etc/apache2/sites-available/
	# chmod 644 /etc/apache2/sites-available/openstack-dashboard*

	aptitude -y purge memcached apache2 apache2-bin libapache2-mod-wsgi \
		openstack-dashboard libapache2-mod-python \
		openstack-dashboard-ubuntu-theme python-mod-pywebsocket \
		libapache2-mod-python

	# rm -f /etc/apache2/sites-available/openstack-dashboard*
	# rm -f /etc/apache2/sites-enabled/openstack-dashboard*

	rm -rf /usr/share/openstack-dashboard/
	rm -rf /etc/apache2
	userdel -r horizon
	apt-get -y autoremove

	echo ""
	echo "Listo"
	echo ""
fi

echo ""
echo "Purgando paquetes"
echo ""

# rm -f /etc/dbconfig-common/heat-common.conf

echo "heat-common heat-common/dbconfig-remove boolean false" > /tmp/heat-seed.txt
debconf-set-selections /tmp/heat-seed.txt

aptitude -y purge virt-top ceilometer-agent-central ceilometer-agent-compute ceilometer-api \
	ceilometer-collector ceilometer-common python-ceilometer python-ceilometerclient nova-api \
	nova-cert nova-common nova-compute nova-conductor nova-console nova-consoleauth \
	nova-consoleproxy nova-doc nova-scheduler nova-volume nova-compute-qemu nova-compute-kvm \
	python-novaclient liblapack3gf python-gtk-vnc novnc neutron-server neutron-common \
	neutron-dhcp-agent neutron-l3-agent neutron-lbaas-agent neutron-metadata-agent python-neutron \
	python-neutronclient neutron-plugin-openvswitch neutron-plugin-openvswitch-agent haproxy \
	cinder-api cinder-common cinder-scheduler cinder-volume python-cinderclient tgt open-iscsi \
	glance glance-api glance-common glance-registry swift swift-account swift-container swift-doc \
	swift-object swift-plugin-s3 swift-proxy memcached python-swift keystone keystone-doc \
	python-keystone python-keystoneclient python-psycopg2 python-sqlalchemy python-sqlalchemy-ext \
	python-psycopg2 python-mysqldb dnsmasq dnsmasq-utils qpidd libqpidbroker2 libqpidclient2 \
	libqpidcommon2 libqpidtypes1 python-cqpid python-qpid python-qpid-extras-qmf qpid-client \
	qpid-tools qpid-doc qemu kvm qemu-kvm libvirt-bin libvirt-doc rabbitmq-server \
	heat-api heat-api-cfn heat-engine neutron-plugin-ml2 python-guestfs heat-cfntools \
	heat-common

aptitude -y purge python-openstack.nose-plugin  python-oslo.sphinx python-oslosphinx

aptitude -y purge qemu-utils qemu-system qemu-utils ipxe-qemu qemu-keymaps qemu-system-x86 qemu-user \
	libguestfs0 qemu-system-common

apt-get -y autoremove

rm -f /tmp/heat-seed.txt

if [ $cleanupdeviceatuninstall == "yes" ]
then
	rm -rf /srv/node/$swiftdevice/accounts
	rm -rf /srv/node/$swiftdevice/containers
	rm -rf /srv/node/$swiftdevice/objects
	rm -rf /srv/node/$swiftdevice/tmp
	chown -R root:root /srv/node/
fi

echo "Eliminando Usuarios de Servicios de OpenStack"

userdel -f -r qpidd
userdel -f -r keystone
userdel -f -r glance
userdel -f -r cinder
userdel -f -r neutron
userdel -f -r nova
userdel -f -r ceilometer
userdel -f -r swift
userdel -r -f rabbitmq
userdel -r -f heat

echo "Eliminando Archivos remanentes"

# rm -f /usr/local/bin/crudini

rm -fr  /etc/qpid \
	/var/run/qpid \
	/var/log/qpid \
	/var/spool/qpid \
	/var/spool/qpidd \
	/var/lib/libvirt \
	/etc/glance \
	/etc/keystone \
	/var/log/glance \
	/var/log/keystone \
	/var/lib/glance \
	/var/lib/keystone \
	/etc/cinder \
	/var/lib/cinder \
	/var/log/cinder \
	/etc/sudoers.d/cinder \
	/etc/tgt \
	/etc/neutron \
	/var/lib/neutron \
	/var/lib/heat \
	/var/log/neutron \
	/var/log/heat \
	/etc/sudoers.d/neutron \
	/etc/nova \
	/etc/heat \
	/var/log/nova \
	/var/lib/nova \
	/etc/sudoers.d/nova \
	/etc/openstack-dashboard \
	/var/log/horizon \
	/etc/ceilometer \
	/var/log/ceilometer \
	/var/lib/ceilometer \
	/etc/ceilometer-collector.conf \
	/etc/swift/ \
	/var/lib/swift \
	/var/cache/swift \
	/tmp/keystone-signing-swift \
	/var/lib/rabbitmq \
	/etc/openstack-control-script-config \
	/var/lib/keystone-signing-swift \
	$dnsmasq_config_file \
	/etc/dnsmasq-neutron.d \
	/etc/init.d/tgtd




rm -f /root/keystonerc_admin
rm -f /root/ks_admin_token

rm -f /usr/local/bin/openstack-control.sh
rm -f /usr/local/bin/openstack-log-cleaner.sh
rm -f /usr/local/bin/openstack-keystone-tokenflush.sh
rm -f /usr/local/bin/openstack-vm-boot-start.sh
rm -f /etc/cron.d/keystone-flush-crontab

if [ $snmpinstall == "yes" ]
then
	if [ -f /etc/snmp/snmpd.conf.pre-openstack ]
	then
		rm -f /etc/snmp/snmpd.conf
		mv /etc/snmp/snmpd.conf.pre-openstack /etc/snmp/snmpd.conf
		service snmpd restart
	else
		service snmpd stop
		aptitude -y purge snmpd snmp-mibs-downloader snmp virt-top
		rm -rf /etc/snmp/snmpd.*
	fi
	rm -f /etc/cron.d/openstack-monitor.crontab \
	/var/tmp/node-cpu.txt \
	/var/tmp/node-memory.txt \
	/var/tmp/packstack \
	/var/tmp/vm-cpu-ram.txt \
	/var/tmp/vm-disk.txt \
	/var/tmp/vm-number-by-states.txt \
	/usr/local/bin/vm-number-by-states.sh \
	/usr/local/bin/vm-total-cpu-and-ram-usage.sh \
	/usr/local/bin/vm-total-disk-bytes-usage.sh \
	/usr/local/bin/node-cpu.sh \
	/usr/local/bin/node-memory.sh

	service cron restart
fi

echo "Limpiando IPTABLES"

/etc/init.d/iptables-persistent flush
/etc/init.d/iptables-persistent save

if [ $dbinstall == "yes" ]
then

	echo ""
	echo "Desinstalando software de Base de Datos"
	echo ""
	case $dbflavor in
	"mysql")
		/etc/init.d/mysql stop
		sync
		sleep 5
		sync
		aptitude -y purge mysql-server-5.5 mysql-server mysql-server-core-5.5 mysql-common \
			libmysqlclient18 mysql-client-5.5
		userdel -f -r mysql
		rm -rf /var/lib/mysql
		rm -rf /root/.my.cnf
		rm -rf /etc/mysql
		rm -rf /var/log/mysql
		;;
	"postgres")
		/etc/init.d/postgresql stop
		sync
		sleep 5
		sync
		apt-get -y purge postgresql postgresql-client  postgresql-9.3 postgresql-client-9.3 \
			postgresql-client-common postgresql-common postgresql-doc postgresql-doc-9.3
		userdel -f -r postgres
		rm -f /root/.pgpass
		rm -rf /etc/postgresql
		rm -rf /etc/postgresql-common
		rm -rf /var/log/postgresql
		;;
	esac
	apt-get -y autoremove
fi

echo ""
echo "Desinstalación completada"
echo ""

