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

# Initializing variables
DATE=`date +%Y-%m-%d-%H%M-%S`
STARTPATH=$PWD
get_iso_path
set_host_path
