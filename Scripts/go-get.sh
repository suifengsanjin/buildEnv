#!/bin/bash
if [ -z ${1} ]; then
	echo "module is must!!!"
	exit 1
fi

GOBIN=$(which go 2>/dev/null)
if [ -z ${GOBIN} ]; then
	echo "Can not find go!Please install go first!"
	exit 1
fi

curdir=`pwd`

##export http_proxy=
##export https_proxy=

if [ -z ${GOPROXY} ]; then
	export GOPROXY="https://goproxy.io"
fi

if [ "no" == "${GO111MODULE}" ]; then
	export GO111MODULE="yes"
fi

if [ -z ${GOROOT} ]; then
	GOROOT=$(go env|grep GOROOT|awk -F '=' '{print substr($2,2,length($2) - 2)}')
fi

if [ -z ${GOPATH} ]; then
	GOPATH=$(go env|grep GOPATH|awk -F '=' '{print substr($2,2,length($2) - 2)}')
fi

cd ${GOROOT}/src
cp ${GOROOT}/src/go.mod ${GOROOT}/src/go.mod.bak
cp ${GOROOT}/src/go.sum ${GOROOT}/src/go.sum.bak

echo "go get -u ${1}"
go get -u ${1}
if [ $? -ne 0 ]; then
	echo "go-get ${1} failed!"
	rm -f ${GOROOT}/src/go.mod
	mv ${GOROOT}/src/go.mod.bak ${GOROOT}/src/go.mod
	exit 1
else
	echo "go-get ${1} sucess!"
fi

cat ${GOROOT}/src/go.mod |grep ${1%%/*}|awk '{print $1"@"$2}'
echo "----------------------------------------------------------------"
count=0
while [ ${count} -ne $(cat ${GOROOT}/src/go.mod|grep ${1%%/*}|wc -l) ]; do
	let count+=1
	info="$(cat ${GOROOT}/src/go.mod|grep ${1%%/*}|awk 'NR=='${count}'{print $0}')"
	if [ $(echo ${info} |grep ${1%%/*}|awk '{print $1}') == "require" ]; then
		file="$(echo ${info} |grep ${1%%/*}|awk '{print $2"@"$3}')"
	else
		file="$(echo ${info} |grep ${1%%/*}|awk '{print $1"@"$2}')"
	fi
	
	mkdir -p ${GOROOT}/src/${file%/*}
	echo "mv ${GOPATH}/pkg/mod/${file} ${GOROOT}/src/${file%@*}"
	mv ${GOPATH}/pkg/mod/${file} ${GOROOT}/src/${file%@*}
	##change access right for all user
	chmod -R 755 ${GOROOT}/src/${file%@*}
done

rm -rf ${GOROOT}/src/go.mod
mv ${GOROOT}/src/go.mod.bak ${GOROOT}/src/go.mod
rm -rf ${GOROOT}/src/go.sum
mv ${GOROOT}/src/go.sum.bak ${GOROOT}/src/go.sum

rm -rf ${GOPATH}/pkg
cd ${curdir}

