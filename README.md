# qBittorrent / ProtonVPN automatic port fowarding

This bash script automates the process of mapping the public port for qBittorrent using the natpmp protocol. It periodically checks for changes in the mapped public port and updates the qBittorrent port accordingly.

## Prerequisites

- **qBittorrent**: Ensure that `qBittorrent` is installed on your system.
- **qBittorrent**: web interface is enabled.
- **qBittorrent**: script is running on the same machine + web interface settings do not require a password for localhost 

## Usage

1. Copy the script to your local machine or server.
2. Make the script executable:
   ```bash
   chmod +x torrent.sh
   ```
3. Run the script:
   ```bash
   ./torrent.sh
   ```

## Workflow

1. The script uses natpmpc to port forward using Proton's published instructions.

2. It enters a continuous loop, checking for changes in the mapped public port every 45 seconds.

3. It uses the `natpmpc` tool to obtain the gateway address and map the public port using the natpmp protocol.

4. If the mapping is successful, the script extracts the mapped public port and compares it with the previous port.

5. The script repeats the process in the loop, continuously monitoring for changes in the mapped public port.

## Configuration

- Adjust the `sleep` duration at the end of the script to control how frequently the script checks for changes (default is 45 seconds).

## Notes

- You should only need to run this one script to keep the port forward active AND update Qbittorrent simultaneously. Hope this helps.
