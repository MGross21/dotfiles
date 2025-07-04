# KVM Troubleshooting Guide

This document covers common issues and solutions for cross-platform KVM setups.

## Input Leap Issues

### Issue: Cannot Connect Between Computers

**Symptoms:**
- Client cannot find server
- Connection timeout errors
- "Server not found" messages

**Solutions:**
1. **Check firewall settings:**
   ```bash
   # Allow Input Leap port (24800)
   sudo ufw allow 24800/tcp
   ```

2. **Use IP address instead of hostname:**
   ```bash
   # Instead of: input-leapc server-hostname
   input-leapc 192.168.1.100
   ```

3. **Verify network connectivity:**
   ```bash
   ping [server-ip]
   telnet [server-ip] 24800
   ```

### Issue: Wayland Compatibility Problems

**Symptoms:**
- Mouse/keyboard not working properly
- Clipboard sharing failures
- Input lag or missed inputs

**Solutions:**
1. **Ensure XWayland is installed:**
   ```bash
   pacman -S xorg-xwayland
   ```

2. **For Hyprland, uncomment in hyprland.conf if needed:**
   ```bash
   env = GDK_BACKEND,x11
   ```

3. **Check Input Leap Wayland support:**
   ```bash
   # Run with debug output
   input-leaps -f -c ~/.config/input-leap/server.conf --log ~/.config/input-leap/debug.log
   ```

### Issue: Permission Denied Errors

**Symptoms:**
- "Permission denied" when accessing input devices
- Service fails to start

**Solutions:**
1. **Ensure user is in input group:**
   ```bash
   groups $USER  # Should show 'input'
   # If not, add user to group:
   sudo usermod -aG input $USER
   ```

2. **Restart session after group changes:**
   ```bash
   # Log out and back in, or:
   newgrp input
   ```

## Alternative Solutions

### If Input Leap Doesn't Work

1. **Try Deskflow (may have Wayland issues):**
   ```bash
   yay -S deskflow
   ```

2. **Use Barrier (deprecated but stable):**
   ```bash
   yay -S barrier
   ```

3. **KDE Connect (for basic sharing):**
   ```bash
   pacman -S kdeconnect
   ```

### Windows Setup Issues

**For Windows clients/servers:**

1. **Download from official releases:**
   - [Input Leap Releases](https://github.com/input-leap/input-leap/releases)

2. **Windows Firewall:**
   - Allow Input Leap through Windows Firewall
   - Port 24800 must be open

3. **Antivirus Software:**
   - Some antivirus may block Input Leap
   - Add Input Leap to whitelist

## Network Setup

### For Advanced Users

1. **Custom port configuration:**
   Edit server config to use different port if 24800 is blocked

2. **SSH tunneling for remote connections:**
   ```bash
   ssh -L 24800:localhost:24800 user@remote-server
   ```

3. **VPN considerations:**
   Some VPNs may interfere with local network discovery

## Logs and Debugging

### Enable detailed logging:
```bash
# Server
input-leaps -f -c ~/.config/input-leap/server.conf --log ~/.config/input-leap/server.log --debug DEBUG2

# Client  
input-leapc --log ~/.config/input-leap/client.log --debug DEBUG2 [server-ip]
```

### Check systemd logs:
```bash
journalctl --user -u input-leap-server.service -f
```

## Performance Optimization

1. **Reduce input lag:**
   - Use wired network connections when possible
   - Ensure QoS settings prioritize Input Leap traffic

2. **For gaming:**
   - Disable Input Leap during gaming sessions
   - Use hardware KVM switch for latency-critical applications

## Getting Help

- [Input Leap Issues](https://github.com/input-leap/input-leap/issues)
- [Arch Linux Forums](https://bbs.archlinux.org/)
- [Reddit r/linux4noobs](https://www.reddit.com/r/linux4noobs/)