###########################################
#config.sh name [${vVMName} ${vMemSize} ${vMemMaxSize} ${vDiskName} ${vIsoPath} ${vNetBridge} ${vIncMAC} ${incIP} ${osType}]
###########################################
#!/bin/sh
baseDir=$(cd $(dirname ${0});pwd)

dName=${1}
vMemSize=${2}
vMaxSize=${3}
vDiskFile=${4}
vIsoPath=${5}
vNetBridge=${6}
incMAC=${7:-DE:AD}
incIP=${8}
vVMOS=${9:-linux}

vDiskSize=
vDiskDir=
VNCPort=0

defDiskPath="/var/lib/libvirt/images/"
defXMLPath="/etc/libvirt/qemu/"
defIsoPath="/mnt/iso/CentOS-7-x86_64-DVD-1810.iso"
defNetBridge="br0"


##set domain name
while [ -z "${dName}" ]; do
	read -p "set domainName:" dName
done

##set memSize
if [ -z "${vMemSize}" ]; then
	read -p "set curMemSize(M default 2048):" vMemsize
	vMemsize=${vMemsize:-2048}
	echo "curMemSize=${curMemSize}"
	read "set MaxMemSize(M default=curMemSize):" vMaxSize
	vMaxSize=${vMaxSize:-${vMemsize}}
	echo "MemMaxSize=${vMaxSize}"
fi
let vMemsize*=1024
let vMaxSize*=1024
##create and set vm disk
if [ -z "${vDiskFile}" ]; then
	vDiskFile=""
	read -p "set VDisk Name(default ${dName}.disk):" vDiskFile
	vDiskFile=${vDiskFile:-${dName}.disk}

	read -p "set VDisk Size(default 20):" vDiskSize
	vDiskSize=${vDiskSize:-20}

	read -p "set vDisk Dir(default ${defDiskPath}):" vDiskDir
	vDiskDir=${vDiskDir:-${defDiskPath}}

	sh ./creVDisk.sh ${vDiskFile} ${vDiskSize} ${vDiskDir}
	vDiskFile=${vDiskDir}${vDiskFile}
fi
vDiskFile=${vDiskFile//\//\\\/}
##set iso path
if [ -z "${vIsoPath}" ]; then
	read -p "set IsoPath(default ${defIsoPath}):" vIsoPath
	vIsoPath=${vIsoPath:-${defIsoPath}}
fi
vIsoPath=${vIsoPath//\//\\\/}

##set vnc port
VNCPort=0
while [[ ${VNCPort} -gt 5999 || ${VNCPort} -le 5900 ]]; do
	read -p "set vnc listen port(5901~5999):" VNCPort
done

##set websock port
WSPort=0
while [[ ${WSPort} -gt 5799 || ${WSPort} -le 5700 ]]; do
	read -p "set noVnc websocket listen port(5701~5799):" WSPort
done

##set net bridge
if [ "${vNetBridge}-" == "-" ]; then
	read -p "set net bridge(default${defNetBridge}):" vNetBridge
	vNetBridge=${vNetBridge:-${defNetBridge}}
fi

##set mac address 
if [ ${incMAC}"" == "DE:AD" ]; then
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
		incMAC=`printf "%s:%02X" ${incMAC} ${addr}`
	done
	echo "get Mac Addr:${incMAC}"
fi

confFile="${defXMLPath}${dName}.xml"
if [ -f ${confFile} ]; then 
	read -p "config file has existed!move it?(y/n)" isbak
	if [ "${isbak:-y}" == "y" ]; then
		mv ${confFile} ${confFile}-$(date "+%Y%m%d-%H%M%S")-bak
	fi
fi

exFile="${baseDir}/config/${vVMOS}.xml"
if [ -f ${exFile} ]; then
	cp ${exFile} ${confFile}
else
	echo "base config file ${exFile} lost!!!Exit!!!"
	exit 1
fi

sed -i "s/vmDomainName/${dName}/g" ${confFile}
sed -i "s/vmCurMem/${vMemsize}/g" ${confFile}
sed -i "s/vmMaxMem/${vMaxSize}/g" ${confFile}
sed -i "s/vmIsoPath/${vIsoPath}/g" ${confFile}
sed -i "s/vmDiskPath/${vDiskFile}/g" ${confFile}
sed -i "s/VMIncBri/${vNetBridge}/g" ${confFile}
sed -i "s/VMIncMAC/${incMAC}/g" ${confFile}
sed -i "s/vmVNCPort/${VNCPort}/g" ${confFile}
sed -i "s/vmWSPort/${WSPort}/g" ${confFile}

echo "${dName},${vIsoPath},${incIP},${incMAC},${VNCPort},${WSPort}" >> ${baseDir}/vm-list.txt
