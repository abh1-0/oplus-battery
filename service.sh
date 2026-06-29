#!/system/bin/sh
# ============================================================
# BatterySaver & Debloater v1.0 -- service.sh
# Runs on every boot after boot_completed + 25s settle time.
# ============================================================

MODDIR=${0%/*}
MID="combined_debloat_battery"

# ================================================
# Part 1: Debloater Universal Launcher Setup
# ================================================
CANDIDATES="
/data/adb/modules/${MID}
/data/adb/ksu/modules/${MID}
/data/adb/apatch/modules/${MID}
"

BIN_DIRS="
/data/adb/ksu/bin
/data/adb/ap/bin
/data/adb/magisk
/data/local/bin
"

write_launcher() {
  DEST="$1"
  [ -z "$DEST" ] && return 1
  mkdir -p "$(dirname "$DEST")" 2>/dev/null
  cat > "$DEST" <<EOF_LAUNCH
#!/system/bin/sh
# Debloater universal launcher
MID="${MID}"

# 1) If mounted to /system/bin (Magisk / overlayfs metamodule)
if [ -x /system/bin/debloater ]; then
  exec /system/bin/debloater "\$@"
fi

# 2) Magisk-style module path
if [ -x "/data/adb/modules/\${MID}/system/bin/debloater" ]; then
  exec "/data/adb/modules/\${MID}/system/bin/debloater" "\$@"
fi

# 3) KernelSU / KSU Next style module path
if [ -x "/data/adb/ksu/modules/\${MID}/system/bin/debloater" ]; then
  exec "/data/adb/ksu/modules/\${MID}/system/bin/debloater" "\$@"
fi

# 4) APatch style module path (best-effort)
if [ -x "/data/adb/apatch/modules/\${MID}/system/bin/debloater" ]; then
  exec "/data/adb/apatch/modules/\${MID}/system/bin/debloater" "\$@"
fi

# 5) Fallback copy created by module boot scripts
if [ -x "/data/local/tmp/debloater" ]; then
  exec "/data/local/tmp/debloater" "\$@"
fi

echo "Debloater launcher: debloater not found."
echo "Try running one of these directly:"
echo "  /data/adb/modules/\${MID}/system/bin/debloater"
echo "  /data/adb/ksu/modules/\${MID}/system/bin/debloater"
echo "  /data/local/tmp/debloater"
exit 127

EOF_LAUNCH
  chmod 0755 "$DEST" 2>/dev/null
}

for D in $CANDIDATES; do
  BIN="$D/system/bin/debloater"
  if [ -f "$BIN" ]; then
    chmod 0755 "$BIN" 2>/dev/null
    cp "$BIN" /data/local/tmp/debloater 2>/dev/null
    chmod 0755 /data/local/tmp/debloater 2>/dev/null
  fi
done

for BD in $BIN_DIRS; do
  if [ -d "$BD" ]; then
    write_launcher "$BD/debloater"
  fi
done

if [ -f /system/bin/debloater ]; then
  chmod 0755 /system/bin/debloater 2>/dev/null
fi

# ================================================
# Part 2: Wait for full boot + 25s settle for Battery Saver
# ================================================
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done
sleep 25

LOG="/data/local/tmp/batterysaver_v10.log"
PROP_FILE="$MODDIR/module.prop"
GPU_DEVFREQ="/sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali"

echo "=== BatterySaver v1.0 started at $(date) ===" > "$LOG"

write() {
    [ ! -f "$1" ] && return 1
    chmod +w "$1" 2>/dev/null
    if ! echo "$2" > "$1" 2>/dev/null; then
        echo "  write failed: $1 -> $2" >> "$LOG"
        return 1
    fi
}

kill_logs() {
    for proc in midasd emdlogger mobile_log_d connsyslogger cam_log_server logd; do
        pids=$(pgrep -f "$proc" 2>/dev/null)
        [ -n "$pids" ] && kill -9 $pids 2>/dev/null
    done
    echo "$(date) -- TELEMETRY KILL SWEEP DONE" >> "$LOG"
}

kill_oplus_daemon() {
    local name="$1"
    stop "$name" 2>/dev/null
    local pids=$(pgrep -f "$name" 2>/dev/null)
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null
    sleep 1
    pkill -9 -f "$name" 2>/dev/null
    killall -STOP "$name" 2>/dev/null
    local alive=$(pgrep -f "$name" 2>/dev/null | wc -l)
    echo "  $name: ${alive} instance(s) remain after kill" >> "$LOG"
}

update_ksu_ui() {
    STATUS_TEXT="$1"
    if [ -f "$PROP_FILE" ]; then
        sed -i "s/^author=.*/author=abh1 | $STATUS_TEXT/" "$PROP_FILE"
        am broadcast -a android.intent.action.CONFIGURATION_CHANGED >/dev/null 2>&1
    fi
}

TOTAL_RAM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
if   [ "$TOTAL_RAM_MB" -ge 14000 ]; then RAM=16
elif [ "$TOTAL_RAM_MB" -ge 10000 ]; then RAM=12
elif [ "$TOTAL_RAM_MB" -ge 7000  ]; then RAM=8
elif [ "$TOTAL_RAM_MB" -ge 5000  ]; then RAM=6
elif [ "$TOTAL_RAM_MB" -ge 3500  ]; then RAM=4
else RAM=3
fi
echo "[RAM] Detected: ${TOTAL_RAM_MB}MB -> tier=${RAM}GB" >> "$LOG"

# ================================================
# SECTION 1 -- Stop Native Logger/Telemetry Daemons
# ================================================
for svc in mobile_log_d emdlogger connsyslogger "oplus.hardware.olc-2-0" \
           ostatsd ostats_pullerd ostats_tpd logd auditd \
           logcat logcatd tcpdump cnss_diag statsd traced \
           idd-logreader idd-logreadermain stats dumpstate aplogd \
           vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    stop "$svc" 2>/dev/null
done
kill_logs
echo "[1] Logger/telemetry daemons stopped" >> "$LOG"

# ================================================
# SECTION 2 -- Kill midasd NATIVE DAEMON
# ================================================
setprop persist.sys.midasd.enable 0
setprop persist.sys.midasd.start  0
stop midasd 2>/dev/null
stop ostats_bds 2>/dev/null
stop vendor.oplus.hardware.cammidasservice-V1-service 2>/dev/null
kill_oplus_daemon "midasd"
kill_oplus_daemon "cammidasservice"
MIDAS_LEFT=$(pgrep -f midasd 2>/dev/null | wc -l)
echo "[2] midasd kill done. Remaining: $MIDAS_LEFT" >> "$LOG"

# ================================================
# SECTION 3 -- Keep oplus_gaia (Retained for AI & Circle to Search)
# ================================================
setprop persist.sys.oplus.gaia.enable 1
GAIA_LEFT=$(pgrep -f oplus_gaia 2>/dev/null | wc -l)
echo "[3] oplus_gaia preserved perfectly. Active: $GAIA_LEFT" >> "$LOG"

# ================================================
# SECTION 4 -- Disable APK Bloat (telemetry + OTA + AI)
# ================================================
PM_DISABLE_LIST="
  com.debug.loggerui
  com.oplus.olc
  com.oplus.sau
  com.oplus.romupdate
  com.nearme.instant.platform
  com.oplus.appsense
  com.oplus.crashbox
  com.oplus.healthservice
  com.oplus.logkit
  com.oplus.onetrace
  com.oplus.powermonitor
  com.oplus.sauhelper
  com.oplus.appbooster
  com.oplus.deepthinker
  com.oplus.dfs
  com.android.mms.service
  com.coloros.assistantscreen
  com.oplus.tingle
  com.oplus.qualityprotect
  com.oplus.midas
"
for pkg in $PM_DISABLE_LIST; do
    pm disable --user 0 "$pkg" 2>/dev/null
done
echo "[4] APK bloat disabled" >> "$LOG"

# ================================================
# SECTION 4.1 -- Disable Google Analytics/Ads Services
# ================================================
for svc in \
    "com.google.android.gms/.ads.AdRequestBrokerService" \
    "com.google.android.gms/.ads.identifier.service.AdvertisingIdService" \
    "com.google.android.gms/.ads.measurement.GmpConversionTrackingBrokerService" \
    "com.google.android.gms/.analytics.AnalyticsService" \
    "com.google.android.gms/.analytics.AnalyticsTaskService" \
    "com.google.android.gms/.analytics.internal.PlayLogReportingService" \
    "com.google.android.gms/.analytics.service.AnalyticsService" \
    "com.google.android.gms/.checkin.EventLogService" \
    "com.google.android.gms/.clearcut.debug.ClearcutDebugDumpService" \
    "com.google.android.gms/.common.stats.GmsCoreStatsService" \
    "com.google.android.gms/.common.stats.StatsUploadService" \
    "com.google.android.gms/.feedback.LegacyBugReportService" \
    "com.google.android.gms/.measurement.AppMeasurementJobService" \
    "com.google.android.gms/.measurement.AppMeasurementService" \
    "com.google.android.gms/.measurement.service.MeasurementBrokerService" \
    "com.google.android.gms/.stats.PlatformStatsCollectorService" \
    "com.google.android.gms/.stats.eastworld.EastworldService" \
    "com.google.android.gms/.tron.CollectionService" \
    "com.google.android.gms/.usagereporting.service.UsageReportingIntentService" \
    "com.android.vending/com.google.android.finsky.enterprisedevicereport.AppStatesService" \
    "com.android.webview/org.chromium.android_webview.services.MetricsBridgeService" \
    "com.android.webview/org.chromium.android_webview.services.MetricsUploadService"; do
    pkg="${svc%/*}"
    if pm list packages 2>/dev/null | grep -q "$pkg"; then
        pm disable "$svc" 2>/dev/null
    fi
done
echo "[4.1] Google analytics/ads services disabled" >> "$LOG"

# ================================================
# SECTION 4.2 -- Re-enable Network/Gaming Apps
# ================================================
for pkg in com.oplus.nas com.oplus.nhs com.oplus.trafficmonitor \
           com.oplus.wirelesssettings com.oplus.gameopt; do
    pm enable --user 0 "$pkg" 2>/dev/null
done
echo "[4.2] Network and gaming apps re-enabled" >> "$LOG"

# ================================================
# SECTION 5 -- Kill/Stop extra Oplus HAL services
# ================================================
stop vendor.oplus.hardware.ormsHalService-aidl-service  2>/dev/null
stop vendor-oplus-hardware-performance-V1-service        2>/dev/null
stop opluscvtmanager                                     2>/dev/null
stop oplus_kevent                                        2>/dev/null
echo "[5] Oplus HAL services reduced" >> "$LOG"

# ================================================
# SECTION 6 -- GPU Governor Fix
# ================================================
if [ -d "$GPU_DEVFREQ" ]; then
    echo "simple_ondemand" > "${GPU_DEVFREQ}/governor" 2>/dev/null
    sleep 1
    GOV_NOW=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
    if [ "$GOV_NOW" = "dummy" ]; then
        echo "powersave" > "${GPU_DEVFREQ}/governor" 2>/dev/null
        sleep 1
        echo "simple_ondemand" > "${GPU_DEVFREQ}/governor" 2>/dev/null
        sleep 1
        GOV_NOW=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
    fi
    echo 390000000  > "${GPU_DEVFREQ}/min_freq" 2>/dev/null
    echo 1100000000 > "${GPU_DEVFREQ}/max_freq" 2>/dev/null
    echo "[6] GPU gov=$GOV_NOW min=390MHz max=1100MHz" >> "$LOG"
else
    echo "[6] GPU devfreq path not found" >> "$LOG"
fi
echo "coarse_demand" > /sys/class/misc/mali0/device/power_policy 2>/dev/null

# ================================================
# SECTION 7 -- CPU Frequency Caps + sugov_ext tuning
# ================================================
for cpu_dir in /sys/devices/system/cpu/cpufreq/policy*/; do
    if [ -f "${cpu_dir}sugov_ext/up_rate_limit_us" ]; then
        write "${cpu_dir}sugov_ext/up_rate_limit_us"   8000
        write "${cpu_dir}sugov_ext/down_rate_limit_us" 2000
    fi
    if [ -f "${cpu_dir}cpuinfo_min_freq" ]; then
        MIN=$(cat "${cpu_dir}cpuinfo_min_freq")
        write "${cpu_dir}scaling_min_freq" "$MIN"
    fi
done
write /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 1500000
write /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq 1800000
write /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 1800000
sleep 2
write /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 1500000
write /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq 1800000
write /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 1800000
echo "[7] CPU caps applied" >> "$LOG"

# ================================================
# SECTION 8 -- Disable & Throttle BG Offenders
# ================================================
am set-standby-bucket com.instagram.android restricted       2>/dev/null
cmd appops set com.instagram.android RUN_ANY_IN_BACKGROUND ignore 2>/dev/null
cmd appops set com.instagram.android WAKE_LOCK ignore             2>/dev/null

am set-standby-bucket com.radolyn.ayugram restricted         2>/dev/null
cmd appops set com.radolyn.ayugram RUN_ANY_IN_BACKGROUND ignore   2>/dev/null
cmd appops set com.radolyn.ayugram WAKE_LOCK ignore               2>/dev/null

am set-standby-bucket com.google.android.gms restricted      2>/dev/null
am set-standby-bucket com.google.android.gsf restricted      2>/dev/null
am set-standby-bucket com.android.vending restricted         2>/dev/null
am set-standby-bucket com.google.android.configupdater rare  2>/dev/null
for pkg in com.google.android.gms com.google.android.gsf; do
    cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore 2>/dev/null
    cmd appops set "$pkg" WAKE_LOCK ignore              2>/dev/null
done

am set-standby-bucket com.jio.myjio rare                     2>/dev/null

# Keep alive (needed for normal use)
cmd appops set com.whatsapp RUN_IN_BACKGROUND allow           2>/dev/null
cmd appops set com.google.android.youtube RUN_IN_BACKGROUND allow 2>/dev/null
settings put global power_mode 1                             2>/dev/null
echo "[8] BG offenders throttled" >> "$LOG"

# ================================================
# SECTION 9 -- Doze Settings
# ================================================
settings put global device_idle_constants \
"light_after_inactive_to=15000,light_pre_idle_to=30000,light_idle_to=60000,light_idle_maintenance_min_budget=30000,light_idle_maintenance_max_budget=60000,min_time_to_alarm=30000,inactive_to=120000,sensing_to=0,locating_to=0,motion_inactive_to=120000,idle_after_inactive_to=30000,idle_pending_to=30000,max_idle_pending_to=60000,idle_pending_factor=2.0,idle_to=900000,max_idle_to=21600000,idle_factor=2.0,max_temp_app_whitelist_duration=60000,mms_temp_app_whitelist_duration=30000,sms_temp_app_whitelist_duration=30000" \
2>/dev/null
dumpsys deviceidle enable 2>/dev/null
echo "[9] Doze configured" >> "$LOG"

# ================================================
# SECTION 10 -- WiFi / NTP Wakeup Reduction
# ================================================
settings put global wifi_scan_always_enabled 0       2>/dev/null
settings put global wifi_wakeup_enabled 0            2>/dev/null
settings put global auto_time 0                      2>/dev/null
settings put global auto_time_zone 0                 2>/dev/null
settings put global network_stats_poll_interval 7200000 2>/dev/null
echo "[10] WiFi/NTP wakeups reduced" >> "$LOG"

# ================================================
# SECTION 11 -- Thermal HAL Polling Reduction
# ================================================
setprop vendor.thermal.config thermal_info_config_disable.json 2>/dev/null || true
for z in 0 1 2 3 4 5; do
    node="/sys/class/thermal/thermal_zone${z}/polling_delay"
    [ -f "$node" ] && write "$node" 5000
done
echo "[11] Thermal polling reduced" >> "$LOG"

# ================================================
# SECTION 12 -- Logger Sysprops
# ================================================
setprop persist.sys.debuglog.config ""
setprop persist.vendor.aee.log.status 0
setprop persist.vendor.aeev.log.status 0
setprop persist.sys.log.tcpdump 0
setprop persist.sys.log.main 0
setprop persist.sys.log.kernel 0
setprop persist.sys.log.radio 0
setprop persist.sys.log.user 0
setprop persist.sys.oppo.junklog false
setprop debug.atrace.tags.enableflags 0
setprop profiler.debugmonitor false
echo "[12] Logger sysprops silenced" >> "$LOG"

# ================================================
# SECTION 13 -- Kernel VM Tuning (RAM-adaptive)
# ================================================
if   [ "$RAM" -le 3 ]; then
    write /proc/sys/vm/dirty_writeback_centisecs 500
    write /proc/sys/vm/dirty_expire_centisecs    200
    write /proc/sys/vm/dirty_ratio              10
    write /proc/sys/vm/dirty_background_ratio   5
    SWAPPINESS=100
elif [ "$RAM" -eq 4 ]; then
    write /proc/sys/vm/dirty_writeback_centisecs 500
    write /proc/sys/vm/dirty_expire_centisecs    3000
    write /proc/sys/vm/dirty_ratio              15
    write /proc/sys/vm/dirty_background_ratio   10
    SWAPPINESS=60
elif [ "$RAM" -eq 6 ]; then
    write /proc/sys/vm/dirty_writeback_centisecs 500
    write /proc/sys/vm/dirty_expire_centisecs    3000
    write /proc/sys/vm/dirty_ratio              30
    write /proc/sys/vm/dirty_background_ratio   15
    SWAPPINESS=40
else
    write /proc/sys/vm/dirty_writeback_centisecs 1500
    write /proc/sys/vm/dirty_expire_centisecs    1500
    write /proc/sys/vm/dirty_ratio              50
    write /proc/sys/vm/dirty_background_ratio   10
    SWAPPINESS=20
fi
write /proc/sys/vm/vfs_cache_pressure    60
write /proc/sys/vm/stat_interval         10
write /proc/sys/vm/page-cluster          0
write /proc/sys/vm/panic_on_oom          0
write /proc/sys/vm/oom_kill_allocating_task 0
write /proc/sys/vm/oom_dump_tasks        0
write /proc/sys/vm/block_dump            0
write /proc/sys/vm/laptop_mode           0
ACT_SWAP=$(cat /proc/sys/vm/swappiness 2>/dev/null)
[ "$ACT_SWAP" != "$SWAPPINESS" ] && write /proc/sys/vm/swappiness "$SWAPPINESS"
write /proc/sys/kernel/sched_schedstats 0
echo "[13] Kernel VM tuned (RAM=${RAM}GB swappiness=${SWAPPINESS})" >> "$LOG"

# ================================================
# SECTION 14 -- I/O Scheduler Tuning
# ================================================
for q in /sys/block/*/queue; do
    write "$q/read_ahead_kb" 128
    write "$q/iostats"       0
    write "$q/nr_requests"   64
    write "$q/nomerges"      0
    write "$q/add_random"    0
    write "$q/rotational"    0
    write "$q/rq_affinity"   1
done
for s in /sys/block/*/queue/scheduler; do
    if ! write "$s" bfq 2>/dev/null; then
        write "$s" cfq 2>/dev/null
    fi
done
echo "[14] I/O scheduler tuned" >> "$LOG"

# ================================================
# SECTION 15 -- Network / TCP Tuning
# ================================================
write /proc/sys/net/ipv4/tcp_ecn              1
write /proc/sys/net/ipv4/tcp_fastopen        3
write /proc/sys/net/ipv4/tcp_syncookies      0
write /proc/sys/net/ipv4/tcp_no_metrics_save 1
echo "[15] TCP/network tuned" >> "$LOG"

# ================================================
# SECTION 16 -- Kernel Debug / Trace Disable
# ================================================
for i in debug_mask log_level debug_level debug_mode enable_event_log \
          snapshot_crashdumper tracing_on mballoc_debug; do
    for o in $(find /sys/ -type f -name "$i" 2>/dev/null | head -20); do
        write "$o" 0
    done
done
write /sys/module/spurious/parameters/noirqdebug      1
write /proc/sys/debug/exception-trace                 0
write /proc/sys/kernel/sched_schedstats               0
write /proc/sys/kernel/sched_child_runs_first         0
write /proc/sys/kernel/sched_autogroup_enabled        1
write /proc/sys/kernel/sched_tunable_scaling          0
write /proc/sys/kernel/hung_task_timeout_secs         0
write /proc/sys/kernel/perf_cpu_time_max_percent      5
write /proc/sys/kernel/timer_migration                1
write /proc/sys/kernel/sched_min_task_util_for_colocation 0
write /proc/sys/kernel/printk         "0 0 0 0"
write /proc/sys/kernel/printk_devkmsg off
write /sys/module/mmc_core/parameters/crc         0
write /sys/module/mmc_core/parameters/use_spi_crc 0
write /sys/module/subsystem_restart/parameters/enable_mini_ramdumps 0
write /sys/module/subsystem_restart/parameters/enable_ramdumps      0
for q in /sys/block/*/queue; do write "$q/iostats" 0; done
write /proc/sys/vm/oom_dump_tasks 0
write /proc/sys/vm/block_dump     0
echo "[16] Kernel debug/trace/printk disabled" >> "$LOG"

# ================================================
# SECTION 17 -- File System / Battery Module tweaks
# ================================================
write /proc/sys/fs/dir-notify-enable 0
write /sys/module/workqueue/parameters/power_efficient Y
write /sys/power/mem_sleep deep 2>/dev/null
echo "[17] FS + battery module tweaks applied" >> "$LOG"

# ================================================
# SECTION 18 -- Final verification snapshot
# ================================================
{
    echo ""
    echo "=== FINAL STATE at $(date) ==="
    echo "Battery temp: $(cat /sys/class/power_supply/battery/temp 2>/dev/null) (x0.1=C)"
    echo "GPU governor: $(cat ${GPU_DEVFREQ}/governor 2>/dev/null)"
    echo "GPU cur_freq: $(cat ${GPU_DEVFREQ}/cur_freq 2>/dev/null)"
    echo "CPU0 max: $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null)"
    echo "midasd alive: $(pgrep -f midasd 2>/dev/null | wc -l)"
    echo "oplus_gaia alive: $(pgrep -f oplus_gaia 2>/dev/null | wc -l)"
    echo "power_mode: $(settings get global power_mode 2>/dev/null)"
    echo "swappiness: $(cat /proc/sys/vm/swappiness 2>/dev/null)"
    echo "RAM tier: ${RAM}GB"
    echo "Doze: $(dumpsys deviceidle 2>/dev/null | grep -E 'mState|mLightState')"
} >> "$LOG"
echo "=== Done ===" >> "$LOG"

# ================================================
# SECTION 19 -- Freeze OPlus Daemons (SIGSTOP)
# ================================================
echo "Freezing OPlus Daemons with SIGSTOP..." >> "$LOG"
for daemon in midasd \
    vendor.oplus.hardware.cammidasservice-V1-service \
    emdlogger mobile_log_d connsyslogger \
    ostatsd ostats_pullerd ostats_tpd \
    opluscvtmanager phoenix_log_manager; do
    killall -STOP "$daemon" 2>/dev/null
done
echo "[19] OPlus daemons frozen" >> "$LOG"

# ================================================
# SECTION 20 -- Update KSU/Magisk UI status
# ================================================
update_ksu_ui "OPTIMIZED v1.0"
