#!/bin/sh

for X in /srv/inbound/outbound/FOR_* /srv/inbound/Stuff\ to\ Print; do
	find "$X" -ctime +30 -exec rm -rf {} \+ 2>&1 | grep -v 'No such file or directory'
done 