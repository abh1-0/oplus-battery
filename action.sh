#!/system/bin/sh
# BatterySaver & Debloater v1.0 -- action.sh
# Runs when you tap the ACTION button in Magisk/KSU module list.
# Re-applies all optimizations on demand WITHOUT needing a reboot.
# ================================================

GPU_DEVFREQ="/sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali"
LOG="/data/local/tmp/batterysaver_action.log"
MODDIR="/data/adb/modules/combined_debloat_battery"
PROP_FILE="$MODDIR/module.prop"

line() { echo "--------------------------------------------"; }

write() {
    [ ! -f "$1" ] && return 1
    chmod +w "$1" 2>/dev/null
    echo "$2" > "$1" 2>/dev/null
}

update_ui() {
    STATUS_TEXT="$1"
    if [ -f "$PROP_FILE" ]; then
        sed -i "s/^author=.*/author=abh1 | $STATUS_TEXT/" "$PROP_FILE"
        am broadcast -a android.intent.action.CONFIGURATION_CHANGED >/dev/null 2>&1
    fi
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
    echo "  $name: ${alive} remaining after kill"
}

kill_logs() {
    for proc in midasd emdlogger mobile_log_d connsyslogger cam_log_server logd; do
        local pids=$(pgrep -f "$proc" 2>/dev/null)
        [ -n "$pids" ] && kill -9 $pids 2>/dev/null
    done
    echo "  [OK] Telemetry kill sweep done"
}

reset_bg_ops() {
    cmd appops set com.google.android.gms RUN_IN_BACKGROUND allow 2>/dev/null
    cmd appops set com.google.android.youtube RUN_IN_BACKGROUND allow 2>/dev/null
    cmd appops set com.facebook.katana RUN_IN_BACKGROUND allow 2>/dev/null
}

# ================================================

echo "============================================="
echo "  BatterySaver v1.0 -- MANUAL APPLY         "
echo "  $(date '+%H:%M:%S')                        "
echo "============================================="
echo ""

TOTAL_RAM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
if   [ "$TOTAL_RAM_MB" -ge 14000 ]; then RAM=16
elif [ "$TOTAL_RAM_MB" -ge 10000 ]; then RAM=12
elif [ "$TOTAL_RAM_MB" -ge 7000  ]; then RAM=8
elif [ "$TOTAL_RAM_MB" -ge 5000  ]; then RAM=6
elif [ "$TOTAL_RAM_MB" -ge 3500  ]; then RAM=4
else RAM=3
fi

# -- Step 1: Kill midasd --
echo "[1/12] Killing midasd daemon..."
setprop persist.sys.midasd.enable 0
setprop persist.sys.midasd.start  0
stop midasd 2>/dev/null
stop ostats_bds 2>/dev/null
stop vendor.oplus.hardware.cammidasservice-V1-service 2>/dev/null
kill_oplus_daemon "midasd"
kill_oplus_daemon "cammidasservice"
MIDAS_ALIVE=$(pgrep -f midasd 2>/dev/null | wc -l)
if [ "$MIDAS_ALIVE" -gt 0 ]; then
    echo "  [!] midasd still alive ($MIDAS_ALIVE procs after all attempts)"
else
    echo "  [OK] midasd KILLED"
fi

# -- Step 2: Keep oplus_gaia --
echo ""
echo "[2/12] Ensuring oplus_gaia is active..."
setprop persist.sys.oplus.gaia.enable 1
GAIA_ALIVE=$(pgrep -f oplus_gaia 2>/dev/null | wc -l)
echo "  [OK] oplus_gaia kept active ($GAIA_ALIVE procs running)"

# -- Step 3: Stop logger daemons + full sweep --
echo ""
echo "[3/12] Stopping logger/telemetry daemons..."
for svc in mobile_log_d emdlogger connsyslogger ostatsd ostats_pullerd \
           ostats_tpd logd auditd logcat logcatd tcpdump traced statsd; do
    stop "$svc" 2>/dev/null
done
stop vendor.oplus.hardware.ormsHalService-aidl-service 2>/dev/null
stop opluscvtmanager 2>/dev/null
stop oplus_kevent    2>/dev/null
kill_logs

# -- Step 4: GPU Governor --
echo ""
echo "[4/12] Fixing GPU governor..."
GPU_GOV_BEFORE=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
echo "  Before : $GPU_GOV_BEFORE"
if [ -d "$GPU_DEVFREQ" ]; then
    echo "simple_ondemand" > "${GPU_DEVFREQ}/governor" 2>/dev/null
    sleep 1
    GPU_GOV_AFTER=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
    if [ "$GPU_GOV_AFTER" = "dummy" ]; then
        echo "  [!] Still dummy -- trying powersave fallback + retry..."
        echo "powersave" > "${GPU_DEVFREQ}/governor" 2>/dev/null
        sleep 1
        echo "simple_ondemand" > "${GPU_DEVFREQ}/governor" 2>/dev/null
        sleep 1
        GPU_GOV_AFTER=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
    fi
    write "${GPU_DEVFREQ}/min_freq" 390000000
    write "${GPU_DEVFREQ}/max_freq" 1100000000
    echo "coarse_demand" > /sys/class/misc/mali0/device/power_policy 2>/dev/null
    GPU_CUR_FREQ=$(cat "${GPU_DEVFREQ}/cur_freq" 2>/dev/null)
    GPU_CUR_MHZ=$((GPU_CUR_FREQ / 1000000))
    if [ "$GPU_GOV_AFTER" = "dummy" ]; then
        echo "  [!] GPU still dummy after retry (SELinux blocked -- reboot will fix)"
    else
        echo "  [OK] After : $GPU_GOV_AFTER @ ${GPU_CUR_MHZ}MHz | policy=coarse_demand"
    fi
else
    echo "  [!] GPU devfreq path not accessible"
fi

# -- Step 5: CPU Caps + sugov_ext --
echo ""
echo "[5/12] Capping CPU frequencies..."
write /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 1500000
write /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq 1800000
write /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 1800000
for cpu_dir in /sys/devices/system/cpu/cpufreq/policy*/; do
    if [ -f "${cpu_dir}cpuinfo_min_freq" ]; then
        MIN=$(cat "${cpu_dir}cpuinfo_min_freq")
        write "${cpu_dir}scaling_min_freq" "$MIN"
    fi
    [ -f "${cpu_dir}sugov_ext/up_rate_limit_us" ] && \
        write "${cpu_dir}sugov_ext/up_rate_limit_us"   8000 && \
        write "${cpu_dir}sugov_ext/down_rate_limit_us" 2000
done
CPU0_MAX=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null)
echo "  [OK] LITTLE max: $((CPU0_MAX / 1000)) MHz | BIG max: 1800 MHz"

# -- Step 6: Throttle Wakeup Offenders + GMS --
echo ""
echo "[6/12] Throttling wakeup offenders + GMS background..."
reset_bg_ops
am set-standby-bucket com.radolyn.ayugram restricted          2>/dev/null
am set-standby-bucket com.google.android.gms restricted       2>/dev/null
am set-standby-bucket com.google.android.gsf restricted       2>/dev/null
am set-standby-bucket com.android.vending restricted          2>/dev/null
am set-standby-bucket com.google.android.configupdater rare   2>/dev/null
for pkg in com.google.android.gms com.google.android.gsf com.radolyn.ayugram; do
    cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore 2>/dev/null
    cmd appops set "$pkg" WAKE_LOCK ignore             2>/dev/null
done
cmd appops set com.whatsapp RUN_IN_BACKGROUND allow    2>/dev/null
settings put global power_mode 1                       2>/dev/null
echo "  [OK] Ayugram + GMS throttled | WhatsApp kept alive | power_mode=1"

# -- Step 7: Doze + WiFi/NTP + TCP --
echo ""
echo "[7/12] Applying Doze + WiFi/NTP + TCP tweaks..."
cmd deviceidle enable >/dev/null 2>&1
settings put global device_idle_constants \
"light_after_inactive_to=15000,light_pre_idle_to=30000,light_idle_to=60000,light_idle_maintenance_min_budget=30000,light_idle_maintenance_max_budget=60000,min_time_to_alarm=30000,inactive_to=120000,sensing_to=0,locating_to=0,motion_inactive_to=120000,idle_after_inactive_to=30000,idle_pending_to=30000,max_idle_pending_to=60000,idle_pending_factor=2.0,idle_to=900000,max_idle_to=21600000,idle_factor=2.0,max_temp_app_whitelist_duration=60000,mms_temp_app_whitelist_duration=30000,sms_temp_app_whitelist_duration=30000" \
2>/dev/null
settings put global wifi_scan_always_enabled 0          2>/dev/null
settings put global wifi_wakeup_enabled 0               2>/dev/null
settings put global auto_time 0                         2>/dev/null
settings put global auto_time_zone 0                    2>/dev/null
settings put global network_stats_poll_interval 7200000 2>/dev/null
write /proc/sys/net/ipv4/tcp_ecn              1
write /proc/sys/net/ipv4/tcp_fastopen        3
write /proc/sys/net/ipv4/tcp_no_metrics_save 1
echo "  [OK] Doze tightened | WiFi/NTP suppressed | TCP optimized"

# -- Step 8: RAM-adaptive VM tuning --
echo ""
echo "[8/12] Applying RAM-adaptive VM tuning (RAM=${RAM}GB)..."
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
echo "  [OK] swappiness=$SWAPPINESS | dirty_ratio set | vfs_cache_pressure=60"

# -- Step 9: I/O Scheduler --
echo ""
echo "[9/12] Applying I/O scheduler tweaks..."
for q in /sys/block/*/queue; do
    write "$q/read_ahead_kb" 128
    write "$q/iostats"       0
    write "$q/nr_requests"   64
    write "$q/nomerges"      0
    write "$q/add_random"    0
    write "$q/rotational"    0
    write "$q/rq_affinity"   1
done
SCHED_SET="none"
for s in /sys/block/*/queue/scheduler; do
    if write "$s" bfq 2>/dev/null; then SCHED_SET="bfq"
    else write "$s" cfq 2>/dev/null && SCHED_SET="cfq"
    fi
done
echo "  [OK] scheduler=$SCHED_SET | read_ahead=128KB | nr_requests=64 | iostats=0"

# -- Step 10: Kernel debug / printk / CRC disable --
echo ""
echo "[10/12] Disabling kernel debug, printk, CRC, ramdumps..."
for i in debug_mask log_level debug_level debug_mode enable_event_log \
          snapshot_crashdumper tracing_on mballoc_debug; do
    for o in $(find /sys/ -type f -name "$i" 2>/dev/null | head -15); do
        write "$o" 0
    done
done
write /sys/module/spurious/parameters/noirqdebug      1
write /proc/sys/debug/exception-trace                 0
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
echo "  [OK] printk off | debug masks cleared | CRC off | ramdumps off"

# -- Step 11: FS + battery module tweaks --
echo ""
echo "[11/12] Applying FS + battery module tweaks..."
write /proc/sys/fs/dir-notify-enable 0
write /sys/module/workqueue/parameters/power_efficient Y
write /sys/power/mem_sleep deep 2>/dev/null
echo "  [OK] dir-notify disabled | power_efficient workqueue=Y | mem_sleep=deep"

# -- Step 12: Status Report --
echo ""
echo "[12/12] Current status:"
BAT_TEMP=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
BAT_LVL=$(dumpsys battery 2>/dev/null | grep " level:" | awk '{print $2}')
[ -n "$BAT_TEMP" ] && echo "  Battery  : $((BAT_TEMP / 10)).$((BAT_TEMP % 10))C  |  Level: ${BAT_LVL}%"
GPU_GOV_NOW=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
GPU_MHZ_NOW=$(($(cat "${GPU_DEVFREQ}/cur_freq" 2>/dev/null) / 1000000))
echo "  GPU      : $GPU_GOV_NOW @ ${GPU_MHZ_NOW}MHz"
MIDAS_NOW=$(pgrep -f midasd 2>/dev/null | wc -l)
GAIA_NOW=$(pgrep -f oplus_gaia 2>/dev/null | wc -l)
echo "  midasd   : $MIDAS_NOW  |  gaia: $GAIA_NOW"
ACT_SWAP_NOW=$(cat /proc/sys/vm/swappiness 2>/dev/null)
echo "  RAM tier : ${RAM}GB  |  swappiness: $ACT_SWAP_NOW"
IO_SCHED=$(cat /sys/block/sda/queue/scheduler 2>/dev/null || cat /sys/block/mmcblk0/queue/scheduler 2>/dev/null)
echo "  I/O sched: $IO_SCHED"
echo ""
echo "============================================="
echo "  All 12 steps applied -- v1.0              "
echo "  Check battery temp in 5 min.             "
echo "============================================="

update_ui "OPTIMIZED v1.0"

{
    echo "Action run at $(date)"
    echo "midasd_alive=$MIDAS_NOW gaia_alive=$GAIA_NOW"
    echo "gpu_gov=$GPU_GOV_NOW gpu_mhz=$GPU_MHZ_NOW"
    echo "bat_temp=${BAT_TEMP} bat_level=${BAT_LVL}"
} > "$LOG"


# ================================================
# RUN DIAGNOSTICS
# ================================================

echo ""
line; echo "  DIAGNOSTICS -- BatterySaver v1.0"; line

# -- BATTERY --
line; echo " * BATTERY"; line
BAT_TEMP=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
BAT_LEVEL=$(dumpsys battery 2>/dev/null | grep " level:" | awk '{print $2}')
BAT_STATUS=$(dumpsys battery 2>/dev/null | grep " status:" | awk '{print $2}')
BAT_PLUGGED=$(dumpsys battery 2>/dev/null | grep "plugged:" | awk '{print $2}')
[ -n "$BAT_TEMP" ] && echo "  Temp    : $((BAT_TEMP / 10)).$((BAT_TEMP % 10))C"
echo "  Level   : ${BAT_LEVEL}%"
echo "  Status  : ${BAT_STATUS}  (2=charging, 3=discharging, 5=full)"
echo "  Plugged : ${BAT_PLUGGED}  (0=no, 1=AC, 2=USB)"
echo ""

# -- THERMAL ZONES --
line; echo " * THERMAL ZONES"; line
for z in /sys/class/thermal/thermal_zone*/; do
    tp=$(cat "${z}type" 2>/dev/null)
    tv=$(cat "${z}temp" 2>/dev/null)
    if [ -n "$tv" ] && [ "$tv" -gt 0 ] 2>/dev/null; then
        degC=$((tv / 1000))
        if [ "$degC" -ge 45 ]; then
            echo "  [HOT]  $tp : ${degC}C"
        elif [ "$degC" -ge 35 ]; then
            echo "  [WARM] $tp : ${degC}C"
        else
            echo "  [OK]   $tp : ${degC}C"
        fi
    fi
done
echo ""

# -- GPU STATE --
line; echo " * GPU STATE  [Mali-G57 2 cores -- 390MHz floor / 1100MHz ceiling]"; line
if [ -d "$GPU_DEVFREQ" ]; then
    GPU_GOV=$(cat "${GPU_DEVFREQ}/governor" 2>/dev/null)
    GPU_CUR=$(cat "${GPU_DEVFREQ}/cur_freq" 2>/dev/null)
    GPU_MIN=$(cat "${GPU_DEVFREQ}/min_freq" 2>/dev/null)
    GPU_MAX=$(cat "${GPU_DEVFREQ}/max_freq" 2>/dev/null)
    GPU_CUR_MHZ=$((GPU_CUR / 1000000))
    GPU_MIN_MHZ=$((GPU_MIN / 1000000))
    GPU_MAX_MHZ=$((GPU_MAX / 1000000))
    echo "  Governor : $GPU_GOV"
    [ "$GPU_GOV" = "dummy" ]       && echo "  [!] dummy = GPU PINNED AT FIXED FREQ (HEAT CAUSE)"
    [ "$GPU_GOV" = "performance" ] && echo "  [!] performance = GPU ALWAYS MAX (BAD for battery)"
    [ "$GPU_GOV" = "simple_ondemand" ] && echo "  [OK] Governor is battery-friendly"
    echo "  Cur Freq : ${GPU_CUR_MHZ} MHz  (floor=390 ceiling=1100)"
    echo "  Min Freq : ${GPU_MIN_MHZ} MHz  (should be 390)"
    echo "  Max Freq : ${GPU_MAX_MHZ} MHz  (should be 1100)"
    echo "  Power    : $(cat /sys/class/misc/mali0/device/power_policy 2>/dev/null)"
    GED_CUR=$(cat /sys/kernel/ged/hal/current_freqency 2>/dev/null)
    [ -n "$GED_CUR" ] && echo "  GED      : $GED_CUR  (opp_idx freq_khz)"
else
    echo "  GPU devfreq path not found"
fi
echo ""

# -- CPU STATE --
line; echo " * CPU FREQUENCIES"; line
for p in /sys/devices/system/cpu/cpufreq/policy*/; do
    pol=$(basename "$p")
    gov=$(cat "${p}scaling_governor"  2>/dev/null)
    cur=$(cat "${p}scaling_cur_freq"  2>/dev/null)
    max=$(cat "${p}scaling_max_freq"  2>/dev/null)
    echo "  $pol : gov=$gov  cur=$((cur/1000))MHz  max=$((max/1000))MHz"
done
echo ""

# -- MIDASD + GAIA STATUS --
line; echo " * MIDASD + GAIA DAEMONS"; line
echo "  persist.sys.midasd.enable = $(getprop persist.sys.midasd.enable 2>/dev/null)  (0=off OK)"
MIDAS_PROC=$(pgrep -f midasd 2>/dev/null | wc -l)
GAIA_PROC=$(pgrep -f oplus_gaia 2>/dev/null | wc -l)
[ "$MIDAS_PROC" -gt 0 ] && echo "  midasd     : $MIDAS_PROC  [!] STILL RUNNING" || echo "  midasd     : 0  [OK] KILLED"
[ "$GAIA_PROC"  -gt 0 ] && echo "  oplus_gaia : $GAIA_PROC  [OK] ACTIVE & HEALTHY" || echo "  oplus_gaia : 0  [!] NOT RUNNING"
echo ""

# -- VM STATE --
line; echo " * VM / MEMORY STATE"; line
echo "  swappiness       : $(cat /proc/sys/vm/swappiness 2>/dev/null)"
echo "  vfs_cache_pressure: $(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)"
echo "  dirty_ratio      : $(cat /proc/sys/vm/dirty_ratio 2>/dev/null)"
echo "  dirty_bg_ratio   : $(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null)"
echo ""

# -- I/O SCHEDULER --
line; echo " * I/O SCHEDULER"; line
for b in /sys/block/*/queue/scheduler; do
    blk=$(echo "$b" | cut -d'/' -f4)
    sched=$(cat "$b" 2>/dev/null)
    echo "  $blk : $sched"
done
echo ""

# -- GMS STANDBY BUCKETS --
line; echo " * GMS / APP STANDBY BUCKETS"; line
for pkg in com.google.android.gms com.google.android.gsf com.android.vending \
           com.radolyn.ayugram com.whatsapp com.instagram.android; do
    bucket=$(cmd appops get "$pkg" RUN_ANY_IN_BACKGROUND 2>/dev/null | head -1)
    echo "  $pkg : $bucket"
done
echo ""

# -- WAKEUP ALARM OFFENDERS --
line; echo " * TOP WAKEUP ALARM OFFENDERS"; line
dumpsys alarm 2>/dev/null | grep "wakeups:" | grep -v "0 wakeups:" | sort -t= -k2 -rn | head -15
echo ""

# -- DOZE STATE --
line; echo " * DOZE STATE"; line
dumpsys deviceidle 2>/dev/null | grep -E "mState|mLightState|mForceIdle|Idling"
echo ""

# -- SERVICE LOG --
line; echo " * LAST SERVICE.SH RUN LOG"; line
if [ -f /data/local/tmp/batterysaver_v10.log ]; then
    cat /data/local/tmp/batterysaver_v10.log
else
    echo "  No log yet. Module has not run since last boot."
fi
echo ""

echo "============================================="
echo "         DIAGNOSTICS COMPLETE               "
echo "============================================="
echo ""
echo "[ Notice: Auto-closing in 10 seconds... ]"
sleep 10
