# ProtonVPN automatic port forwarding & qBittorrent update

A simple bash script that keeps a ProtonVPN NAT-PMP port mapping alive and
updates qBittorrent automatically whenever the mapped port changes. It does
both jobs in one script — no cron jobs, no extra tools beyond `natpmpc`.

## Why use this?

If you torrent without port forwarding, you can still download — but you're
not *connectable*. Peers can't reach you directly, so you upload less, get
fewer swarm connections, and seeding to a healthy ratio becomes a grind.

Port forwarding fixes that. The catch with ProtonVPN:

- You **can't pick your own port** — you have to request one from Proton's
  NAT-PMP server, and it assigns you whatever it wants.
- The port **isn't permanent** — the mapping expires after 60 seconds and
  must be constantly renewed, and Proton can rotate you onto a different
  port (e.g. after a VPN reconnect).
- When the port changes, **qBittorrent needs to be told** — otherwise it
  keeps listening on a port that no longer points at you.

Doing that by hand means re-running `natpmpc` commands every minute and
re-typing the port into qBittorrent settings. This script does all of it
in a loop: renews the mapping, notices when the port changes, and pushes
the new port into qBittorrent automatically.

## Prerequisites

- **ProtonVPN**: a paid plan with port forwarding enabled, connected via
  WireGuard or OpenVPN
- **natpmpc**: installed on your system (`sudo apt install natpmpc` on
  Debian/Ubuntu)
- **qBittorrent**: installed with the Web interface enabled, and
  **Bypass authentication for clients on localhost** checked in
  Tools → Options → Web UI
- The script runs on the same machine as qBittorrent, and the VPN
  connection is up on that machine

## Usage

1. Save the script and make it executable:
   ```bash
   chmod +x portupdate.sh
   ```
2. Run it:
   ```bash
   ./portupdate.sh
   ```
3. Leave the terminal window open — the script needs to keep running to
   renew the port mapping (mappings expire after 60 seconds without a
   renewal).

## Workflow

1. On each cycle the script asks the VPN gateway for a UDP port mapping
   (public port 0 = let the server assign one).
2. It then binds TCP to that exact same public port, so UDP and TCP always
   match.
3. It compares the mapped port against the previous one. If it changed (or
   on the first run), it updates qBittorrent's listening port through the
   Web UI API. If not, it skips the update.
4. It waits 45 seconds and repeats, keeping the mapping alive and
   qBittorrent in sync forever.

If the VPN drops, the mapping dies with it — the script just reports the
error and keeps retrying until the connection is back.

## Configuration

Edit the variables at the top of the script if needed:

- `QBITTORRENT_HOST` / `QBITTORRENT_PORT` — where the qBittorrent Web UI
  is listening (default `localhost:8080`)
- `GATEWAY` — the NAT-PMP gateway (`10.2.0.1` is Proton's default)
- `LIFETIME` — requested mapping lifetime in seconds (default 60; Proton's
  maximum)
- `sleep 45` at the end of the loop — how often the mapping is renewed.
  Keep this below `LIFETIME`.

## Notes

- The script also disables qBittorrent's "different port on each startup"
  setting, so it can't fight the script.
- In qBittorrent it's worth enabling **Tools → Options → Advanced →
  Reannounce to all trackers when IP or port changed** — after a port
  change, peers otherwise keep the old port until the next tracker
  announce.
- Stopping the script simply lets the mapping expire; the next run picks
  up whatever port the server assigns.

---

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
</p>
<p align="center">
  <sub>Copyright © 2026 <a href="https://github.com/the-jame">the-jame</a> · Released under the <a href="LICENSE">MIT License</a></sub>
</p>
