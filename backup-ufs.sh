#!/bin/sh

###########################################################################
#             Version 1.0.4   2012-03-01                                  #
#                                                                         #
###########################################################################


dote=`date +"%Y-%m-%d--%H-%M" `
backuppath="/backup/2012-03-01"

dircheck ()
{
	if !(test -d $1); then
		echo "Target folder not exist ($1)."
		echo "Create directory? (yes)"
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

echo "Target directory:" $backuppath
echo "Do you want change it? (no): "
read mstr;

case ${mstr} in
        [Yy][Ee][Ss]|[Yy])
		echo "Enter desired target directory"
		read backuppath;
		if !(dircheck $backuppath ); then
		    echo "Directory not not exist and not created, Exit"
		    exit
		fi
;;
esac

if !(dircheck $backuppath ); then
    echo "Directory not not exist and not created, Exit"
    exit
fi

# backup main partitions, excluded home
echo 'Начал резервное копирование'

echo 'Starting backup root partition'
dump -0 -L -f - / | gzip -9  | pv >  ${backuppath}/${dote}-root.img.gz
echo 'Finished backup root partition'
sleep 4

echo 'Starting backup partition /var'
dump -0 -L -f - /var | gzip -9 | pv  >  ${backuppath}/${dote}-var.img.gz
echo 'Finished backup partition /var'
sleep 4

echo 'Starting backup partition /var /usr'
dump -0 -L -f - /usr | gzip -9  | pv >  ${backuppath}/${dote}-usr.img.gz
echo 'Finished backup partition /usr'
sleep 4

echo 'Starting backup partition /var /home'
dump -0 -L -f - /home | gzip -9  | pv >  ${backuppath}/${dote}-home.img.gz
echo 'Finished backup partition /home'
sleep 4

echo 'Backup complited'
