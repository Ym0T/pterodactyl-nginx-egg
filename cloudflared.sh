#!/bin/bash

# Header
echo -e " "
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"
echo -e "\033[1;34m[Tunnel] Cloudflare Tunnel\033[0m"
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"

# [Tunnel] Check if cloudflared_token.txt exists and has content
if [ -s "/home/container/cloudflared_token.txt" ]; then
    echo -e "\033[0;37m[Tunnel] Starting Cloudflared with token...\033[0m"

    # Start cloudflared in the background and store the PID
    cloudflared tunnel --no-autoupdate run --token "$(cat /home/container/cloudflared_token.txt)" > /home/container/logs/cloudflared.log 2>&1 &
    CLOUD_FLARED_PID=$!

    echo $CLOUD_FLARED_PID > /home/container/tmp/cloudflared.pid

    # Display waiting message
    echo -ne "\033[0;33m[Tunnel] Waiting for Cloudflared to start\033[0m"

    MAX_ATTEMPTS=10
    ATTEMPT=0

    # Monitor log file in real-time for a success or failure message
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        echo -ne "."  # Add a dot every second
        sleep 1
        ATTEMPT=$((ATTEMPT + 1))

        # Check if cloudflared has exited
        if ! kill -0 $CLOUD_FLARED_PID 2>/dev/null; then
            echo -e "\n\033[0;31m[Tunnel] Cloudflared failed to start. Check logs at /home/container/logs/cloudflared.log\033[0m"
            echo -e "\033[0;31m$(tail -n 10 /home/container/logs/cloudflared.log)\033[0m"
            exit 1
        fi

        # Check log file for success messages
        if grep -qE "Registered tunnel connection|Updated to new configuration" /home/container/logs/cloudflared.log; then
            echo -e "\n\033[0;32m[Tunnel] Cloudflared is running successfully!\033[0m"
            exit 0
        fi
    done

    # If we reach here, max attempts were reached without confirmation
    echo -e "\n\033[0;31m[Tunnel] Cloudflared did not confirm a successful connection. Check logs at /home/container/logs/cloudflared.log\033[0m"
    echo -e "\033[0;31m$(tail -n 10 /home/container/logs/cloudflared.log)\033[0m"
    exit 1

else
    echo -e "\033[0;31m[Tunnel] cloudflared_token.txt is empty or does not exist. Skipping Cloudflared startup.\033[0m"
fi
