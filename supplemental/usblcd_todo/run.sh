#!/bin/sh
cd "$(dirname "$0")"
#./todo_list.py /home/ssokolow/Desktop/TODO_TODAY.txt "$@" 2>&1 | tee -a /tmp/todo_list.log &
while true; do
    pipenv run ./general_info.py
    sleep 1
done
