#!/bin/bash
cd /home/container && eval $(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
