#!/bin/bash

# [Tunnel] Check if cloudflared_token.txt exists and has content
if [ -s "/home/container/cloudflared_token.txt" ]; then
    # If the file has content, start cloudflared using the content as the token
    echo "[Tunnel] Starting cloudflared tunnel with token"
    cloudflared tunnel --no-autoupdate run --token "$(cat /home/container/cloudflared_token.txt)" > /dev/null 2>&1 &

    # Wait for the tunnel to start
    echo "[Tunnel] Waiting for cloudflared tunnel to start..."
    
    # Set max number of attempts
    MAX_ATTEMPTS=10
    ATTEMPT=0

    # Check if cloudflared is running, repeat every 1 second until it is or max attempts reached
    while ! pgrep -x "cloudflared" > /dev/null && [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        ATTEMPT=$((ATTEMPT + 1))
        sleep 1
    done

    # If cloudflared is running
    if pgrep -x "cloudflared" > /dev/null; then
        # Green success message
        echo -e "[Tunnel]\033[0;32m Cloudflared tunnel is running successfully.\033[0m"
    else
        echo -e "[Tunnel]\033[0;31m Failed to start cloudflared tunnel after $MAX_ATTEMPTS attempts. Exiting...\033[0m"
        exit 1
    fi

else
    echo "[Tunnel]\033[0;31m cloudflared_token.txt is empty or does not exist. Skipping cloudflared startup.\033[0m"
fi
