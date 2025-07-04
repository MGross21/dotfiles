# Input Leap Configuration

Input Leap is a cross-platform KVM (Keyboard, Video, Mouse) sharing solution that allows you to control multiple computers with a single keyboard and mouse.

## Overview

Input Leap is the actively maintained successor to Barrier, providing:
- Cross-platform support (Linux, Windows, macOS)
- Better Wayland compatibility than older alternatives
- Secure encrypted connections
- Multiple monitor support

## Setup

### Server Setup (Main Computer)

1. Install Input Leap: `yay -S input-leap`
2. Run the GUI: `input-leap`
3. Configure as Server
4. Set up screen layout and client computers
5. Start the server

### Client Setup (Secondary Computer)

1. Install Input Leap on the client machine
2. Configure as Client
3. Set the server IP address
4. Connect to the server

### Command Line Usage

#### Server
```bash
# Start server (replace with your configuration file)
input-leaps -c ~/.config/input-leap/server.conf

# Start server with logging
input-leaps -c ~/.config/input-leap/server.conf -f --log ~/.config/input-leap/server.log
```

#### Client
```bash
# Connect to server (replace SERVER_IP with actual IP)
input-leapc SERVER_IP

# Connect with logging
input-leapc --log ~/.config/input-leap/client.log SERVER_IP
```

## Auto-Start with Systemd (Optional)

For automatic startup, you can use the provided systemd service:

1. Copy the service file:
```bash
cp ~/.config/input-leap/input-leap-server.service.example ~/.config/systemd/user/input-leap-server.service
```

2. Edit the service file to match your setup

3. Enable and start the service:
```bash
systemctl --user daemon-reload
systemctl --user enable input-leap-server.service
systemctl --user start input-leap-server.service
```

## Configuration Files

- `server.conf` - Server configuration file
- `client.conf` - Client configuration file (if needed)

## Troubleshooting

### Wayland Issues

If you experience issues with Wayland, you may need to:

1. Ensure Input Leap has proper Wayland permissions
2. Check if XWayland is installed: `pacman -Qi xorg-xwayland`
3. For Hyprland-specific issues, see the Hyprland configuration

### Firewall

Make sure port 24800 (default) is open on the server:
```bash
# For ufw
sudo ufw allow 24800

# For firewalld
sudo firewall-cmd --permanent --add-port=24800/tcp
sudo firewall-cmd --reload
```

### Network Discovery

If clients can't find the server:
- Use IP address instead of hostname
- Ensure both machines are on the same network
- Check that no VPN is interfering

## Links

- [Input Leap GitHub](https://github.com/input-leap/input-leap)
- [Arch Wiki - Synergy](https://wiki.archlinux.org/title/Synergy) (general KVM information)