#!/bin/bash

for X in /srv/inbound/FOR_{ANDRE,MOM,NICK} /srv/inbound/Stuff\ to\ Print; do
	find "$X" -ctime +30 -exec echo rm -rf {} \+ 2>&1 | grep -v 'No such file or directory'
done
