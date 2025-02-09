#!/bin/bash

# Header
echo -e " "
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"
echo -e "\033[1;34m[Git] Checking & Updating Repository\033[0m"
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"

# [Git] Check if Git is installed
if command -v git > /dev/null 2>&1; then
    echo -e "\033[0;37m[Git] Pulling latest changes for the 'www' folder...\033[0m"
    cd /home/container/www

    if [ -d .git ]; then
        if git pull; then
            echo -e "\033[0;32m[Git] Successfully updated repository.\033[0m"
        else
            echo -e "\033[0;31m[Git] Failed to pull latest changes.\033[0m"
        fi
    else
        echo -e "\033[0;33m[Git] No Git repository found, skipping pull.\033[0m"
    fi
else
    echo -e "\033[0;31m[Git] Git is not installed, skipping update.\033[0m"
fi
