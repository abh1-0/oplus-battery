# ❄️ Battery Saver & Debloater (Qualcomm Edition)

### Kill hidden background loggers, telemetry & overheating services on OnePlus / Oppo SnapDragon devices 

Forked and optimized by **[abh1](https://t.me/op9devs)**  
Original by **[Ayan (@imnotaino)](https://t.me/imnotaino)**  

Updates & Support → **[t.me/op9devs](https://t.me/op9devs)**

---

# 📖 What is this?

**Battery Saver & Debloater** is a premium optimization module built for **OnePlus and Oppo Qualcomm Snapdragon** devices running **OxygenOS / ColorOS 15 & 16**.

Many Android 15/16 OPLUS ports and ROMs suffer from standby idle drain, overnight battery loss, thermal throttling, and background CPU overhead. The culprit isn't necessarily the hardware or the ROM itself, but a massive stack of background services:

- Telemetry engines & AI tracking agents
- Debug daemons & OPlus loggers
- Crash tracers & updater agents
- System UI monitoring trackers

This module cleans them up using system-less mounts and boot-time `killall` / suspension scripts without breaking essential system functions.
### Key Benefits:
- 📉 Massively reduced stanby drain while you're sleepin' (while the device isn't being used)
- 🌡️ Cooler idle temperatures & optimized thermal profiles
- 💤 Faster entry into deep sleep
- ⚡ Smoother overall system performance
- 💾 Reduced storage write cycles from constant background logger spam

---

# ✨ Features

| Feature | Description |
|---|---|
| ⚡ **Snapdragon Optimized** | Tuned specifically to address Qualcomm & OPlus framework anomalies unlike the original developer's version |
| 🧠 **AI Daemon Management** | Restrains resource-heavy services while keeping critical framework engines (`oplus_gaia`) safe |
| 🔋 **Battery Saver Pro** | Resolves fast battery drain and deep sleep issues |
| ❄️ **Cooler CPU Temps** | Eliminates wakeups that lead to idle heating |
| 🛡️ **No Core Breaks** | Maintains compatibility with Google Quick Search Box (Circle to Search), App Services, and Screenshots |
| 📊 **Action Menu Diagnostics** | Tap the Magisk Action button for a live battery and hardware diagnostic readout |
| 🔧 **100% System-less** | No permanent modification of `/system`, `/vendor`, or `/product` |

---

# 🚫 Native Daemon Block & Freeze

The module prevents system loggers and trackers from eating CPU cycles and writing logs continuously:

```bash
# OPlus AI Performance & Analytics
/system_ext/bin/midasd
/vendor/bin/hw/vendor.oplus.hardware.cammidasservice-V1-service

# OPlus Crash Tracing & UI Tracking
/system_ext/bin/oplus_theia
/system_ext/bin/theia_screen_monitor
/system_ext/bin/opluscvtmanager
/system_ext/bin/phoenix_log_manager
/system_ext/bin/ostatsd
```

*Note: Critical components like `oplus_gaia`, screenshot engines, and key Google services are explicitly protected to prevent system crashes or features breaking.*

---

# 🛡️ Telemetry & APK Bloat Disabled

Aggressive background APKs and services are frozen system-lessly on startup to reclaim memory and CPU cycles:

| Package | Purpose |
|---|---|
| `com.oplus.olc` | OPlus Log Center |
| `com.oplus.sau` | System App Updater |
| `com.oplus.romupdate` | ROM Update Service |
| `com.nearme.instant.platform` | Instant Apps Platform |
| `com.oplus.appsense` | Usage Analytics |
| `com.oplus.onetrace` | OTrace Telemetry |
| `com.oplus.powermonitor` | Background Battery Statistics |

---

# 🤫 Framework Logging Disabled

Logging levels are optimized via system properties and start scripts to limit background filesystem wear:

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

---

# 🚀 Installation

1. Download the latest `BatterySaver/Debloater`.
2. Open **Magisk**, **KernelSU**, or **APatch**.
3. Head to the **Modules** tab.
4. Select **Install from storage** and flash the ZIP.
5. Reboot your device.

---

# 📢 Telegram Group

Join the group for updates, support, and discussions:

### 👉 **[t.me/op9devs](https://t.me/op9devs)**

---

# 👤 Credits

- **Fork Developer / Maintainer:** [abh1](https://t.me/abh1-0)
- **Original Developer:** [Ayan (@imnotaino)](https://t.me/imnotaino) 
