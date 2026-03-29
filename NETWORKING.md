Yes, but with limitations.

In **NixOS**, you can create configurations that apply to **any interface that appears**, but you cannot deterministically assign different static addresses to multiple unknown interfaces without some unique identifier. The networking stack (typically **systemd-networkd**) must match on something.

However, several approaches approximate “first-come first-serve”.

---

# 1. Assign the same configuration to all Ethernet interfaces

If the goal is simply “any interface gets an address”, match on interface type.

```nix
{
  networking.useNetworkd = true;

  systemd.network.networks."10-ether" = {
    matchConfig.Type = "ether";

    networkConfig = {
      Address = "192.168.1.50/24";
      Gateway = "192.168.1.1";
    };
  };
}
```

All Ethernet interfaces will receive that address.
This only works if only one interface is connected to that network.

---

# 2. Use DHCP for universal deployments

This is the most common approach for hardware-agnostic NixOS builds.

```nix
{
  networking.useNetworkd = true;

  systemd.network.networks."10-all" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };
}
```

Any interface that appears will request an address automatically.

This is how most **portable NixOS images** work.

---

# 3. Priority matching (closest thing to first-come)

`systemd-networkd` processes rules in lexical order.

Example:

```nix
{
  networking.useNetworkd = true;

  systemd.network.networks."10-first" = {
    matchConfig.Type = "ether";
    networkConfig.Address = "192.168.1.10/24";
  };

  systemd.network.networks."20-second" = {
    matchConfig.Type = "ether";
    networkConfig.Address = "192.168.1.11/24";
  };
}
```

But this does **not guarantee ordering** across multiple interfaces.
Both interfaces will usually match the first rule.

So it does **not reliably assign different addresses**.

---

# 4. Automatic interface renaming (more flexible)

You can dynamically rename interfaces based on appearance order:

```nix
systemd.network.links."lan" = {
  matchConfig.Type = "ether";
  linkConfig.NamePolicy = "kernel";
};
```

Then configure wildcard networking.

This is sometimes used in appliance-style systems.

---

# 5. How universal NixOS images handle this

Generic NixOS builds typically do:

```nix
networking.useNetworkd = true;

systemd.network.networks."10-dhcp" = {
  matchConfig.Type = "ether";
  networkConfig.DHCP = "yes";
};
```

Examples include:

* cloud images
* installation ISOs
* container hosts

They avoid static addressing entirely.

---

# Key limitation

Static assignment like:

```
eth0 -> 192.168.1.10
eth1 -> 192.168.1.11
```

requires **some unique identifier**:

* MAC address
* PCI path
* interface name
* driver

Without that information, the kernel provides no way to distinguish interfaces.

---

# Practical recommendation

For a universal configuration:

```
Type = ether
DHCP = yes
```

Then control addresses through DHCP reservations on the router if needed.

---

If the goal is building **a portable NixOS config that runs on arbitrary machines**, there is a common pattern using hardware modules and network auto-configuration that avoids most interface naming issues. I can outline that structure if needed.
