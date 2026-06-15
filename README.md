<div align="center">

<img width="1280" height="640" alt="image" src="https://github.com/user-attachments/assets/a8fec90a-6e0f-4a6f-bac2-be90e991684a" />
<img width="1774" height="887" alt="Disable Servers Save Battery" src="https://github.com/user-attachments/assets/da48877d-9215-429e-829d-d667d121251e" />

<img src="https://img.shields.io/badge/DisableServers-v1.9_Stable-blueviolet?style=for-the-badge&logo=android" alt="DisableServers"/>
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

The real battery killer is the massive amount of hidden:
- telemetry services & AI engines
- MediaTek debug daemons
- logging servers
- crash tracers
- update agents
- UI tracking services

running silently in the background 24/7.

These services constantly:
- wake CPU cores
- spam network requests
- increase thermal load
- trigger unnecessary wakelocks
- ruin deep sleep

This module targets and disables them cleanly using native Linux `SIGSTOP` scripts and system-less mounting, without breaking your ROM.

Result:
- cooler idle temperatures
- smoother performance
- massively reduced standby drain
- superior deep sleep
- fewer random lag spikes
- lower storage write cycles

---

# ✨ Features

| Feature | Description |
|---|---|
| 🚫 **MediaTek Logger Killer** | Blocks heavy MTK debug & modem daemons completely |
| 🧠 **AI Daemon Freezing** | Forcefully suspends aggressive `midas` & `oplus_gaia` AI trackers |
| 🔋 **Battery Optimization** | Plugs the leaks causing overnight battery drain |
| ❄️ **Cooler Temperatures** | Stops hidden CPU wakeups that cause random heating |
| 🛡️ **Massive Telemetry Purge** | Shuts down over 12 hidden OPlus analytics services |
| 📊 **Action Menu Diagnostics** | Tap the Magisk Action button for an instant live hardware readout |
| 📱 **Dimensity Optimized** | Specifically tuned for MediaTek platforms |
| 🔧 **System-less** | No direct `/system` modification |

---

# 🚫 Native Daemon Block & Freeze

The module tackles heavy background processes using two methods: zero-byte system-less mounts, and boot-time `killall -STOP` freezing. 

These daemons are infamous for constant CPU usage, thermal spikes, and storage spam:

```bash
# MediaTek Network & Modem Loggers
/system_ext/bin/connsyslogger
/system_ext/bin/mobile_log_d
/system_ext/bin/emdlogger

# OPlus AI Performance & Analytics
/system_ext/bin/midasd
/system_ext/bin/oplus_gaia
/vendor/bin/hw/vendor.oplus.hardware.cammidasservice-V1-service

# OPlus Crash Tracing & UI Tracking
/system_ext/bin/oplus_theia
/system_ext/bin/theia_screen_monitor
/system_ext/bin/opluscvtmanager
/system_ext/bin/phoenix_log_manager
/system_ext/bin/ostatsd
```

Because OPlus tries to aggressively restart these services when killed, **v1.9** utilizes a powerful permanent suspension script during boot so Android `init` never realizes they are disabled.

---

# 🛡️ Telemetry & APK Bloat Disabled

Several hidden OPLUS apps are disabled globally during boot. Most users never even open these apps/services, yet they continuously consume resources.

| Package | Purpose |
|---|---|
| `com.debug.loggerui` | MTK Logger Control |
| `com.oplus.olc` | OPLUS Log Center |
| `com.oplus.sau` | System App Updater |
| `com.oplus.romupdate` | ROM Update Service |
| `com.nearme.instant.platform` | Instant Apps Platform |
| `com.oplus.appsense` | Usage Analytics |
| `com.oplus.appplatform` | OPLUS Framework |
| `com.oplus.onetrace` | OTrace Telemetry |
| `com.oplus.powermonitor` | Useless background stats tracker |

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

The module only mounts overlays, runtime props, and executes boot-scripts.

It does NOT permanently modify:
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

- Android 14 / 15 / 16
- ColorOS / OxygenOS 15 / 16
- MediaTek Dimensity chipset
- Magisk / KernelSU / APatch
- Unlocked bootloader

---

# 🚀 Installation

1. Download latest `Disable_Servers_Save_Battery_v1.9.zip`
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
- **New:** Use the Magisk Action button on the module tab to trigger a live battery/hardware diagnostic check!

---

# ❓ FAQ

## Q: Will this improve battery life?

Yes. Especially on MediaTek Dimensity devices running OPlus ports, where loggers, AI analytics, and telemetry are extremely aggressive.

---

## Q: Will notifications break?

No. The module does NOT touch Google Play Services, the Android notification framework, or FCM services. Gaming networks (`nas`, `nhs`) are strictly preserved.

---

## Q: Can this break OTA updates?

No. Everything is system-less.

---

## Q: Why does this reduce heating?

Because hidden services continuously wake CPU cores and read network states even while idle. Stopping them reduces background scheduling, thermal load, storage writes, and wakelocks.

---

## Q: Does this work on Snapdragon?

Partially. But the module is heavily optimized for MediaTek Dimensity and OPlus specific daemons.

---

## Q: Can I uninstall safely?

Yes. Disable/remove the module and reboot. Everything reverts automatically.

---

# 📢 Telegram Channel

For updates, support, and future optimization modules:

### 👉 [t.me/colorosmodules](https://t.me/colorosmodules)

---

# 👤 Credits

| Role | Name |
|---|---|
| Developer | Ayan (@imnotaino) |
| Target OS | ColorOS 15/16 & OxygenOS 15/16 |
| Optimized For | MediaTek Dimensity |

---

<div align="center">

### Made with ♥ by Ayan (@imnotaino)

[t.me/colorosmodules](https://t.me/colorosmodules)

</div>
