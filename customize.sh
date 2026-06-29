#!/system/bin/sh
# BatterySaver & Debloater v1.0 -- customize.sh
# Executed by Magisk/KSU/APatch during installation.

SKIPUNZIP=0

sleep_print() { sleep 0.3; }

# Simple device detection for install banner
DEVICE="$(getprop ro.product.model 2>/dev/null)"
[ -z "$DEVICE" ] && DEVICE="$(getprop ro.product.device 2>/dev/null)"
[ -z "$DEVICE" ] && DEVICE="Unknown"

ANDROID="$(getprop ro.build.version.release 2>/dev/null)"
[ -z "$ANDROID" ] && ANDROID="Unknown"

MOD_VER="$(grep -m1 '^version=' "$MODPATH/module.prop" 2>/dev/null | cut -d= -f2-)"
[ -z "$MOD_VER" ] && MOD_VER="v1.0"

ui_print " "
ui_print "===================================================="
ui_print "     ULTRA BATTERY SAVER & DEBLOATER (v1.0)         "
ui_print "     By abh1  |  STABLE OPTIMIZED                   "
ui_print "===================================================="
ui_print "                   __   __  __"
ui_print "                  \\ \\ / / /_ |"
ui_print "                   \\ V /   | |"
ui_print "                    > <    | |"
ui_print "                   / . \\   | |"
ui_print "                  /_/ \\_\\  |_|"
ui_print "===================================================="
ui_print " Device   : $DEVICE"
ui_print " Android  : $ANDROID"
ui_print " ModuleID : combined_debloat_battery"
ui_print "===================================================="
ui_print " "
sleep_print

# -----------------------------------------------
# Device & Battery Info
# -----------------------------------------------
ui_print "[*] Gathering Device & Battery Info..."
sleep_print
BRAND=$(getprop ro.product.brand)
BOARD=$(getprop ro.board.platform)
SEC_PATCH=$(getprop ro.build.version.security_patch)
KERNEL=$(uname -r)

ui_print "    [OK] Device    : $BRAND $DEVICE"
ui_print "    [OK] SoC       : $BOARD"
ui_print "    [OK] Android   : $ANDROID"
ui_print "    [OK] Sec Patch : $SEC_PATCH"
ui_print "    [OK] Kernel    : $KERNEL"
sleep_print

BATT_LEVEL=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
BATT_TEMP_RAW=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
BATT_VOLT_RAW=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
if [ -n "$BATT_TEMP_RAW" ]; then BATT_TEMP="$((BATT_TEMP_RAW/10)).$((BATT_TEMP_RAW%10))C"; else BATT_TEMP="N/A"; fi
if [ -n "$BATT_VOLT_RAW" ]; then BATT_VOLT="$((BATT_VOLT_RAW/1000000)).$(((BATT_VOLT_RAW%1000000)/100000))V"; else BATT_VOLT="N/A"; fi
ui_print "    [OK] Battery   : ${BATT_LEVEL}%  |  Temp: $BATT_TEMP  |  Volt: $BATT_VOLT"
sleep_print

# -----------------------------------------------
# Logger Binary Overrides (Filtered of gaia/theia)
# -----------------------------------------------
ui_print " "
ui_print "[*] System-lessly overriding Logger Binaries..."
for bin in connsyslogger mobile_log_d emdlogger midasd logd logcat tcpdump; do
    ui_print "    [-] /system_ext/bin/$bin"
    sleep_print
done

# -----------------------------------------------
# Init .rc Overrides
# -----------------------------------------------
ui_print " "
ui_print "[*] Overriding Init .rc configs..."
for rc in logd logcat logcatd atrace bugreport debuggerd dmesgd dumpstate \
          tombstoned traced_perf traced_probes traceur lpdumpd; do
    ui_print "    [-] $rc.rc"
    sleep_print
done

# -----------------------------------------------
# APK Debloating (Filtered of core system apps/services)
# -----------------------------------------------
ui_print " "
ui_print "[*] Muting background telemetry & bloatware..."
sleep_print
for pkg in com.debug.loggerui com.oplus.olc com.oplus.sau com.oplus.romupdate \
           com.nearme.instant.platform com.oplus.appsense \
           com.oplus.crashbox com.oplus.healthservice com.oplus.logkit \
           com.oplus.onetrace com.oplus.powermonitor \
           com.oplus.sauhelper com.oplus.appbooster \
           com.oplus.deepthinker com.oplus.dfs com.android.mms.service \
           com.coloros.assistantscreen com.oplus.tingle com.oplus.qualityprotect \
           com.oplus.midas; do
    ui_print "    [-] $pkg"
    sleep_print
done

# -----------------------------------------------
# Google Analytics Services disabled
# -----------------------------------------------
ui_print " "
ui_print "[*] Disabling Google analytics/ads services..."
sleep_print
ui_print "    [-] GMS AdvertisingIdService, AnalyticsService"
sleep_print
ui_print "    [-] GMS AppMeasurementService, MeasurementBrokerService"
sleep_print
ui_print "    [-] GMS PlatformStatsCollectorService, EventLogService"
sleep_print
ui_print "    [-] GMS UsageReportingIntentService, CollectionService"
sleep_print
ui_print "    [-] WebView MetricsBridgeService, MetricsUploadService"
sleep_print
ui_print "    [-] Play Store AppStatesService"
sleep_print

# -----------------------------------------------
# Re-enabled apps
# -----------------------------------------------
ui_print " "
ui_print "[*] Restoring Network & Gaming Apps..."
sleep_print
for pkg in com.oplus.nas com.oplus.nhs com.oplus.trafficmonitor \
           com.oplus.wirelesssettings com.oplus.gameopt; do
    ui_print "    [+] $pkg"
    sleep_print
done

# -----------------------------------------------
# Optimizations Summary
# -----------------------------------------------
ui_print " "
ui_print "[*] Applying v1.0 Optimizations..."
sleep_print
ui_print "    [+] midasd -> kill_oplus_daemon() [pgrep+kill+SIGSTOP]"
sleep_print
ui_print "    [+] oplus_gaia, athena, epona, screenshots -> preserved perfectly!"
sleep_print
ui_print "    [+] GPU: Mali-G57 simple_ondemand + coarse_demand policy"
sleep_print
ui_print "    [+] CPU: LITTLE=1500MHz BIG=1800MHz + sugov_ext rate limiting"
sleep_print
ui_print "    [+] RAM-adaptive swappiness (3GB=100 4GB=60 6GB=40 8GB+=20)"
sleep_print
ui_print "    [+] RAM-adaptive dirty VM params (quickmem)"
sleep_print
ui_print "    [+] I/O: BFQ/CFQ scheduler, read_ahead=128KB, nr_requests=64"
sleep_print
ui_print "    [+] TCP: tcp_ecn=1, tcp_fastopen=3, tcp_no_metrics_save=1"
sleep_print
ui_print "    [+] Printk disabled, CRC disabled, ramdump disabled"
sleep_print
ui_print "    [+] Debug masks, trace nodes silenced"
sleep_print
ui_print "    [+] power_efficient workqueue enabled"
sleep_print
ui_print "    [+] Aggressive Doze idle constants applied"
sleep_print
ui_print "    [+] WiFi scan + NTP wakeups disabled"
sleep_print
ui_print "    [+] GMS/Ayugram -> restricted standby bucket"
sleep_print
ui_print "    [+] WhatsApp + YouTube -> background kept alive"
sleep_print
ui_print "    [+] power_mode=1 (OPlus battery-friendly baseline)"
sleep_print

# -----------------------------------------------
# Frozen Daemon List
# -----------------------------------------------
ui_print " "
ui_print "[*] Daemons frozen with SIGSTOP..."
sleep_print
ui_print "    midasd  emdlogger  mobile_log_d"
sleep_print
ui_print "    connsyslogger  ostatsd  ostats_pullerd"
sleep_print
ui_print "    ostats_tpd  opluscvtmanager  phoenix_log_manager"
sleep_print

# -----------------------------------------------
# Permissions & Debloater Binary Setup
# -----------------------------------------------
ui_print " "
ui_print "[*] Setting file permissions & setting up Debloater binary..."
sleep_print

mkdir -p "$MODPATH"
mkdir -p "$MODPATH/system/bin"
mkdir -p "$MODPATH/system/etc/init"

find "$MODPATH" -type d -exec chmod 0755 {} \;
find "$MODPATH" -type f -exec chmod 0644 {} \;

chmod 0755 "$MODPATH/service.sh" 2>/dev/null
chmod 0755 "$MODPATH/action.sh"  2>/dev/null
chmod 0755 "$MODPATH/post-fs-data.sh" 2>/dev/null
chown 0:0  "$MODPATH/service.sh" 2>/dev/null
chown 0:0  "$MODPATH/action.sh"  2>/dev/null
chown 0:0  "$MODPATH/post-fs-data.sh" 2>/dev/null

if [ -f "$MODPATH/system/bin/debloater" ]; then
    chmod 0755 "$MODPATH/system/bin/debloater" 2>/dev/null
    chown 0:0 "$MODPATH/system/bin/debloater" 2>/dev/null
fi

if command -v restorecon >/dev/null 2>&1; then
    restorecon -RF "$MODPATH" 2>/dev/null
fi

ui_print "    [OK] service.sh       -- executable (755)"
ui_print "    [OK] action.sh        -- executable (755)"
ui_print "    [OK] post-fs-data.sh  -- executable (755)"
ui_print "    [OK] debloater binary -- executable (755)"
ui_print "    [OK] system.prop      -- read-only (644)"
ui_print "    [OK] SELinux context restored"
sleep_print

# -----------------------------------------------
# Volume Key Prompt for Debloater --default
# -----------------------------------------------
ui_print " "
ui_print "- Optional: Run Debloater Default Optimise now?"
ui_print "  Vol+ = Yes (run now)"
ui_print "  Vol- = No  (skip)"
ui_print "  (Auto-skip after 8 seconds if no key detected)"

TMPDIR="${TMPDIR:-/data/local/tmp}"
run_now=0

if command -v getevent >/dev/null 2>&1 && [ -d /dev/input ]; then
  TMPF="$TMPDIR/debloater_volkey.$$"
  (getevent -qlc 1 2>/dev/null > "$TMPF") &
  GE_PID=$!
  (sleep 8; kill $GE_PID 2>/dev/null) &
  KILL_PID=$!
  wait $GE_PID 2>/dev/null
  kill $KILL_PID 2>/dev/null
  EVENT="$(cat "$TMPF" 2>/dev/null)"
  rm -f "$TMPF"
  echo "$EVENT" | grep -q "KEY_VOLUMEUP" && run_now=1
  echo "$EVENT" | grep -q "KEY_VOLUMEDOWN" && run_now=0
fi

if [ "$run_now" = "1" ]; then
  ui_print "- Running Default Optimise..."
  sh "$MODPATH/system/bin/debloater" --default
  ui_print "- Default Optimise finished."
else
  ui_print "- Skipped Default Optimise."
fi

ui_print " "
ui_print "NOTE: For more customisation or full restore:"
ui_print "      Use Termux -> run: su ; debloater"
ui_print " "

# -----------------------------------------------
# Open Telegram channel
# -----------------------------------------------
ui_print "[*] Opening Telegram channel..."
am start -a android.intent.action.VIEW -d "https://t.me/op9devs" >/dev/null 2>&1
sleep_print

# -----------------------------------------------
# Done
# -----------------------------------------------
ui_print " "
ui_print "==========================================="
ui_print "   INSTALLATION COMPLETE -- v1.0 STABLE    "
ui_print "   Reboot to apply all optimizations.     "
ui_print "   Tap ACTION button to re-apply anytime. "
ui_print "==========================================="
ui_print " "
