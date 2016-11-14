#!/bin/bash
# Change hostname and resize root partition on SD card
# Written by Dany Pinoy
strImgFile=$1

if [[ ! $(whoami) =~ "root" ]]; then
  echo ""
  echo "**********************************"
  echo "*** This should be run as root ***"
  echo "**********************************"
  echo ""
  exit
fi

if [[ -z $1 || -z $2 ]]; then
  echo "Usage: sh raspbian--hostname-resize.sh /dev/mmcblk0 RPIDanPin"
  exit
fi

if [[ ! -e $1 || ! $(file $1) =~ "block special" ]]; then
  echo "Error : Not a block device, or device doesn't exist"
  exit
fi

mount $1p2 /mnt/
sed -i "s/raspberrypi/$2/" /mnt/etc/samba/smb.conf
cat /mnt/etc/samba/smb.conf
sed -i "s/raspberrypi/$2/" /mnt/etc/hostname
cat /mnt/etc/hostname
umount /mnt/

# Get the starting offset of the root partition
PART_START=$(parted $1 -ms unit s p | grep "^2" | cut -f 2 -d: | sed 's/[^0-9]//g')
echo $PART_START
[ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
fdisk $1 <<EOF
p
d
$PART_NUM
n
p
2
$PART_START

p
w
EOF
e2fsck -f $1p2
resize2fs $1p2
