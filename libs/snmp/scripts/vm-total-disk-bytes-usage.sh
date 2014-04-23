#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script para monitoreo del uso de disco (bytes) de las VM's
# y de las imagenes de glance
#
# Primera variable: Cantidad de bytes usados por las instancias
# Segunda variable: Cantidad de bytes usados por las imagenes de glance
#


PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin

du -c --block-size=1 /var/lib/nova/instances/|tail -n 1|awk '{print $1}'
du -c --block-size=1 /var/lib/glance/images/|tail -n 1|awk '{print $1}'
