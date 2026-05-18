<div align="center">

<img width="1774" height="887" alt="Disable Servers Save Battery" src="https://github.com/user-attachments/assets/da48877d-9215-429e-829d-d667d121251e" />

<img src="https://img.shields.io/badge/DisableServers-v1.5-blueviolet?style=for-the-badge&logo=android" alt="DisableServers"/>
<br/>
<img src="https://img.shields.io/badge/ColorOS%20%7C%20OOS16-Supported-brightgreen?style=for-the-badge"/>
<img src="https://img.shields.io/badge/MediaTek-Dimensity-orange?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Telegram-colorosmodules-blue?style=for-the-badge&logo=telegram"/>

# ❄️ Disable_Servers_Save_Battery

### Kill hidden background loggers, telemetry & overheating services on ColorOS / OxygenOS 16

Made with ♥ by **[Ayan (@imnotaino)](https://t.me/imnotaino)**  
Updates & Support → **[t.me/colorosmodules](https://t.me/colorosmodules)**

</div>

---

# 📖 What is this?

**Disable_Servers_Save_Battery** is a premium battery optimization module built for **ColorOS / OxygenOS 16** devices running on **MediaTek Dimensity** platforms.

Most Android 16 OPLUS ports suffer from terrible idle drain, random heating, overnight battery loss, and unnecessary CPU usage.

The funny part?
The ROM itself usually isn't the main issue.

The real battery killer is the amount of hidden:
- telemetry services
- analytics frameworks
- MediaTek debug daemons
- logging servers
- update agents
- network monitor services

running silently in the background 24/7.

These services constantly:
- wake CPU cores
- spam logs to storage
- increase thermal load
- trigger unnecessary wakelocks
- reduce deep sleep time

This module disables them cleanly and system-lessly without modifying `/system`.

Result:
- cooler idle temperatures
- smoother performance
- reduced standby drain
- better deep sleep
- less random lag spikes
- lower storage write cycles

---

# ✨ Features

| Feature | Description |
|---|---|
| 🚫 **MediaTek Logger Killer** | Blocks heavy MTK debug daemons completely |
| 🔋 **Battery Optimization** | Reduces idle drain & overnight battery loss |
| ❄️ **Cooler Temperatures** | Stops hidden CPU wakeups causing heating |
| 🛡️ **Telemetry Blocker** | Disables OPLUS analytics & tracking services |
| ⚡ **Performance Stability** | Less background load = smoother UI |
| 📱 **Dimensity Optimized** | Specifically tuned for MediaTek platforms |
| 🔧 **System-less Mounting** | No direct `/system` modification |
| 🚀 **Safe Removal** | Fully removable anytime |

---

# 🚫 MediaTek Logger Block

The module replaces several MediaTek logging binaries using zero-byte system-less mounts.

These loggers are infamous for:
- constant CPU usage
- modem wakeups
- huge log generation
- thermal spikes
- storage spam

Blocked binaries:

```bash
/system_ext/bin/connsyslogger
/system_ext/bin/mobile_log_d
/system_ext/bin/emdlogger
```

The module also overrides their init `.rc` scripts inside:

```bash
/system_ext/etc/init/
```

so Android `init` never registers or launches them again after boot.

This massively reduces background activity on Dimensity devices.

---

# 🛡️ Telemetry & Background Services Disabled

Several hidden OPLUS services are disabled globally during boot.

These services constantly run in background even when the phone is idle.

| Package | Purpose |
|---|---|
| `com.debug.loggerui` | MTK Logger Control |
| `com.oplus.nas` | Oppo Network Assistant |
| `com.oplus.olc` | OPLUS Log Center |
| `com.oplus.sau` | System App Updater |
| `com.oplus.romupdate` | ROM Update Service |
| `com.oplus.nhs` | Network Health Service |
| `com.oplus.trafficmonitor` | Traffic Monitor |
| `com.nearme.instant.platform` | Instant Apps Platform |
| `com.oplus.appsense` | Usage Analytics |
| `com.oplus.appplatform` | OPLUS Framework |

Most users never even open these apps/services, yet they continuously consume resources.

This module freezes them automatically during boot.

---

# 🤫 Framework Logging Disabled

Additional framework-level logging is muted using `system.prop` and boot-time scripts.

Applied props:

```properties
# Disable Debug Logs
persist.sys.debuglog.config=""
persist.vendor.aee.log.status=0
persist.vendor.aeev.log.status=0

# Disable TCP Dumps
persist.sys.log.tcpdump=0

# Disable User Logs
persist.sys.log.user=0

# Disable Oppo Junk Logs
persist.sys.oppo.junklog=false
```

This prevents unnecessary framework spam and excessive storage writes.

---

# 📦 What the module modifies

The module only mounts overlays and runtime props.

It does NOT modify:
- `/system`
- `/vendor`
- `/product`
- `/odm`

Everything is:
- temporary
- system-less
- reversible

---

# 📋 Requirements

- Android 16
- ColorOS / OxygenOS 16
- MediaTek Dimensity chipset
- Magisk / KernelSU / APatch
- Unlocked bootloader

---

# 🚀 Installation

1. Download latest `Disable_Servers_Save_Battery.zip`
2. Open:
   - Magisk
   - KernelSU
   - APatch
3. Go to **Modules**
4. Select **Install from storage**
5. Flash the ZIP
6. Reboot device

After successful installation:
- Telegram channel opens automatically
- Boot scripts apply optimizations during startup

---

# 🖥️ Flash Preview

```text
╔══════════════════════════════════════╗
║     Disable_Servers_Save_Battery     ║
║         Battery Optimization          ║
╚══════════════════════════════════════╝

  Developer : Ayan (@imnotaino)
  Channel   : t.me/colorosmodules

  Flash Time : 2026-05-18 11:47:36

──────────────────────────────────────
          ★  Device  Info  ★
──────────────────────────────────────
  Device  : realme Narzo 60x
  Codename: ossi
  Android : 16  (SDK 36)
  Build   : RMX3782_16.0.0.xxx
  Kernel  : 5.15.x
  Battery : 84%
──────────────────────────────────────

  ► Initialising environment...
  ► Verifying root access...
  ► Mounting logger overrides...
  ► Disabling telemetry services...
  ► Applying power-saving props...
  ► Freezing OPLUS background agents...
  ► Cleaning temporary files...

══════════════════════════════════════
 ✓ Disable_Servers_Save_Battery Ready!
══════════════════════════════════════

  ➤  t.me/colorosmodules

  Made with ♥ by Ayan (@imnotaino)
```

---

# ⚙️ OTA Updates

The module supports:
- Magisk updateJson
- OTA-style update checks
- automatic version tracking

Future updates can be delivered directly through Magisk app.

---

# ❓ FAQ

## Q: Will this improve battery life?

Yes.
Especially on MediaTek Dimensity devices where loggers and telemetry are extremely aggressive.

---

## Q: Will notifications break?

No.

The module does NOT touch:
- Google Play Services
- Android notification framework
- FCM services

---

## Q: Can this break OTA updates?

No.
Everything is system-less.

---

## Q: Why does this reduce heating?

Because hidden services continuously wake CPU cores even while idle.

Stopping them reduces:
- background scheduling
- thermal load
- storage writes
- wakelocks

---

## Q: Does this work on Snapdragon?

Partially.

But the module is mainly optimized for MediaTek Dimensity platforms.

---

## Q: Can I uninstall safely?

Yes.

Disable/remove the module and reboot.

Everything reverts automatically.

---

# 📢 Telegram Channel

For updates, support, and future optimization modules:

### 👉 https://t.me/colorosmodules

---

# 👤 Credits

| Role | Name |
|---|---|
| Developer | Ayan (@imnotaino) |
| Framework | MMT-Extended |
| Target OS | ColorOS / OxygenOS 16 |
| Optimized For | MediaTek Dimensity |

---

<div align="center">

### Made with ♥ by Ayan (@imnotaino)

t.me/colorosmodules

</div>
