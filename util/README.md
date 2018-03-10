### Make a image of a noresised SD-card
      dd bs=4M count=1536 of=basisimage.img if=/dev/mmcblk0 status=progress conv=fsync
