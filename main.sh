#!/bin/bash

SCRIPT_REMASTER='/usr/local/bin/remaster.sh'
SCRIPT_REMASTER_BACKUP='/usr/local/bin/remaster-orig.sh'

# Back up the original /usr/local/bin/remaster.sh
if [ -f "$SCRIPT_REMASTER_BACKUP" ]
then
	echo "$SCRIPT_REMASTER_BACKUP already exists."
else
	echo "Backing up $SCRIPT_REMASTER"
	sudo cp $SCRIPT_REMASTER $SCRIPT_REMASTER_BACKUP
fi

# Replace /usr/local/bin/remaster.sh with the modified version
sudo cp usr_local_bin/remaster.sh $SCRIPT_REMASTER

DATE_LOG=`date +%Y-%m-%d-%H%M-%S`
mkdir -p log
FILE_LOG=log/$DATE_LOG.txt
bash start_log_remaster.sh 2>&1 | tee $FILE_LOG
