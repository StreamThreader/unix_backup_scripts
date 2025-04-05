#!/bin/sh

dote=`date +"%Y-%m-%d %H-%M " `
backuppath=/mnt/192.168.0.200
basemountdir=/mnt/new
rootdir=${basemountdir}"/root"
vardir=${basemountdir}"/var"
usrdir=${basemountdir}"/usr"
homedir=${basemountdir}"/home"

echo "Directory with backups: "$backuppath
echo "Target directory for root: "$rootdir
echo "Target directory for var: "$vardir
echo "Target directory for usr: "$usrdir
echo "Target directory for home: "$homedir
echo "Backup files:"
echo  `ls ${backuppath}/*root*`
echo  `ls ${backuppath}/*var*`
echo  `ls ${backuppath}/*usr*`
echo  `ls ${backuppath}/*home*`

echo "For proceed press Enter, or Ctrl+C for Exit"
read ii;

# Restory main partitions
echo 'Restory started'

echo 'Starting restory partition root'
    gzip -d -c  `ls ${backuppath}/*root*`  | ( cd ${rootdir} ; restore -rf - )
echo 'Finished restory partition root'
sleep 4

echo 'Starting restory partition /var'
    gzip -d -c  `ls ${backuppath}/*var*`  | ( cd ${vardir} ; restore -rf - )
echo 'Finished restory partition /var'
sleep 4

echo 'Starting restory partition /usr'
    gzip -d -c  `ls ${backuppath}/*usr*`  | ( cd ${usrdir} ; restore -rf - )
echo 'Finished restory partition /usr'
sleep 4

echo 'Starting restory partition /home'
    gzip -d -c  `ls ${backuppath}/*home*`  | ( cd ${homedir} ; restore -rf - )
echo 'Finished restory partition /home'
sleep 4

echo 'Restory finished'
