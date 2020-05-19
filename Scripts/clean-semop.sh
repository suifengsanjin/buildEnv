#!/bin/bash
ipcs -s
for semop in $(ipcs -s|grep 0x|awk '{print $2}') ; do
	echo "delete semop ${semop}"
	ipcrs -s ${semop}
done
