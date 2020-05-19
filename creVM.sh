#!/bin/sh
###############################################################
#if use in a new machine,please reset iso path and bridge inc
##############################################################

defIsoPath="/mnt/iso/CentOS-7-x86_64-DVD-1810.iso"
defIsoPathWin32="/mnt/iso/en_windows_7_enterprise_with_sp1_x64_dvd_u_677651.iso"
defNetBridge="br0"
defDiskDir="/var/lib/libvirt/images/"
defConfDir="/etc/libvirt/qemu/"
defVMOS="linux"
baseDir=`pwd`

vDiskDir=
vDiskName=
vDiskSize=
vIsoPath=

vVMOS=
vVMName=
vMemSize=2048
vMemMaxSize=2048
vCpuSocks=1
vCpuSets=

vNetBridge=
vIncMAC="DE:AD"

setMem()
{
	read -p "set curMemSize(M default 2048):" vMemSize
	vMemSize=${vMemSize:-2048}
	echo "curMemSize=${vMemSize}"
	read -p "set MaxMemSize(M default=curMemSize):" vMemMaxSize
	vMemMaxSize=${vMemMaxSize:-${vMemSize}}
	echo "MemMaxSize=${vMemMaxSize}"
}

setCpu()
{
	read -p "set cpus(default 1):" vCpuSocks
	vCpuSocks=${vCpuSocks:-1}
	echo "cpus=${vCpuSocks}"
	echo "set cpu-set:"
	read -pvCpuSets
	echo "cpu-set=${vCpuSets}"
}

create_vOS()
{
	echo "---------------------OS----------------------"
	read -p "set OS Type(win32 or linux default linux):" vVMOS
	vVMOS=${vVMOS:-${defVMOS}}
	read -p "set VM name:" vVMName
	if [ "${vVMName}-" == "-" ]; then
		echo "VMName is NULL!"
		exit 1
	fi
	read -p "set mem and cpus(y/n):" mcMode
	mcMode=${mcMode:-n}
	if [ ${mcMode}"" == "y" ]; then
		setMem
		##setCpu
	else
		echo "default CpuSocks=${vCpuSocks} MemSize=${vMemSize}M MaxMemSize=${vMemMaxSize}M"
	fi
}

create_vDisk()
{
	echo "---------------------DISK----------------------"
	echo "create VDisk Info!"
	read -p "set vDiskDir(default ${defDiskDir}):" vDiskDir
	vDiskDir=${vDiskDir:-${defDiskDir}}
	echo "DiskDir=${vDiskDir}"
	read -p "set vDiskSize(G):" vDiskSize
	vDiskSize=${vDiskSize:-20}
	echo "DiskSize=${vDiskSize}G"
	read -p "set vDiskName(default ${vVMName}.disk):" vDiskName
	vDiskName=${vDiskName:-${vVMName}.disk}
	sh ${baseDir}/creVDisk.sh ${vDiskName} ${vDiskSize} ${vDiskDir}
	if [ $? -eq 2 ]; then
		echo "create DiskFile Failed!Please reset vDiskName:"
	fi

	vDiskName=${vDiskDir}${vDiskName}

	read -p "set iso path(default ${defIsoPath}):" vIsoPath
	if [ "${vVMOS}-" == "win32-" ]; then
		vIsoPath=${vIsoPath:-${defIsoPathWin32}}
	else
		vIsoPath=${vIsoPath:-${defIsoPath}}
	fi
}

create_vNet()
{
	echo "---------------------NET----------------------"
	read -p "set net bridge(default${netBridge}):" vNetBridge
	vNetBridge=${vNetBridge:-${defNetBridge}}

	##set mac address 
	while [ -z "${incIP}" ]; do
		read -p "set mac address by IP:" incIP
	done

	##replace ${str//srcstr/replace}
	ipArr=(${incIP//./ })
	if [ ${#ipArr[@]} -ne 4 ]; then
		echo "Error IP:${incIP}"
		exit 1
	fi

	for addr in ${ipArr[*]}; do
		if [[ ${addr} -gt 255 || ${addr} -lt 0 ]]; then
			echo "Error IP:${incIP}"
			exit 1
		fi
		vIncMAC=`printf "%s:%02X" ${vIncMAC} ${addr}`
	done
	echo "get Mac Addr:${vIncMAC}"
}

clean()
{
	if [ "" != "${virOSName}" ]; then
		pid=`ps -ef|grep ${virOSName}|grep -v grep|awk '{print $2}'`
		echo "${pid}"
		if [ "${pid}" != "" ]; then
			echo "Stop Pro :${pid}"
			ps -ef|grep ${pid}|grep -v grep
			kill ${pid}
		fi
		virsh undefine ${virOSName}
	fi
	if [[ "" != "${virDiskName}" && -f ${virDiskName} ]]; then
			read -p "Del diskFile:${virDiskName}(y:yes n:no)" isDel
			if [ ${isDel}"" == "y" ]; then
				echo "rm -f ${virDiskName}"
				rm -f ${virDiskName}
			fi
	fi
	exit 0
}

createVMByConfig()
{
	sh config.sh ${vVMName} ${vMemSize} ${vMemMaxSize} ${vDiskName} ${vIsoPath} ${vNetBridge} ${vIncMAC} ${incIP} ${vVMOS}
	if [ $? -ne 0 ]; then
		clean
		exit 1
	fi
	virsh define ${vConfigDir:-${defConfDir}}${vVMName}.xml
	virsh start ${vVMName}
	echo "VM started!Pleas connect by VNC and do next!"
}

echo "##########################################################################"
echo "this shell is used to help create VM by kvm-qemu"
echo "#create by lh @ 20190828"
echo "#note:"
echo "create by xml config"
echo "##########################################################################"

##sigal 
trap clean 2 3 15
if [[ ""${defNetBridge} == "" || ${defIsoPath}"" == "" ]]; then
	echo "defNetBridge or defIsoPath is NULL!Please modify this shell!!!"
	echo "defNetBridge=${defNetBridge}"
	echo "defIsoPath=${defIsoPath}"
	exit 1
fi

create_vOS
create_vDisk
create_vNet
createVMByConfig

if [ $? -ne 0 ]; then
	clean
fi
