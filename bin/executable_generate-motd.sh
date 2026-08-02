#!/usr/bin/env bash

# Colors
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Configuration defaults
FIGLET_FONT="${FIGLET_FONT:-Poison}"
HOSTNAME_TEXT="${HOSTNAME_TEXT:-$(hostname)}"
SHOW_VERSION="${SHOW_VERSION:-1}"
SHOW_SYSTEM_LOAD="${SHOW_SYSTEM_LOAD:-1}"
SHOW_MEMORY="${SHOW_MEMORY:-1}"
SHOW_DISK="${SHOW_DISK:-1}"
STORAGE_AUTO_DETECT="${STORAGE_AUTO_DETECT:-1}"
DISK_WARN_THRESHOLD="${DISK_WARN_THRESHOLD:-80}"
DISK_CRIT_THRESHOLD="${DISK_CRIT_THRESHOLD:-90}"

label() {
    echo -e "${BOLD}${1}${RESET}"
}

get_percentage_color() {
    local value=$1
    local warn=$2
    local crit=$3

    if [ "$value" -ge "$crit" ]; then
        echo -e "${RED}"
    elif [ "$value" -ge "$warn" ]; then
        echo -e "${YELLOW}"
    else
        echo -e "${GREEN}"
    fi
}

# ~/bin font wins over /usr/local/share/figlet
if [ -f "$HOME/bin/${FIGLET_FONT}.flf" ]; then
    FIGLET_FONT_PATH="$HOME/bin/${FIGLET_FONT}.flf"
elif [ -f "/usr/local/share/figlet/${FIGLET_FONT}.flf" ]; then
    FIGLET_FONT_PATH="/usr/local/share/figlet/${FIGLET_FONT}.flf"
else
    FIGLET_FONT_PATH="$FIGLET_FONT"
fi

echo -e "${CYAN}"
figlet -f "$FIGLET_FONT_PATH" "$HOSTNAME_TEXT" 2>/dev/null || echo "$HOSTNAME_TEXT"
echo -e "${RESET}"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# System Information
if [ "$SHOW_VERSION" = "1" ]; then
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        echo -e "  $(label "System:") ${PRETTY_NAME:-FreeBSD}"
    else
        echo -e "  $(label "System:") $(uname -s) $(uname -r)"
    fi
    echo -e "  $(label "Kernel:") $(uname -r)"
    echo ""
fi

# Uptime
UPTIME_RAW=$(uptime)
UPTIME=$(echo "$UPTIME_RAW" | sed -E 's/.*up ([^,]+),.*/\1/' | xargs)
echo -e "  $(label "Uptime:") $UPTIME"

if [ "$SHOW_SYSTEM_LOAD" = "1" ]; then
    LOAD=$(echo "$UPTIME_RAW" | sed -E 's/.*load averages?: (.*)/\1/' | xargs)
    LOAD_1=$(echo "$LOAD" | cut -d',' -f1 | cut -d' ' -f1)

    if command -v nproc &>/dev/null; then
        CPU_CORES=$(nproc)
    elif sysctl -n hw.ncpu &>/dev/null; then
        CPU_CORES=$(sysctl -n hw.ncpu)
    else
        CPU_CORES=1
    fi

    LOAD_PCT=$(awk -v loadavg="$LOAD_1" -v cores="$CPU_CORES" 'BEGIN {printf "%.0f", (loadavg/cores)*100}')

    if [ -n "$LOAD_PCT" ]; then
        LOAD_COLOR=$(get_percentage_color "$LOAD_PCT" 70 90)
    else
        LOAD_COLOR="${GREEN}"
    fi

    echo -e "  $(label "Load:") ${LOAD_COLOR}${LOAD}${RESET} (${CPU_CORES} cores)"
fi

echo ""

# Memory Usage
if [ "$SHOW_MEMORY" = "1" ]; then
    if command -v free &>/dev/null; then
        MEM_INFO=$(free -h | awk 'NR==2{print $3"/"$2}')
        MEM_PERCENT=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    else
        # FreeBSD fallback using sysctl
        total_mem=$(sysctl -n hw.physmem 2>/dev/null || echo 0)
        if [ "$total_mem" -gt 0 ]; then
            page_size=$(sysctl -n vm.stats.vm.v_page_size)
            free_pages=$(sysctl -n vm.stats.vm.v_free_count)
            inactive_pages=$(sysctl -n vm.stats.vm.v_inactive_count)
            free_mem=$(( (free_pages + inactive_pages) * page_size ))
            used_mem=$(( total_mem - free_mem ))
            MEM_PERCENT=$(( used_mem * 100 / total_mem ))

            used_gb=$(awk -v b="$used_mem" 'BEGIN {printf "%.1fG", b/1024/1024/1024}')
            total_gb=$(awk -v b="$total_mem" 'BEGIN {printf "%.1fG", b/1024/1024/1024}')
            MEM_INFO="${used_gb}/${total_gb}"
        else
            MEM_INFO="N/A"
            MEM_PERCENT=0
        fi
    fi

    if [ -n "$MEM_PERCENT" ]; then
        MEM_COLOR=$(get_percentage_color "$MEM_PERCENT" 70 90)
    else
        MEM_COLOR="${GREEN}"
    fi

    echo -e "  $(label "Memory:") ${MEM_COLOR}${MEM_INFO}${RESET} (${MEM_PERCENT}%)"
fi

# Storage Usage
if [ "$SHOW_DISK" = "1" ]; then
    STORAGE_SHOWN=0

    show_mount() {
        local mount_point="$1"
        local prefix="$2"
        local mount_label="$3"

        if ! df "$mount_point" &>/dev/null; then
            return
        fi

        local info used total percent
        info=$(df -h "$mount_point" 2>/dev/null | awk 'NR==2{print $3,$2,$5}')
        used=$(echo "$info" | awk '{print $1}')
        total=$(echo "$info" | awk '{print $2}')
        percent=$(echo "$info" | awk '{print $3}' | sed 's/%//')

        if [ -z "$percent" ]; then
            return
        fi

        local color
        color=$(get_percentage_color "$percent" "$DISK_WARN_THRESHOLD" "$DISK_CRIT_THRESHOLD")

        if [ -n "$mount_label" ]; then
            echo -e "  ${prefix}${mount_label}  ${color}${used}${RESET} / ${total} (${percent}%)"
        else
            echo -e "  ${prefix}${mount_point}  ${color}${used}${RESET} / ${total} (${percent}%)"
        fi
    }

    # ZFS Detection
    if [ "$STORAGE_AUTO_DETECT" = "1" ] && command -v zpool &>/dev/null; then
        ZPOOLS=$(zpool list -H -o name 2>/dev/null)
        if [ -n "$ZPOOLS" ]; then
            echo -e "  $(label "Storage (ZFS):")"
            while IFS= read -r pool; do
                [ -z "$pool" ] && continue
                pool_info=$(zpool list -H -o name,size,alloc,cap,health "$pool" 2>/dev/null)
                if [ -n "$pool_info" ]; then
                    pool_name=$(echo "$pool_info" | awk '{print $1}')
                    pool_size=$(echo "$pool_info" | awk '{print $2}')
                    pool_alloc=$(echo "$pool_info" | awk '{print $3}')
                    pool_cap=$(echo "$pool_info" | awk '{print $4}' | sed 's/%//')
                    pool_health=$(echo "$pool_info" | awk '{print $5}')

                    health_color="${GREEN}"
                    if [ "$pool_health" = "DEGRADED" ]; then
                        health_color="${YELLOW}"
                    elif [ "$pool_health" != "ONLINE" ]; then
                        health_color="${RED}"
                    fi

                    cap_color=$(get_percentage_color "$pool_cap" "$DISK_WARN_THRESHOLD" "$DISK_CRIT_THRESHOLD")
                    echo -e "    ${BOLD}${pool_name}${RESET}  ${cap_color}${pool_alloc}${RESET} / ${pool_size} (${pool_cap}%)  ${health_color}${pool_health}${RESET}"

                    # / first, then alpha
                    zfs list -H -o name,used,avail,mountpoint,mounted -t filesystem -r "$pool" 2>/dev/null | \
                    while IFS=$'\t' read -r ds_name ds_used ds_avail ds_mount ds_mounted; do
                        [ "$ds_name" = "$pool" ] && continue

                        [ "$ds_mount" = "none" ] && continue
                        [ "$ds_mount" = "-" ] && continue
                        [ "$ds_mounted" = "no" ] && continue

                        # legacy mounts: mountpoint property is not the real path
                        if [ "$ds_mount" = "legacy" ]; then
                            ds_mount=$(mount | grep -E "^$ds_name on " | awk '{print $3}')
                            [ -z "$ds_mount" ] && continue
                        fi

                        # skip sub-paths
                        case "$ds_mount" in
                            /home/*/.*|/persist/home/*/.*|/var/lib/*|/usr/ports*|/usr/src*|/var/audit*|/var/crash*|/home) continue ;;
                        esac

                        ds_used_bytes=$(zfs get -Hp -o value used "$ds_name" 2>/dev/null)
                        ds_avail_bytes=$(zfs get -Hp -o value available "$ds_name" 2>/dev/null)
                        if [ -n "$ds_used_bytes" ] && [ -n "$ds_avail_bytes" ] && [ "$ds_avail_bytes" -gt 0 ]; then
                            ds_total=$((ds_used_bytes + ds_avail_bytes))
                            ds_pct=$((ds_used_bytes * 100 / ds_total))
                            # sort key: 0=/ 1=rest
                            if [ "$ds_mount" = "/" ]; then
                                echo -e "0\t${ds_mount}\t${ds_used}\t${ds_pct}"
                            else
                                echo -e "1\t${ds_mount}\t${ds_used}\t${ds_pct}"
                            fi
                        fi
                    done | sort -t$'\t' -k1,1n -k2,2 | while IFS=$'\t' read -r _ ds_mount ds_used ds_pct; do
                        ds_color=$(get_percentage_color "$ds_pct" "$DISK_WARN_THRESHOLD" "$DISK_CRIT_THRESHOLD")
                        echo -e "      ${ds_mount}  ${ds_color}${ds_used}${RESET} (${ds_pct}%)"
                    done
                fi
            done <<< "$ZPOOLS"
            STORAGE_SHOWN=1
        fi
    fi

    if [ "$STORAGE_SHOWN" = "0" ]; then
        echo -e "  $(label "Storage:")"
        show_mount "/" "    " ""
    fi
fi

echo ""

# Active Users
USERS=$(who | cut -d' ' -f1 | sort -u | wc -l)
if [ "$USERS" -gt 0 ]; then
    echo -e "  $(label "Active users:") $USERS"
    echo ""
fi

# Last login
if [ -n "$USER" ]; then
    if command -v lastlog &> /dev/null; then
        LAST_LOGIN=$(lastlog -u "$USER" 2>/dev/null | tail -n 1 | awk '{if ($2 != "**") print $4,$5,$6,$7,$9}')
    else
        # FreeBSD fallback (second entry is previous login)
        LAST_LOGIN=$(last -n 2 "$USER" | head -n 2 | tail -n 1 | awk '{print $3, $4, $5, $6, $7}')
    fi
    if [ -n "$LAST_LOGIN" ] && [[ "$LAST_LOGIN" != *"still logged in"* ]]; then
        echo -e "  $(label "Last login:") $LAST_LOGIN"
        echo ""
    fi
fi

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
