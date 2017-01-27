# remaster-mx16

## Prerequisites
* This remastering process requires an MX Linux or antiX Linux development environment.
* Git should be installed.

## Creating the Swift Linux ISO files:
Just enter the command "sh main.sh".

## SSH access to SourceForge
* Enter the following command:
```
ssh -t (USERNAME),swiftlinux@shell.sourceforge.net create
```
* Once in the SourceForge shell, cd to /home/frs/project/swiftlinux .

## Uploading to SourceForge
Enter the following command:
```
rsync -avP -e ssh (FILE) (USERNAME),swiftlinux@shell.sourceforge.net:/home/frs/project/swiftlinux
```

