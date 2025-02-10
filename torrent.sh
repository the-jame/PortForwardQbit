#!/usr/bin/env bash

# qBittorrent Web UI API settings
QBITTORRENT_HOST="localhost"
QBITTORRENT_PORT="8080"
QBITTORRENT_API_URL="http://$QBITTORRENT_HOST:$QBITTORRENT_PORT/api/v2"

# Function to set qBittorrent listen port via Web UI API
set_qbittorrent_port() {
    local port="$1"
    local payload="json={\"listen_port\": $port}"

    # Send the request to update the listen port
    curl -s -X POST -d "$payload" "$QBITTORRENT_API_URL/app/setPreferences"
    if [[ $? -eq 0 ]]; then
        echo "Successfully updated qBittorrent listen port to $port."
    else
        echo "ERROR: Failed to update qBittorrent listen port."
    fi
}

previous_mapped_port=""

while true; do
    date

    # Run natpmpc for UDP and TCP port mapping
    udp_mapping_info=$(natpmpc -a 1 0 udp 60 -g 10.2.0.1 2>&1)
    tcp_mapping_info=$(natpmpc -a 1 0 tcp 60 -g 10.2.0.1 2>&1)

    # Check if natpmpc succeeded
    if [[ $? -ne 0 ]]; then
        echo "ERROR: natpmpc command failed."
        echo "UDP Output: $udp_mapping_info"
        echo "TCP Output: $tcp_mapping_info"
        sleep 45
        continue
    fi

    # Extract the mapped port (use TCP output as it's more reliable)
    mapped_port=$(echo "$tcp_mapping_info" | grep -oP 'Mapped\ public\ port\ \K[0-9]+')
    if [[ -z "$mapped_port" ]]; then
        echo "ERROR: Failed to extract Mapped public port from natpmpc output."
        echo "UDP Output: $udp_mapping_info"
        echo "TCP Output: $tcp_mapping_info"
        sleep 45
        continue
    fi

    echo "Mapped public port: $mapped_port"
    notify-send "Port Forwarding" "Mapped public port: $mapped_port"

    # Check if the mapped port has changed
    if [[ "$mapped_port" != "$previous_mapped_port" ]]; then
        echo "Changing qBittorrent listen port to $mapped_port"

        # Update qBittorrent listen port via Web UI API
        set_qbittorrent_port "$mapped_port"

        # Update the previous mapped port
        previous_mapped_port="$mapped_port"
    else
        echo "Mapped port has not changed. Skipping qBittorrent port update."
    fi

    sleep 45
done
