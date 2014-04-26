#!/bin/bash
#
# Instalador desatendido para Openstack sobre UBUNTU
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Abril del 2014
#
# Script para monitoreo del porcentaje de uso de CPU
# y memora de las VM's y la memoria asignada a las VM's
# La primera variable es el % de uso de CPU
# La segunda variable es el % de uso de la memoria real
# La tercera variable es la cantidad de bytes asignados a las VM's
# (ram)
#


PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin

memzero=`ps --user libvirt-qemu u|awk '{print $4}'|grep -c -i -v "MEM"`

memqemu="0"

# tail -n 1 /workdir/file.csv |cut -d, -f14
# virt-top -1 -d 1 -b -n 4i --script --no-csv-mem --no-csv-block --no-csv-net --csv /workdir/file.csv

csvfilename=`openssl rand -hex 10`

if [ -f /usr/bin/virt-top ]
then
	# virt-top -1 -d 1 -b -n 4 --script --no-csv-mem --no-csv-block --no-csv-net --csv /tmp/$csvfilename.csv 2>/dev/null
	virt-top -d 1 -b -n 4 --script --no-csv-mem --no-csv-block --no-csv-net --csv /tmp/$csvfilename.csv 2>/dev/null
	# qemucpu=`tail -n 1 /tmp/$csvfilename.csv |cut -d, -f14`
	# assignedkb=`tail -n 1 /tmp/$csvfilename.csv |cut -d, -f16`
	cat /tmp/$csvfilename.csv |grep -v "%CPU"|cut -d, -f22 > /tmp/$csvfilename-cpu.txt
	cat /tmp/$csvfilename.csv |grep -v "%CPU"|cut -d, -f16 > /tmp/$csvfilename-ram.txt
	qemucpu="0"
	assignedkb="0"
	for CPU in `/bin/cat /tmp/$csvfilename-cpu.txt`
	do
		qemucpu=`echo "$CPU+$qemucpu"|bc`
	done
	for ASRAM in `/bin/cat /tmp/$csvfilename-ram.txt`
	do
		assignedkb=`echo "$ASRAM+$assignedkb/10"|bc`
	done
	assignedvmbytes=`echo $assignedkb*1024|bc`
	rm -f /tmp/$csvfilename.csv
	rm -f /tmp/$csvfilename-ram.txt
	rm -f /tmp/$csvfilename-cpu.txt
else
	qemucpu="0"
	assignedvmbytes="0"
fi



case $memzero in
0)
        memqemu="0"
        ;;
*)
        listqemus=`ps --user libvirt-qemu u|awk '{print $4}'|grep -i -v "MEM"`
        for i in $listqemus
        do
                # echo $i
                memqemu=`echo $memqemu+$i|bc`

        done
        ;;
esac

echo $qemucpu
echo $memqemu
echo $assignedvmbytes
