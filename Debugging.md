# Debugging Senarios

A collection of strange gotchas and debug moments

## Login to Twich

Upon login, I was propted with `"Incompatible Browser"` despite firefox being explicitly listed.

*What was the fix you might ask?* The [**system clock!**](https://bbs.archlinux.org/viewtopic.php?id=289645)

```bash
sudo timedatectl set-timezone <time-zone> # For me, American/Phoenix
sudo timedatectl enable systemd-timesyncd --now
sudo timedatectl set-ntp true

# Then Check
timedatectl status
```

You should now see:

```md
Time Zone: <time-zone>
System clock syncrohonized:yes
NTP Service: active
```
