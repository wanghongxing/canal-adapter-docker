#!/bin/bash
bash /data/canal/canal-adapter/bin/startup.sh

sleep 3

tail -f /data/canal/canal-adapter/logs/adapter/adapter.log