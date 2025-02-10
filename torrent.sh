#!/usr/bin/env bash

# Function to get the qBittorrent command for changing torrenting port
get_qbittorrent_command() {
    if command -v qbittorrent &> /dev/null; then
        echo "qbittorrent --torrenting-port="
    else
        echo "Error: qBittorrent is not installed."
        return 1
    fi
}

# Function to extract the mapped port from natpmpc output
extract_mapped_port() {
    local mapping_info="$1"
    if [[ $mapping_info =~ Mapped\ public\ port\ ([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
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
    mapped_port=$(extract_mapped_port "$tcp_mapping_info")
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
        echo "Changing qBittorrent port to $mapped_port"

        # Get the qBittorrent command
        qbittorrent_command=$(get_qbittorrent_command)
        if [ $? -eq 0 ]; then
            # Change qBittorrent port
            $qbittorrent_command$mapped_port

            # Update the previous mapped port
            previous_mapped_port="$mapped_port"
        else
            echo "Error: Unable to determine qBittorrent command."
        fi
    else
        echo "Mapped port has not changed. Skipping qBittorrent port update."
    fi

    sleep 45
done
