#!/bin/bash
bash /data/canal/canal-adapter/bin/startup.sh

sleep 3

tail -f logs/adapter/adapter.log