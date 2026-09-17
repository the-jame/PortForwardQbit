#!/usr/bin/env bash

# qBittorrent Web UI API settings
QBITTORRENT_HOST="localhost"
QBITTORRENT_PORT="8080"
QBITTORRENT_API_URL="http://$QBITTORRENT_HOST:$QBITTORRENT_PORT/api/v2"

# NAT-PMP settings (ProtonVPN defaults)
GATEWAY="10.2.0.1"
LIFETIME=60

# Function to set qBittorrent listen port via Web UI API
set_qbittorrent_port() {
    local port="$1"
    local payload="json={\"listen_port\": $port, \"random_port\": false}"

    # -f makes curl fail on HTTP errors (403, 500, ...) so $? is meaningful
    curl -fsS --max-time 10 -X POST -d "$payload" "$QBITTORRENT_API_URL/app/setPreferences"
    if [[ $? -eq 0 ]]; then
        echo "Successfully updated qBittorrent listen port to $port."
    else
        echo "ERROR: Failed to update qBittorrent listen port."
    fi
}

# Extract the mapped public port from natpmpc output.
# Tolerates both "port: 52844" and "port : 52844" formats.
get_mapped_port() {
    sed -nE 's/.*Mapped public port[^0-9]*([0-9]+).*/\1/p'
}

previous_mapped_port=""

while true; do
    date

    # Renew the UDP mapping (public port 0 = let the server assign one)
    udp_mapping_info=$(natpmpc -a 1 0 udp "$LIFETIME" -g "$GATEWAY" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "ERROR: natpmpc UDP mapping failed."
        echo "$udp_mapping_info"
        sleep 45
        continue
    fi

    mapped_port=$(get_mapped_port <<<"$udp_mapping_info")
    if [[ -z "$mapped_port" ]]; then
        echo "ERROR: Failed to extract mapped public port from natpmpc output."
        echo "UDP Output: $udp_mapping_info"
        sleep 45
        continue
    fi

    # Bind TCP to the SAME public port so both protocols match
    tcp_mapping_info=$(natpmpc -a 1 "$mapped_port" tcp "$LIFETIME" -g "$GATEWAY" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "ERROR: natpmpc TCP mapping failed."
        echo "$tcp_mapping_info"
        sleep 45
        continue
    fi

    tcp_port=$(get_mapped_port <<<"$tcp_mapping_info")
    if [[ "$tcp_port" != "$mapped_port" ]]; then
        echo "ERROR: UDP and TCP mapped ports differ (udp=$mapped_port tcp=$tcp_port)."
        sleep 45
        continue
    fi

    echo "Mapped public port: $mapped_port"

    # Check if the mapped port has changed
    if [[ "$mapped_port" != "$previous_mapped_port" ]]; then
        echo "Changing qBittorrent listen port to $mapped_port"
        set_qbittorrent_port "$mapped_port"
        previous_mapped_port="$mapped_port"
    else
        echo "Mapped port not changed. Skipping qBittorrent port update."
    fi

    sleep 45
done
