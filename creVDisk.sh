#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Input param lost!"
	echo "	ex:$0 vDiskName [vDiskSize] [vDiskDir]"
	echo "---------------------------"
	exit 1
fi

vDiskName=$1
vDiskSize=${2:-20}
vDiskDir=${3:-/var/lib/libvirt/images/}

vDiskFile=${vDiskDir}${vDiskName}

if [ -f ${vDiskFile} ]; then
	echo "vDiskFile [${vDiskFile}] existed!"
	links=`stat ${vDiskFile} |grep Links|awk -F : '{print $4}'`
	if [ $((links)) == 1 ]; then
		echo "[${vDiskFile}] is not used!Use this?(y:yes n:no r:recreate)"
		read iUse
		case ${iUse} in
			y) exit 1
			;;
			n) exit 0
			;;
			r) rm -f ${vDiskFile}
			;;
			*) exit 2
			;;
		esac
	else
		echo "[${vDiskFile}] is used!"
		exit 2
	fi
fi
qemu-img create -f qcow2 ${vDiskFile} ${vDiskSize}G
if [ $? -ne 0 ]; then
	echo "create virDisk ${virDiskName} Failed!"
	exit 1
else 
	stat ${vDiskFile}
	exit 0
fi

