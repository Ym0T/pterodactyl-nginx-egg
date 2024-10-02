#!/bin/bash

# [Git] Check if Git is installed and pull the latest changes in the 'www' folder
if command -v git > /dev/null 2>&1; then
    echo "[Git] Pulling latest changes for the 'www' folder"
    cd /home/container/www

    if [ -d .git ]; then
        git pull || echo "[Git] Failed to pull latest changes for the 'www' folder"
    else
        echo "[Git] No Git repository found in the 'www' folder, skipping pull"
    fi
else
    echo "[Git] Git is not installed, skipping Git pull"
fi