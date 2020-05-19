#!/bin/bash

save()
{
	read -p "set snopshot name(default ${1}-$(date +"%Y-%m-%d")):" ssname
	ssname=${ssname:-${1}-$(date +"%Y-%m-%d")}
	if [ ! -z "$(virsh snapshot-list ${1}|grep ${ssname})" ]; then
		echo "${ssname} snopshot has existed!!!Please remove it first!!!"
		exit 1
	fi
	echo "save ${1} snopshot ${ssname} ..."
	virsh snapshot-create-as --domain ${1} --name "${ssname}"
	echo "save ${1} snopshot ${ssname} sucess!"
}

listss()
{
	echo "snopshot:"
	virsh snapshot-list ${1}
}

restore()
{
	echo "snopshot:"
	
	virsh snapshot-list ${1}
	read -p "choice snopshot restore:" ssname
	if [ -z "${ssname}" ]; then
		echo "No snapshot select!!!"
		exit 1
	fi
	echo "restore snopshot ${ssname} ..."
	virsh snapshot-revert ${1} "${ssname}"
	echo "restore snopshot ${ssname} sucess!"
}

delete()
{
	echo "domain ${1} has snopshot:"
	virsh snapshot-list ${1}
	
	read -p "choice snopshot delete:" ss_names
	for ssname in ${ss_names} ; do
		echo "delete snopshot ${ssname} ..."
		virsh snapshot-delete --domain ${1} --snapshotname "${ssname}"
	done
}

if [ -z ${1} ]; then
	echo "domain name is must!!!"
	exit 1
fi

echo "snopshot mgr:"
echo "     s for save (default)"
echo "     r for restore"
echo "     d for delete"
echo "     l for list"
read -p "choice opt:" ss_opt
ss_opt=${ss_opt:-s}

case ${ss_opt} in
	s) save ${1}
	;;
	r) restore ${1}
	;;
	d) delete ${1}
	;;
	l) listss ${1}
	;;
	*)
	echo "unknow opt: ${ss_opt}"
	;;
esac
