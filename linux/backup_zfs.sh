#!/usr/bin/bash

# For Linux Debian 12.10

version_script="1.0.1"
backuppath="/home/ftp/incoming/bpool"
zpoolname="bpool"
dote=`date +"%Y-%m-%d--%H-%M"`
fastcompress="false"
backsnapshotname=$dote"-backup_zfs_v$version_script"
info_file="$backuppath/$dote-00-$zpoolname-info.txt"
restory_script="$backuppath/$dote-00-$zpoolname-restory.sh"

# Custom skip example
excludedataset=("$zpoolname/ROOTTEST" "$zpoolname/tmp/shm")

dircheck () {
    if !(test -d $1); then
	echo "Directory ($1) not exist."
	echo "Create one? (yes)"

        read mstr;
        case ${mstr} in
	    [Yy][Ee][Ss]|[Yy]|"")
		mkdir -p $backuppath
		;;
	    *)
		return 1
    		;;
        esac
    fi
}

echo "Directory for store backup: $backuppath"
echo "You want change it? (no): "

read mstr;
case ${mstr} in
    [Yy][Ee][Ss]|[Yy])
	echo "Enter new path for store backup"
	read backuppath;

        if !(dircheck $backuppath ); then
	    echo "Directory not exist and not created, exit."
    	    exit
        fi
        ;;
esac

if !(dircheck $backuppath ); then
    echo "Directory not exist and not created, exit."
    exit
fi

if zpool list $zpoolname; then
    echo "ZFS pool "$zpoolname" found"
else
    echo "ZFS pool "$zpoolname" not found"
    echo "Please set correct zfs pool name and try again"
    exit
fi

###############################################################################

echo "Collecting info..."

echo "Script version: $version_script" > $info_file
echo "Started at: $dote" >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "hostname:" >> $info_file
hostname >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Linux Debian version: " >> $info_file
cat /etc/debian_version >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Architecture:" >> $info_file
uname -m >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "CPU:" >> $info_file
lscpu | sed -nr '/Model name/ s/.*:\s*(.*) @ .*/\1/p' >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "RAM:" >> $info_file
grep MemTotal /proc/meminfo >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Disk list" >> $info_file
lsblk >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

for disk_n in $(lsblk -l | grep disk| awk '{print $1}'); do
    echo "smart for disk: "$disk_n >> $info_file

    smartctl -a /dev/$disk_n >> $info_file

    echo "" >> $info_file
    echo "______________________________________________________" >> $info_file
done

echo "partitions" >> $info_file
fdisk -l >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "disk by id" >> $info_file
ls -l /dev/disk/by-id/| grep -v "part" | grep -v "total" | \
    awk '{print $9" "$10" "$11}' >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "disk by label" >> $info_file
ls -l /dev/disk/by-label/ | grep -v total | \
    awk '{print $9" "$10" "$11}' >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "disk by partlabel" >> $info_file
ls -l /dev/disk/by-partlabel/ | grep -v total | \
    awk '{print $9" "$10" "$11}'  >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "disk by partuuid" >> $info_file
ls -l /dev/disk/by-partuuid/ | grep -v total | \
    awk '{print $9" "$10" "$11}' >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "zpool list"  >> $info_file
zpool list -v >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "zpool status"  >> $info_file
zpool status -v >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "zfs list"  >> $info_file
zfs list -o name,used,refer,avail,reservation,quota,mountpoint >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "IP configuration" >> $info_file
ip a >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "route table" >> $info_file
ip r >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Process list" >> $info_file
ps ax >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Installed packages: " >> $info_file
apt list --installed >> $info_file

echo "" >> $info_file
echo "__________________________________________________________" >> $info_file

echo "Info saved to: "$info_file

###############################################################################

echo 'Backup started'

echo "creating recursive snapshots"
zfs snapshot -r $zpoolname@$backsnapshotname

echo "list of snapshots:"
list_of_snapshots="$(zfs list -r -o name -t snapshot $zpoolname | \
	grep $backsnapshotname)"

echo "$list_of_snapshots" | column -t -s "@"

echo "Press Ctrl+C to abort..."
for i in $(seq 10 -1 1); do
	sleep 1
	echo "$i"
done

# Generate restory script
echo "#!/usr/bin/bash" > "$restory_script"
echo "" >> "$restory_script"
echo "exit" >> "$restory_script"
echo "" >> "$restory_script"

echo "Starting zfs send..."
for targetsnapname in ${list_of_snapshots[@]}; do
    skipflag=0
    dtsetname=$(echo $targetsnapname | awk -F "@" '{print $1}')
    for i in ${excludedataset[*]}; do
	if [ "$dtsetname" == "$i" ]; then
	    skipflag=1
	    break
	fi
    done

    if [ $skipflag == 1 ]; then
	echo "Skip: $dtsetname"
	continue
    fi

    # replace slash to underscore
    taskname=$(echo $dtsetname | sed 's/\//_/g')

    echo ""
    echo "Starting backup: "$dtsetname
    echo "zfs send $targetsnapname"

    if [ $fastcompress == "true" ]; then
	echo "use fast compress method: gzip"
	zfs send -v $targetsnapname | \
	    nice gzip > $backuppath/$dote-$taskname.zfsend.gz

	echo "gzcat ./$dote-$taskname.zfsend.gz | zfs recv -v -F $dtsetname" \
	    >> "$restory_script"
    else
    	echo "use best compress method: xz"
	zfs send -v $targetsnapname | \
	    nice xz -T0 > $backuppath/$dote-$taskname.zfsend.xz

	echo "xzcat ./$dote-$taskname.zfsend.xz | zfs recv -v -F $dtsetname"\
	    >> "$restory_script"
    fi

    echo "Finish backup: "$taskname
done

echo ""
echo "Destroy temporary created snapshots"
zfs destroy -r $zpoolname@$backsnapshotname

echo 'Backup finished'
