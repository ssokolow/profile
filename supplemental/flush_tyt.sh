#/bin/bash
export FLASH=/media/16GB_Flash
devnode=$(grep "$FLASH" /proc/mounts | awk '{ print $1 }')

if [ -e "$FLASH" ]; then
	killall smplayer2
	rm -f "$FLASH"/*.{mp4,webm}
	exo-mount -de "$devnode"
	sudo -n /usr/pandora/scripts/op_usbhost.sh
	sudo -n /usr/pandora/scripts/op_cpuspeed.sh -n 600
	notify-send 'You may now remove the thumbdrive'

else
	sudo -n /usr/pandora/scripts/op_cpuspeed.sh -n 800
	sudo -n /usr/pandora/scripts/op_usbhost.sh
	/usr/bin/nohup /usr/pandora/scripts/pnd_run.sh -p "/media/OS_32GB/pandora/menu//smplayer2_r6.pnd" -e "smplayer2.sh" -b "smplayer2"
fi