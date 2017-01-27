#!/bin/bash

# This script comes from the /usr/local/bin/remaster.sh in MX Linux.

# This script is used to create each edition of Swift Linux.

# Root check 
if [[ $UID != "0" ]]; then
	echo -e "You need to be root to execute this script.\n"
	exit 1
fi

# Sets the path to iso or cdrom
function get_iso_path {
	echo "If you have not already done so, please copy the MX Linux ISO into $PWD."
	echo "Press Enter to continue."
	read CONTINUE
	
	echo
	echo '-------------------'
	echo 'ls -d -1 $PWD/*.iso'
	ls -d -1 $PWD/*.iso
	echo '-----------------------------------------------------------------------------------------'
	echo "Enter the complete path to the MX Linux ISO on your hard disk (i.e. /path_to_iso/MX.iso):"
	read CD
	echo
	if [[ ! -e $CD ]]; then
		echo -e "Path or file doesn't exist, please try again \n" 
		get_iso_path
	fi
}

# Set working path where everything is copied
function set_host_path {
	HOSTPATH="$STARTPATH/remaster-$DATE"
	REM=$HOSTPATH
	echo "REM: $REM"
	mkdir -p $REM
}

# Mounts ISO named $1 to $REM/iso
function mount_iso {
	cd $STARTPATH
	mount -o loop $1 $REM/iso
	cd $REM
}

# Copy cdrom content (except squash file) from $1 to $2
function copy_iso {
	# Finds the biggest file in ISO, which is most likely the squash file
	SQUASH=$(find $1 -type f -printf "%s %p\n" | sort -rn | head -n1 | cut -d " " -f 2)
	SQUASH_REL=${SQUASH#$1/}
	rsync -a $1/ $2 --exclude=$SQUASH_REL
	wait
}

# Function mounts file $1 of type $2
function mount_compressed_fs { 
	echo "Mounting original squashfs to $REM/squashfs"
	mount -t $2 -o loop $1 squashfs
	if [[ $? -ne 0 ]]; then
		umount iso
		echo "Error mounting squashfs file. \"$1\" is probable not a $2 file."
		echo "Cleaning up, removing \"remaster\" directory.\n"
		cd ..
		rm -r remaster
		exit 4
	fi
	wait
}

function create_remaster_env {
	ABBREV="$1"
	EDITION="$2"
	echo '+++++++++++++++++++++++++++++++++++++++++++++++++'
	echo "BEGIN creating remastering environment ($EDITION)"
	echo '+++++++++++++++++++++++++++++++++++++++++++++++++'
	echo "Creating directory structure for this operation"
	mkdir $REM/iso $REM/squashfs $REM/$ABBREV-iso $REM/$ABBREV-squashfs
	echo "($REM/iso) directory to mount CD on"
	echo "($REM/squashfs) directory for old squashfs"
	echo "($REM/$ABBREV-squashfs) directory for $ABBREV squashfs"
	echo -e "($REM/$ABBREV-iso) directory for $ABBREV iso \n"
	echo -e "mounting original CD to $REM/iso"
	mount_iso $CD
	copy_iso iso $ABBREV-iso
	mount_compressed_fs $SQUASH squashfs
	echo -e "Copying mounted squashfs to $REM/$ABBREV-squashfs (takes some time) \n"
	cp -a squashfs/* $ABBREV-squashfs/
	umount squashfs
	umount iso
	rm -r squashfs
	rm -r iso
	echo '++++++++++++++++++++++++++++++++++++++++++++++++++++'
	echo "FINISHED creating remastering environment ($EDITION)"
	echo '++++++++++++++++++++++++++++++++++++++++++++++++++++'
}

function replace_text_in_file {
	TEXT1="$1"
	TEXT2="$2"
	FILE_TO_UPDATE="$3"
	ABBREV="$4"
	if [[ "$FILE_TO_UPDATE" =~ "$ABBREV-iso" ]]
	then
		chmod +w $FILE_TO_UPDATE
	fi
	sed -i "s|$TEXT1|$TEXT2|g" $FILE_TO_UPDATE
	if [[ "$FILE_TO_UPDATE" =~ "$ABBREV-iso" ]]
	then
		chmod -w $FILE_TO_UPDATE
	fi
}

function edit_swiftlinux {
	ABBREV="$1"
	EDITION="$2"

	echo '------------------------'
	echo "Editing the $EDITION ISO"

	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/version "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/grub/grub.cfg "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/grub/theme/theme.txt "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/isolinux/isolinux.cfg "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/isolinux/readme.msg "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/syslinux/readme.msg "$ABBREV"
	replace_text_in_file 'MX' "$EDITION" $ABBREV-iso/boot/syslinux/syslinux.cfg "$ABBREV"

	echo '-----------------------------'
	echo "Editing the $EDITION squashfs"
	
	# Set LightDM background
	cp $STARTPATH/usr_local_share_backgrounds_MX16_lightdm/$ABBREV.jpg $ABBREV-squashfs/usr/local/share/backgrounds/MX16/lightdm
	replace_text_in_file 'login.jpg' "$ABBREV.jpg" $ABBREV-squashfs/etc/lightdm/lightdm-gtk-greeter.conf "$ABBREV"

    # Set Xfce background
	cp $STARTPATH/usr_local_share_backgrounds_MX16_wallpaper/$ABBREV.jpg $ABBREV-squashfs/usr/local/share/backgrounds/MX16/wallpaper
	replace_text_in_file 'maine-sunrise.jpg' "$ABBREV.jpg" $ABBREV-squashfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml "$ABBREV"
}

# Set ISO path
function set_iso_path {
	ABBREV="$1"
	ISOPATH=$REM
	echo "ISOPATH: $ISOPATH"
}

function set_iso_name {
	ABBREV="$1"
	ISONAME="swiftlinux-$ABBREV.iso"
	ISONAME=$ISOPATH/$ISONAME
	echo "ISONAME: $ISONAME"
}

# Create $ABBREV linuxfs in the $ABBREV-iso
function make_squashfs {
	# $1: squashfs directory
	ABBREV="$2"
	echo '+++++++++++++++++++++++++++++++++++'
	echo "BEGIN make_squashfs in $1 ($ABBREV)"
	echo '+++++++++++++++++++++++++++++++++++'
	cd $REM
	echo -e "Good. We are now creating your iso. Sit back and relax, this takes some time (some 20 minutes on an AMD +2500 for a 680MB iso). \n"
	mksquashfs $1 $REM/$ABBREV-iso/antiX/linuxfs -comp xz
	if [[ $? -ne 0 ]]; then
		echo -e "Error making linuxfs file. Script aborted.\n" 
		exit 5
	fi
	echo '++++++++++++++++++++++++++++++++++++++'
	echo "FINISHED make_squashfs in $1 ($ABBREV)"
	echo '++++++++++++++++++++++++++++++++++++++'
}

# makes iso named $1 
function make_iso {
	# $1: $ISONAME
	cd $REM
	genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o $1 $REM/$ABBREV-iso && isohybrid $1 $REM/$ABBREV-iso
	if [[ $? -eq 0 ]]; then 
		echo
		echo "Done. You will find your very own remastered home-made Linux here: $1"
	else
		echo
		echo -e "ISO building failed.\n"
	fi
	cd $REM
}

# Builds squashfs from $1 folder and then makes the new ISO
function build { 
	# $1: squashfs directory
	EDITION="$2"
	ABBREV="$3"
	echo '***************************************'
	echo "BEGIN building $EDITION ($ABBREV) in $1"
	echo '***************************************'
	edit_swiftlinux "$ABBREV" "$EDITION"
	set_iso_path "$ABBREV"
	set_iso_name "$ABBREV"
	make_squashfs $1 $ABBREV
	make_iso $ISONAME
	echo '******************************************'
	echo "FINISHED building $EDITION ($ABBREV) in $1"
	echo '******************************************'
}

function build_edition {
	ABBREV="$1"
	EDITION="$2"
	create_remaster_env "$ABBREV" "$EDITION"
	build $ABBREV-squashfs "$EDITION" $ABBREV
}

# Initializing variables
DATE=`date +%Y-%m-%d-%H%M-%S`
STARTPATH=$PWD
get_iso_path
set_host_path
build_edition 'taylor_swift' 'Taylor Swift Linux'
build_edition 'ingress_enlightened' 'Ingress Enlightened Swift Linux'
build_edition 'ingress_resistance' 'Ingress Resistance Swift Linux'
chmod 777 $REM
