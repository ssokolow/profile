#/bin/bash
FLASH=/media/16GB_Flash
devnode=$(grep /media/16 /proc/mounts | awk '{ print $1 }')

if [ -e "$FLASH" ]; then
	killall smplayer2
	rm -f "$FLASH"/*.{mp4,webm}
	exo-mount -de "$devnode"
	/usr/pandora/scripts/pnd_run.sh -p "/usr/pandora/apps//op_usbhost.pnd" -e "op_usbhost.sh" -b "op_usbhost"
	notify-send 'You may now remove the thumbdrive'
else
	/usr/pandora/scripts/pnd_run.sh -p "/usr/pandora/apps//op_usbhost.pnd" -e "op_usbhost.sh" -b "op_usbhost"
	/usr/bin/nohup /usr/pandora/scripts/pnd_run.sh -p "/media/OS_32GB/pandora/menu//smplayer2_r6.pnd" -e "smplayer2.sh" -b "smplayer2"
fi