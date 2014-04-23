#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS/DEBIAN
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Script para aprovisionamiento de MetaData
# Solo para ser ejecutado en las VM's
#
# Incluya este script en el rc.local de sus VM's
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
#
# Definimos algunas variables necesarias
#
metadatadrivelabel="config-2"
metadatadrivemount="/mnt/config-2"
metadatafile="/mnt/config-2/openstack/latest/meta_data.json"
metadatatext="/var/tmp/lattest-metadata.txt"
runoncecontrolfile="/etc/metadata-provision-already-ran.conf"


#
# Este script deberia correr una sola vez. Por lo tanto, al finalizar
# si la ejecucion fue exitosa, el deja un archivo de control definido
# mas arriba en la variable "runoncecontrolfile".
# Si este archivo es encontrado, se aborta la ejecucion
#

if [ -f $runoncecontrolfile ]
then
	echo ""
	echo "Este script ya fue ejecutado"
	echo ""
	exit 0
fi


#
# Creamos el directorio para la metadata
#

mkdir -p $metadatadrivemount > /dev/null 2>&1

#
# Intentamos montar el drive
#

mount LABEL=$metadatadrivelabel $metadatadrivemount > /dev/null 2>&1

#
# Verificamos que exista el archivo de metadata y si no abortamos
#

if [ -f $metadatafile ]
then
	echo ""
	echo "Extrayendo metadata desde archivo $metadatafile"
	cat $metadatafile |sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' > $metadatatext
else
	echo ""
	echo "Archivo de metadata no disponible. Abortando."
	echo ""
	exit 0
fi

#
# Si logramos obtener la metadata y colocarla en un archivo plano de texto
# ahora procedemos a obtener el password administrativo y el key
#

adminpass=`grep "admin_pass" $metadatatext|cut -d: -f2|cut -d\" -f2`
passexist=`grep "admin_pass" $metadatatext|cut -d: -f2|cut -d\" -f2|wc -l`
sshrootkey=`grep "public_keys" $metadatatext|cut -d: -f3|cut -d\" -f2`
keyexist=`grep "public_keys" $metadatatext|cut -d: -f3|cut -d\" -f2 |wc -l`

if [ $passexist == 1 ]
then
	echo ""
	echo "Password exitosamente obtenido desde la metadata. Aprovisionando.."
	echo "root:$adminpass"|chpasswd
	echo "Listo !"
	echo ""
else
	echo ""
	echo "No se pudo obtener el password desde la metadata"
	echo ""
fi

if [ $keyexist == 1 ]
then
	echo ""
	echo "Key SSH exitosamente obtenido desde la metadata. Aprovisionando.."
	mkdir -p /root/.ssh > /dev/null 2>&1
	echo "$sshrootkey" >> /root/.ssh/authorized_keys
	chmod 0440 /root/.ssh/authorized_keys
	echo ""
else
	echo ""
	echo "No se pudo obtener el Key SSH desde la metadata"
	echo ""
fi

#
# Creamos el script de control para asegurarnos de no volver a correr
#
echo "THE WORLD IS TWISTED BUT ALL IS OK !!" > $runoncecontrolfile
# jejeje
#

# echo $*

#
# Hacemos limpieza
#

cd /
umount $metadatadrivemount > /dev/null 2>&1
rmdir $metadatadrivemount

#
#

echo ""
echo "Tarea finalizada"
echo ""
