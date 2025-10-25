#!/bin/bash
set -euo pipefail

# 霓虹配色（兼容无色终端）
if [ -t 1 ]; then
    P='\033[38;5;129m'  # 紫
    C='\033[38;5;51m'   # 青
    R='\033[38;5;196m'  # 红
    G='\033[38;5;46m'   # 绿
    Y='\033[38;5;226m'  # 黄
    X='\033[0m'
else
    P=C=R=G=Y=X=
fi

log="$HOME/cleanup_$(date +%Y%m%d_%H%M%S).log"
me=$(whoami)
pid=$$

log_msg() { echo "[$(date '+%F %T')] $*" >>"$log"; }

# 清理 cron
clear_cron() {
    if crontab -r 2>/dev/null; then
        echo "${G}✅ cron cleared${X}"
        log_msg "cron cleared"
    elif crontab -l >/dev/null 2>&1; then
        echo "${Y}⚠️  cron clear failed${X}"
        log_msg "cron clear failed"
    else
        echo "${G}✅ no cron jobs${X}"
        log_msg "no cron jobs"
    fi
}

# 杀用户进程（排除自身）
kill_procs() {
    count=0
    for p in $(ps -U "$me" -o pid= 2>/dev/null); do
        [ "$p" = "$pid" ] && continue
        if kill -9 "$p" 2>/dev/null; then ((count++)); fi
    done
    echo "${G}✅ killed $count processes${X}"
    log_msg "killed $count processes"
}

# 安全删除目录
rm_dir() {
    [ -d "$1" ] && { rm -rf "$1" && echo "${G}✅ removed $1${X}" && log_msg "removed $1"; }
}

# 恢复默认结构
restore_default() {
    mkdir -p "$HOME/mail" "$HOME/repo"
    chmod 755 "$HOME/mail" "$HOME/repo"

    d="$HOME/domains/$me.serv00.net"
    mkdir -p "$d/public_html" "$d/logs/access"
    chmod -R 755 "$d"

    cat >"$d/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Default</title>
<style>body{background:#0f0c29;color:#00ffea;font-family:monospace;text-align:center;padding:50px;}
h1{font-size:2em;text-shadow:0 0 10px #ff00ff;}</style></head>
<body><h1>SYSTEM ONLINE</h1><p>Default page</p></body></html>
EOF
    chmod 644 "$d/public_html/index.html"
    echo "${G}✅ default site restored${X}"
    log_msg "default site restored"
}

# 主清理流程
reset_system() {
    echo "${R}⚠️  This will delete almost everything in $HOME.${X}"
    echo "${Y}💡 serv00 keeps 7-day backups via panel.${X}"
    read -p "Continue? [y/N]: " -r
    [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "${Y}Cancelled.${X}"; return; }

    read -p "Keep dotfiles (.bashrc, .ssh, etc)? [Y/n]: " -r
    keep=${REPLY:-Y}

    echo "${C}→ Clearing cron...${X}"; clear_cron
    echo "${C}→ Removing cache dirs...${X}"
    for dir in go .cache .npm .yarn .cargo/registry; do rm_dir "$HOME/$dir"; done

    echo "${C}→ Cleaning home...${X}"
    if [[ $keep =~ ^[Yy]$ ]]; then
        rm -rf "$HOME"/* 2>/dev/null
    else
        set +f
        shopt -s nullglob dotglob 2>/dev/null || true
        for f in "$HOME"/* "$HOME"/.*; do
            [[ "$f" == "$HOME/." || "$f" == "$HOME/.." || "$f" == "$log" ]] && continue
            rm -rf "$f"
        done
        shopt -u nullglob dotglob 2>/dev/null || true
    fi

    echo "${C}→ Restoring defaults...${X}"; restore_default
    echo "${C}→ Killing processes (SSH may drop)...${X}"
    sleep 2; kill_procs

    echo "${G}✅ Reset complete. Log: $log${X}"
}

# 菜单
while true; do
    clear
    echo "${P}serv00 Reset Tool${X}"
    echo "1) Full reset"
    echo "2) Clear cron"
    echo "3) Kill processes"
    echo "4) Exit"
    read -p "Choice [1-4]: " -r opt
    case $opt in
        1) reset_system; break ;;
        2) clear_cron ;;
        3) kill_procs ;;
        4) exit 0 ;;
        *) echo "${R}Invalid${X}"; sleep 1 ;;
    esac
done
