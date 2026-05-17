# Disable_Servers_Save_Battery 🔋❄️

A premium, performance-oriented Magisk/APatch module designed specifically to tackle severe battery drain, high idle consumption, and CPU heating issues on **ColorOS / OxygenOS 16** (Android 16) devices, optimized for **MediaTek Dimensity** platforms.

---

## 🌟 Core Features

### 1. System-less MediaTek Logger Block 🚫
Replaces core MediaTek debug loggers with zero-byte system-less mounts to completely stop CPU pinning and prevent gigabytes of continuous junk log writes to internal storage:
* Blocks `/system_ext/bin/connsyslogger` (Connectivity Logger)
* Blocks `/system_ext/bin/mobile_log_d` (Mobile System Logger)
* Blocks `/system_ext/bin/emdlogger` (Modem/Radio Logger)
* Overrides their respective `.rc` scripts in `/system_ext/etc/init/` to prevent `init` from ever registering or launching these background tasks.

### 2. Telemetry & Update Server Debloat 🛡️
Globally freezes and disables heavy background updating agents and tracking "servers" in ColorOS that run continuously and hog CPU cycles:
* `com.debug.loggerui` (MTK Logger Control)
* `com.oplus.nas` (Oppo Network Assistant — reduces CPU usage by 10%+)
* `com.oplus.olc` (Oppo Log Center Telemetry)
* `com.oplus.sau` (Oppo System App Update Service)
* `com.oplus.romupdate` (Oppo ROM Update Service)
* `com.oplus.nhs` (Oppo Network Health Service)
* `com.oplus.trafficmonitor` (Traffic Speed Monitor)
* `com.nearme.instant.platform` (HeyTap Instant Apps Platform)
* `com.oplus.appsense` (App analytics/usage monitoring)
* `com.oplus.appplatform` (Oplus Developer Framework)

### 3. Log Framework Muted 🤫
Injects standard power-saving logging configurations at early boot (via `system.prop`) and late boot (via `service.sh`) to mute framework-level spams:
```properties
persist.sys.debuglog.config=""
persist.vendor.aee.log.status=0
persist.vendor.aeev.log.status=0
persist.sys.log.tcpdump=0
persist.sys.log.user=0
persist.sys.oppo.junklog=false
```

### 4. Direct Telegram Redirection ✈️
Instantly redirects users to the official [ColorOS Modules Channel](https://t.me/colorosmodules) upon successful flashing in the Magisk app!

---

## 📥 Installation

1. Download the latest `Disable_Servers_Save_Battery.zip`.
2. Open the **Magisk Manager** or **KernelSU / APatch** app.
3. Go to the **Modules** tab.
4. Click **Install from storage** and select the zip.
5. Once installation finishes (it will automatically open the Telegram channel), reboot your device.
6. Enjoy a completely cool, smooth, and battery-friendly ROM!

---

## ⚙️ OTA Updates
This module features fully integrated Magisk auto-updates powered by the official repository metadata.

---

## 👤 Developer
* **Author:** Dev- [@imnotaino](https://t.me/imnotaino)
* **Channel:** [@colorosmodules](https://t.me/colorosmodules)
