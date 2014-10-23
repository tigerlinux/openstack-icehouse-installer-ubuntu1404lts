#!/bin/bash
#
# Instalador desatendido para Openstack Icehouse sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script de instalacion y preparacion de Nova
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

if [ -f /etc/openstack-control-script-config/nova-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo ""
echo "Instalando paquetes para Nova"

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

echo "glance-common glance/admin-password password $glancepass" > /tmp/glance-seed.txt
echo "glance-common glance/auth-host string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-api glance/keystone-ip string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-common glance/paste-flavor select keystone" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-tenant-name string $keystoneadmintenant" >> /tmp/glance-seed.txt
echo "glance-api glance/endpoint-ip string $glancehost" >> /tmp/glance-seed.txt
echo "glance-api glance/region-name string $endpointsregion" >> /tmp/glance-seed.txt
echo "glance-api glance/register-endpoint boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-user	string $keystoneadminuser" >> /tmp/glance-seed.txt
echo "glance-common glance/configure_db boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_host string $messagebrokerhost" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_password password $brokerpass" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_userid string $brokeruser" >> /tmp/glance-seed.txt

debconf-set-selections /tmp/glance-seed.txt

echo "cinder-common cinder/admin-password password $cinderpass" > /tmp/cinder-seed.txt
echo "cinder-api cinder/region-name string $endpointsregion" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/configure_db boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-tenant-name string $keystoneadmintenant" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/register-endpoint boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/auth-host string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/start_services boolean false" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/endpoint-ip string $cinderhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/volume_group string cinder-volumes" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/keystone-ip string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-user string $keystoneadminuser" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_password password $brokerpass" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_host string $messagebrokerhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_userid string $brokeruser" >> /tmp/cinder-seed.txt

debconf-set-selections /tmp/cinder-seed.txt

echo "neutron-common neutron/admin-password password $keystoneadminpass" > /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-password password $keystoneadminpass" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/keystone-ip string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/local_ip string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/register-endpoint boolean false" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tunnel_id_ranges string 0" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/endpoint-ip string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "openswan openswan/install_x509_certificate boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_password password $brokerpass" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_userid string $brokeruser" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_host string $messagebrokerhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tunnel_id_ranges string 1" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/plugin-select select OpenVSwitch" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/local_ip string $neutronhost" >> /tmp/neutron-seed.txt

debconf-set-selections /tmp/neutron-seed.txt

echo "nova-common nova/admin-password password $keystoneadminpass" > /tmp/nova-seed.txt
echo "nova-common nova/configure_db boolean false" >> /tmp/nova-seed.txt
echo "nova-consoleproxy nova-consoleproxy/daemon_type select spicehtml5" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit-host string 127.0.0.1" >> /tmp/nova-seed.txt
echo "nova-api nova/register-endpoint boolean false" >> /tmp/nova-seed.txt
echo "nova-common nova/my-ip string $novahost" >> /tmp/nova-seed.txt
echo "nova-common nova/start_services boolean false" >> /tmp/nova-seed.txt
echo "nova-common nova/admin-user string $keystoneadminuser" >> /tmp/nova-seed.txt
echo "nova-api nova/region-name string $endpointsregion" >> /tmp/nova-seed.txt
echo "nova-common nova/admin-tenant-name string $keystoneadmintenant" >> /tmp/nova-seed.txt
echo "nova-api nova/endpoint-ip string $novahost" >> /tmp/nova-seed.txt
echo "nova-api nova/keystone-ip string $keystonehost" >> /tmp/nova-seed.txt
echo "nova-common nova/active-api multiselect ec2, osapi_compute, metadata" >> /tmp/nova-seed.txt
echo "nova-common nova/auth-host string $keystonehost" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_host string $messagebrokerhost" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_password password $brokerpass" >> /tmp/nova-seed.txt
echo "nova-common nova/rabbit_userid string $brokeruser" >> /tmp/nova-seed.txt
echo "nova-common nova/neutron_url string http://$neutronhost:9696" >> /tmp/nova-seed.txt
echo "nova-common nova/neutron_admin_password password $neutronpass" >> /tmp/nova-seed.txt

debconf-set-selections /tmp/nova-seed.txt


# Verificamos si este servidor va a poder soportar KVM - Si no, mas adelante
# configuraremos NOVA para usar qemu en lugar de kvm
# Si esta variable da cero, habrá que configurar la máquina para QEMU.
kvm_possible=`grep -E 'svm|vmx' /proc/cpuinfo|uniq|wc -l`

if [ $kvm_possible == "0" ]
then
	nova_kvm_or_qemu="nova-compute-qemu"
else
	nova_kvm_or_qemu="nova-compute-kvm"
fi

case $consoleflavor in
"spice")
	consolepackage="nova-spiceproxy"
	consolesvc="nova-spiceproxy"
	;;
"vnc")
	consolepackage="nova-novncproxy"
	consolesvc="nova-novncproxy"
	;;
esac

if [ $nova_in_compute_node = "no" ]
then
	aptitude -y install $nova_kvm_or_qemu \
		nova-api \
		nova-cert \
		nova-common \
		nova-compute \
		nova-conductor \
		nova-console \
		nova-consoleauth \
		nova-doc \
		nova-scheduler \
		nova-volume \
		$consolepackage \
		python-novaclient \
		liblapack3gf \
		python-gtk-vnc \
		novnc
else
	aptitude -y install $nova_kvm_or_qemu
fi

echo "Listo"
echo ""

stop nova-api
stop nova-api
stop nova-cert
stop nova-cert
stop nova-scheduler
stop nova-scheduler
stop nova-conductor
stop nova-conductor
stop nova-console
stop nova-console
stop nova-consoleauth
stop nova-consoleauth
stop $consolesvc
stop $consolesvc
stop nova-compute
stop nova-compute

source $keystone_admin_rc_file

rm -f /tmp/nova-seed.txt
rm -f /tmp/neutron-seed.txt
rm -f /tmp/cinder-seed.txt
rm -f /tmp/glance-seed.txt
rm -f /tmp/keystone-seed.txt

echo ""
echo "Aplicando Reglas de IPTABLES"

iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6080 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6081 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6082 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 5900:5999 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 8773,8774,8775 -j ACCEPT
/etc/init.d/iptables-persistent save
echo ""
echo "Listo"
echo ""

echo "Configurando NOVA"

if [ $nova_in_compute_node = "no" ]
then
        crudini --set /etc/nova/api-paste.ini filter:authtoken paste.filter_factory "keystoneclient.middleware.auth_token:filter_factory"
        crudini --set /etc/nova/api-paste.ini filter:authtoken auth_protocol http
        crudini --set /etc/nova/api-paste.ini filter:authtoken auth_host $keystonehost
        crudini --set /etc/nova/api-paste.ini filter:authtoken admin_tenant_name $keystoneservicestenant
        crudini --set /etc/nova/api-paste.ini filter:authtoken auth_port 35357
        crudini --set /etc/nova/api-paste.ini filter:authtoken admin_password $novapass
        crudini --set /etc/nova/api-paste.ini filter:authtoken admin_user $novauser
        crudini --set /etc/nova/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000/
fi

crudini --set /etc/nova/nova.conf keystone_authtoken auth_host $keystonehost
crudini --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user $novauser
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password $novapass
crudini --set /etc/nova/nova.conf keystone_authtoken signing_dir /tmp/keystone-signing-nova
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$keystonehost:5000/

#
# Configuración principal
#

crudini --set /etc/nova/nova.conf DEFAULT notification_driver nova.openstack.common.notifier.rpc_notifier
if [ $ceilometerinstall == "yes" ]
then
	crudini --set /etc/nova/nova.conf DEFAULT notification_driver ceilometer.compute.nova_notifier
	case $brokerflavor in
	"qpid")
		sed -r -i 's/ceilometer.compute.nova_notifier/ceilometer.compute.nova_notifier\nnotification_driver\ =\ nova.openstack.common.notifier.rpc_notifier/' /etc/nova/nova.conf
		;;
	"rabbitmq")
		sed -r -i 's/ceilometer.compute.nova_notifier/ceilometer.compute.nova_notifier\nnotification_driver\ =\ nova.openstack.common.notifier.rpc_notifier/' /etc/nova/nova.conf
		;;
	esac
	crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
	crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
	crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
fi
crudini --set /etc/nova/nova.conf DEFAULT use_forwarded_for False
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
crudini --set /etc/nova/nova.conf DEFAULT logdir /var/log/nova
crudini --set /etc/nova/nova.conf DEFAULT state_path /var/lib/nova
crudini --set /etc/nova/nova.conf DEFAULT lock_path /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf DEFAULT volumes_dir /etc/nova/volumes
crudini --set /etc/nova/nova.conf DEFAULT dhcpbridge /usr/bin/nova-dhcpbridge
crudini --set /etc/nova/nova.conf DEFAULT dhcpbridge_flagfile /etc/nova/nova.conf
crudini --set /etc/nova/nova.conf DEFAULT force_dhcp_release True
crudini --set /etc/nova/nova.conf DEFAULT injected_network_template /usr/share/nova/interfaces.template
crudini --set /etc/nova/nova.conf DEFAULT libvirt_nonblocking True
crudini --set /etc/nova/nova.conf DEFAULT libvirt_inject_partition -1
crudini --set /etc/nova/nova.conf DEFAULT network_manager nova.network.manager.FlatDHCPManager
crudini --set /etc/nova/nova.conf DEFAULT iscsi_helper tgtadm
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_timeout 10
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal False
crudini --set /etc/nova/nova.conf DEFAULT control_exchange nova
crudini --set /etc/nova/nova.conf DEFAULT host `hostname`

#
# Base de datos
#

case $dbflavor in
"mysql")
	crudini --set /etc/nova/nova.conf database connection mysql://$novadbuser:$novadbpass@$dbbackendhost:$mysqldbport/$novadbname
	;;
"postgres")
	crudini --set /etc/nova/nova.conf database connection postgresql://$novadbuser:$novadbpass@$dbbackendhost:$psqldbport/$novadbname
	;;
esac


#
# Sigue configuración principal
#

osapiworkers=`grep processor.\*: /proc/cpuinfo |wc -l`
 
crudini --set /etc/nova/nova.conf DEFAULT compute_driver libvirt.LibvirtDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT rootwrap_config /etc/nova/rootwrap.conf
crudini --set /etc/nova/nova.conf DEFAULT osapi_volume_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf DEFAULT verbose False
crudini --set /etc/nova/nova.conf DEFAULT ec2_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT service_down_time 60
crudini --set /etc/nova/nova.conf DEFAULT image_service nova.image.glance.GlanceImageService
crudini --set /etc/nova/nova.conf DEFAULT libvirt_use_virtio_for_bridges True
crudini --set /etc/nova/nova.conf DEFAULT osapi_compute_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret $metadata_shared_secret
crudini --set /etc/nova/nova.conf DEFAULT metadata_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT osapi_compute_workers $osapiworkers
# crudini --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
crudini --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver
crudini --set /etc/nova/nova.conf DEFAULT neutron_region_name $endpointsregion
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT debug False
crudini --set /etc/nova/nova.conf DEFAULT my_ip $nova_computehost
crudini --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
crudini --set /etc/nova/nova.conf DEFAULT neutron_admin_password $neutronpass
crudini --set /etc/nova/nova.conf DEFAULT api_paste_config /etc/nova/api-paste.ini
crudini --set /etc/nova/nova.conf DEFAULT glance_api_servers $glancehost:9292
crudini --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name $keystoneservicestenant
crudini --set /etc/nova/nova.conf DEFAULT metadata_host $novahost
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url "http://$keystonehost:35357/v2.0"
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis "ec2,osapi_compute,metadata"
crudini --set /etc/nova/nova.conf DEFAULT neutron_admin_username $neutronuser
crudini --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy True
crudini --set /etc/nova/nova.conf DEFAULT volume_api_class nova.volume.cinder.API
crudini --set /etc/nova/nova.conf DEFAULT neutron_url "http://$neutronhost:9696"
crudini --set /etc/nova/nova.conf DEFAULT libvirt_type kvm
crudini --set /etc/nova/nova.conf DEFAULT instance_name_template $instance_name_template
crudini --set /etc/nova/nova.conf DEFAULT start_guests_on_host_boot $start_guests_on_host_boot
crudini --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot $resume_guests_state_on_host_boot
crudini --set /etc/nova/nova.conf DEFAULT instance_name_template $instance_name_template
crudini --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host $allow_resize_to_same_host
# crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio $ram_allocation_ratio
crudini --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio $cpu_allocation_ratio
crudini --set /etc/nova/nova.conf DEFAULT connection_type libvirt
# crudini --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
# crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $novahost
# crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url "http://$vncserver_controller_address:6080/vnc_auto.html"
crudini --set /etc/nova/nova.conf DEFAULT scheduler_default_filters "RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,CoreFilter"
# crudini --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
# crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen $novahost
# crudini --set /etc/nova/nova.conf DEFAULT vnc_keymap $vnc_keymap
crudini --set /etc/nova/nova.conf DEFAULT force_config_drive true
crudini --set /etc/nova/nova.conf DEFAULT config_drive_format iso9660
crudini --set /etc/nova/nova.conf DEFAULT config_drive_cdrom true
crudini --set /etc/nova/nova.conf DEFAULT config_drive_inject_password True
crudini --set /etc/nova/nova.conf DEFAULT mkisofs_cmd genisoimage
crudini --set /etc/nova/nova.conf DEFAULT dhcp_domain $dhcp_domain
crudini --set /etc/nova/nova.conf DEFAULT neutron_default_tenant_id default
 
# Mas opciones nuevas para Nova
# Algunas ya no están en Icehouse
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_ovs_integration_bridge $integration_bridge
# crudini --set /etc/nova/nova.conf DEFAULT libvirt_ovs_bridge $integration_bridge
crudini --set /etc/nova/nova.conf DEFAULT neutron_ovs_bridge $integration_bridge
# crudini --set /etc/nova/nova.conf DEFAULT dhcp_options_enabled True

case $consoleflavor in
"vnc")
	crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
	crudini --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
	crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $novahost
	crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url "http://$vncserver_controller_address:6080/vnc_auto.html"
	crudini --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
	crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen $novahost
	crudini --set /etc/nova/nova.conf DEFAULT vnc_keymap $vnc_keymap
	crudini --del /etc/nova/nova.conf spice html5proxy_base_url
	crudini --del /etc/nova/nova.conf spice server_listen
	crudini --del /etc/nova/nova.conf spice server_proxyclient_address
	crudini --del /etc/nova/nova.conf spice keymap
        crudini --set /etc/nova/nova.conf spice agent_enabled False
        crudini --set /etc/nova/nova.conf spice enabled False
	;;
"spice")
	crudini --del /etc/nova/nova.conf DEFAULT novncproxy_host
	crudini --del /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address
	crudini --del /etc/nova/nova.conf DEFAULT novncproxy_base_url
	crudini --del /etc/nova/nova.conf DEFAULT novncproxy_port
	crudini --del /etc/nova/nova.conf DEFAULT vncserver_listen
	crudini --del /etc/nova/nova.conf DEFAULT vnc_keymap

	crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled False
	crudini --set /etc/nova/nova.conf DEFAULT novnc_enabled False

	crudini --set /etc/nova/nova.conf spice html5proxy_base_url "http://$spiceserver_controller_address:6082/spice_auto.html"
	crudini --set /etc/nova/nova.conf spice server_listen 0.0.0.0
	crudini --set /etc/nova/nova.conf spice server_proxyclient_address $novahost
	crudini --set /etc/nova/nova.conf spice enabled True
	crudini --set /etc/nova/nova.conf spice agent_enabled True
	crudini --set /etc/nova/nova.conf spice keymap en-us
	;;
esac 

case $brokerflavor in
"qpid")
	crudini --set /etc/nova/nova.conf DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid
	crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect_interval_min 0
	crudini --set /etc/nova/nova.conf DEFAULT qpid_username $brokeruser
	crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect True
	crudini --set /etc/nova/nova.conf DEFAULT qpid_tcp_nodelay True
	crudini --set /etc/nova/nova.conf DEFAULT qpid_protocol tcp
	crudini --set /etc/nova/nova.conf DEFAULT qpid_hostname $messagebrokerhost
	crudini --set /etc/nova/nova.conf DEFAULT qpid_password $brokerpass
	crudini --set /etc/nova/nova.conf DEFAULT qpid_port 5672
	# crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect_limit 0
	# crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect_interval 0
	# crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect_timeout 0
	crudini --set /etc/nova/nova.conf DEFAULT qpid_heartbeat 60
	# crudini --set /etc/nova/nova.conf DEFAULT qpid_reconnect_interval_max 0
	;;
 
"rabbitmq")
	crudini --set /etc/nova/nova.conf DEFAULT rpc_backend nova.openstack.common.rpc.impl_kombu
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_host $messagebrokerhost
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_userid $brokeruser
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_password $brokerpass
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_port 5672
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_use_ssl false
	crudini --set /etc/nova/nova.conf DEFAULT rabbit_virtual_host $brokervhost
	;;
esac


sync
sleep 5
sync


sed -r -i 's/NOVA_ENABLE\=false/NOVA_ENABLE\=true/' /etc/default/nova-common

sync
sleep 5
sync

if [ $kvm_possible == "0" ]
then
	echo ""
	echo "ALERTA !!! - Este servidor NO SOPORTA KVM - Se reconfigurará NOVA"
	echo "para usar virtualización por software vía QEMU"
	echo "El rendimiento será pobre"
	echo ""
	source $keystone_admin_rc_file
	crudini --set /etc/nova/nova.conf DEFAULT libvirt_type qemu
	echo ""
else
	crudini --set /etc/nova/nova.conf DEFAULT libvirt_cpu_mode $libvirt_cpu_mode
fi

sync
sleep 5
sync

rm -f /var/lib/nova/nova.sqlite

if [ $nova_in_compute_node = "no" ]
then
	su nova -s /bin/sh -c "nova-manage db sync"
fi

sync
sleep 5
sync

echo "Listo"

echo "Activando Servicios de Nova"

if [ $nova_in_compute_node = "no" ]
then
	start nova-api
	start nova-cert
	start nova-scheduler
	start nova-conductor
	start nova-console
	start nova-consoleauth
	start $consolesvc

	if [ $nova_without_compute = "no" ]
	then
		start nova-compute
	else
		stop nova-compute
		echo 'manual' > /etc/init/nova-compute.override
	fi

	echo 'manual' > /etc/init/nova-xenvncproxy.override
else
	start nova-compute
fi

echo ""
echo "Listo"

echo ""
echo "Haciendo pausa de 10 segundos"
echo ""

sync
sleep 10
sync

/etc/init.d/iptables-persistent save

echo ""
echo "Continuando la instalación"
echo ""

if [ $nova_in_compute_node = "no" ]
then
	if [ $vm_default_access == "yes" ]
	then
		echo ""
		echo "Creando accesos de seguridad para las VM's"
		echo "Puertos: ssh e ICMP"
		echo ""
		source $keystone_admin_rc_file
		nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
		nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
		echo "Listo"
		echo ""
	fi

	for vmport in $vm_extra_ports_tcp
	do
		echo ""
		echo "Creando acceso de seguridad para el puerto $vmport tcp"
		source $keystone_admin_rc_file
		nova secgroup-add-rule default tcp $vmport $vmport 0.0.0.0/0
	done

	for vmport in $vm_extra_ports_udp
	do
		echo ""
		echo "Creando acceso de seguridad para el puerto $vmport udp"
		source $keystone_admin_rc_file
		nova secgroup-add-rule default udp $vmport $vmport 0.0.0.0/0
	done
fi

testnova=`dpkg -l nova-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testnova == "0" ]
then
	echo ""
	echo "Falló la instalación de nova - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/nova-installed
	date > /etc/openstack-control-script-config/nova
	echo "$consolesvc" > /etc/openstack-control-script-config/nova-console-svc
	if [ $nova_in_compute_node = "no" ]
	then
		date > /etc/openstack-control-script-config/nova-full-installed
	fi
	if [ $nova_without_compute = "yes" ]
	then
		if [ $nova_in_compute_node = "no" ]
		then
			date > /etc/openstack-control-script-config/nova-without-compute
		fi
	fi
fi

echo ""
echo "Nova Instalado y Configurado"
echo ""


