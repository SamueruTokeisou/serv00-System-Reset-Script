#!/bin/bash

# serv00 系统重置脚本 - 赛博朋克增强版
# 版本: 3.0
# 适配: FreeBSD (serv00.com)
# 风格: Cyberpunk Terminal UI

set -o pipefail

# === 颜色定义（赛博朋克霓虹色系）===
NEON_PURPLE='\033[38;5;129m'   # 主色调：霓虹紫
NEON_CYAN='\033[38;5;51m'      # 霓虹青
NEON_PINK='\033[38;5;201m'     # 霓虹粉
NEON_GREEN='\033[38;5;46m'     # 霓虹绿
NEON_YELLOW='\033[38;5;226m'   # 警告黄
NEON_RED='\033[38;5;196m'      # 危险红
RESET='\033[0m'

# 检测终端是否支持颜色
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# 彩色函数（自动降级）
color() {
    local code="$1"; shift
    if [ "$USE_COLOR" = 1 ]; then
        echo -e "${code}$*${RESET}"
    else
        echo "$*"
    fi
}
紫色() { color "$NEON_PURPLE" "$1"; }
青色()   { color "$NEON_CYAN" "$1"; }
粉色()   { color "$NEON_PINK" "$1"; }
绿色()  { color "$NEON_GREEN" "$1"; }
黄色() { color "$NEON_YELLOW" "$1"; }
红色()    { color "$NEON_RED" "$1"; }

# === 配置 ===
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_PID=$$

# === 日志 ===
日志记录() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# === 环境检查 ===
检查环境() {
    for cmd in whoami crontab pkill ps rm mkdir chmod; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            红色 "❌ 错误: 缺少必要命令 $cmd"
            exit 1
        fi
    done
}

# === 清理 cron ===
清理Cron() {
    日志记录 "清理 cron 任务"
    if crontab -r 2>/dev/null; then
        绿色 "✅ cron 任务已清空"
        日志记录 "Cron tasks cleared"
    else
        if crontab -l >/dev/null 2>&1; then
            黄色 "⚠️  清理失败（权限问题？）"
            日志记录 "Failed to clear cron"
        else
            绿色 "✅ 无 cron 任务，跳过"
            日志记录 "No cron tasks found"
        fi
    fi
}

# === 终止用户进程（排除自身）===
终止进程() {
    local user=$(whoami)
    日志记录 "清理用户进程 (排除 PID: $SCRIPT_PID)"
    
    local count=0
    # FreeBSD 兼容：ps -U user -o pid=
    for pid in $(ps -U "$user" -o pid= 2>/dev/null); do
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
        fi
    done
    
    if [ "$count" -eq 0 ]; then
        黄色 "⚠️  未发现可清理的进程"
    else
        绿色 "✅ 已终止 $count 个进程"
    fi
    日志记录 "Terminated $count processes"
}

# === 安全删除目录 ===
清理目录() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 0
    fi
    if rm -rf "$dir" 2>/dev/null; then
        绿色 "✅ 已删除: $dir"
        日志记录 "Deleted: $dir"
    else
        黄色 "⚠️  无法删除: $dir"
        日志记录 "Failed to delete: $dir"
    fi
}

# === 恢复默认结构 ===
恢复默认() {
    local username=$(whoami)
    日志记录 "恢复默认目录结构"

    青色 "→ 创建基础目录..."
    mkdir -p "$HOME/mail" "$HOME/repo" && chmod 755 "$HOME/mail" "$HOME/repo"
    绿色 "✅ ~/mail  ~/repo"

    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"

    # 默认 index.html
    cat > "$domain_base/public_html/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$username.serv00.net</title>
    <meta charset="utf-8">
    <style>
        body {
            background: #0f0c29;
            background: linear-gradient(to right, #24243e, #302b63, #0f0c29);
            color: #00ffea;
            font-family: 'Courier New', monospace;
            text-align: center;
            padding: 50px;
            margin: 0;
        }
        .cyber-box {
            border: 2px solid #ff00ff;
            box-shadow: 0 0 15px #00ffff, inset 0 0 10px rgba(0,255,255,0.3);
            padding: 30px;
            border-radius: 8px;
            max-width: 600px;
            margin: 0 auto;
            backdrop-filter: blur(5px);
        }
        h1 {
            font-size: 2.2em;
            text-shadow: 0 0 10px #ff00ff;
            margin: 0 0 20px;
        }
        p { font-size: 1.1em; opacity: 0.9; }
        .glitch {
            animation: glitch 3s infinite;
        }
        @keyframes glitch {
            0% { text-shadow: 0 0 10px #00ffff; }
            25% { text-shadow: -5px 0 #ff00ff, 5px 0 #00ffff; }
            50% { text-shadow: 0 0 10px #00ffff; }
            75% { text-shadow: 5px 0 #ff00ff, -5px 0 #00ffff; }
            100% { text-shadow: 0 0 10px #00ffff; }
        }
    </style>
</head>
<body>
    <div class="cyber-box">
        <h1 class="glitch">🌐 SYSTEM ONLINE</h1>
        <p>Welcome to <strong>$username.serv00.net</strong></p>
        <p>Server status: <span style="color:#00ff00">ACTIVE</span></p>
        <p style="font-size:0.9em; margin-top:25px;">// Powered by serv00.com //</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html"
    绿色 "✅ 默认网站已部署"
    日志记录 "Created default index.html"

    echo ""
    绿色 "✅ 默认结构恢复完成"
}

# === 初始化系统 ===
初始化服务器() {
    clear
    红色 "┌────────────────────────────────────────────────────────────┐"
    红色 "│                    ⚠️  危险区域 ⚠️                       │"
    红色 "│           此操作不可撤销！                                │"
    红色 "└────────────────────────────────────────────────────────────┘"
    echo ""
    黄色 "这将:"
    echo "  • 🔥 删除所有cron作业"
    echo "  • 💀 杀死所有你的进程"
    echo "  • 🧹 删除你主目录下的几乎所有内容"
    echo ""
    青色 "💡 serv00 自动保留最近 7 天备份（可通过面板恢复）"
    echo ""

    read -p "$(红色 '确定要重置系统吗？ [y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        黄色 "🛑 操作取消."
        日志记录 "Operation cancelled by user"
        return 0
    fi

    echo ""
    read -p "$(青色 '是否保留配置文件（.bashrc, .ssh等）？ [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    echo ""
    青色 "════════════════════════════════════════════════════════════"
    粉色 "🚀 开始系统重置协议..."
    青色 "════════════════════════════════════════════════════════════"
    日志记录 "=== System reset started ==="

    # 1. Cron
    echo ""; 青色 "[1/5] 🕒 清除cron作业..."; 清理Cron

    # 2. 特殊目录
    echo ""; 青色 "[2/5] 🧹 清理缓存目录..."
    for d in go .cache .npm .yarn .cargo/registry .local/share/Trash; do
        [ -d "$HOME/$d" ] && 清理目录 "$HOME/$d"
    done

    # 3. 主目录清理
    echo ""; 青色 "[3/5] 🗑️  清理主目录..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        绿色 "→ 保留模式：保留点文件"
        # 删除非隐藏文件
        rm -rf "$HOME"/* 2>/dev/null
        绿色 "✅ 非隐藏文件已清除"
        日志记录 "Purged non-hidden files"
    else
        黄色 "→ 完全清除模式：包括点文件"
        # 启用安全 glob
        set +f  # 确保 glob 开启
        shopt -s nullglob dotglob 2>/dev/null || true
        for item in "$HOME"/* "$HOME"/.*; do
            case "$item" in
                "$HOME/."|"$HOME/.."|"$LOG_FILE") continue ;;
            esac
            rm -rf "$item" 2>/dev/null
        done
        shopt -u nullglob dotglob 2>/dev/null || true
        绿色 "✅ 主目录已完全清除"
        日志记录 "Full home directory purged"
    fi

    # 4. 恢复默认
    echo ""; 青色 "[4/5] 🏗️  恢复默认结构..."; 恢复默认

    # 5. 清理进程（最后）
    echo ""; 青色 "[5/5] 💀 结束用户进程..."
    黄色 "⚠️  连接可能在3秒后中断..."
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    终止进程

    echo ""
    青色 "════════════════════════════════════════════════════════════"
    绿色 "✅ 系统重置完成"
    青色 "════════════════════════════════════════════════════════════"
    日志记录 "=== System reset completed ==="

    echo ""
    粉色 "📌 重置后信息:"
    echo "  • 备份: serv00 保留7天快照"
    echo "  • 默认站点: https://$username.serv00.net"
    echo "  • 目录创建:"
    echo "      ~/mail, ~/repo, ~/domains/$username.serv00.net/{public_html,logs/access}"
    [ -f "$LOG_FILE" ] && echo "  • 日志: $LOG_FILE"
    echo ""
}

# === 显示信息 ===
显示信息() {
    clear
    青色 "┌────────────────────────────────────────────────────────────┐"
    青色 "│                🖥️  系统状态报告                            │"
    青色 "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "👤 用户: $(whoami)"
    echo "🏠 主目录: $HOME"
    echo "📍 当前目录: $(pwd)"
    echo ""

    if command -v df >/dev/null; then
        disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "💾 磁盘使用情况: $disk"
    fi

    cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    proc_n=$(ps -U "$(whoami)" 2>/dev/null | wc -l)
    file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)

    echo ""
    echo "📊 统计:"
    echo "  Cron 作业: $cron_n"
    echo "  进程数: $proc_n"
    echo "  文件数: $file_n"
    echo "  目录数: $dir_n"
    echo ""
    青色 "────────────────────────────────────────────────────────────"
}

# === 主菜单 ===
显示菜单() {
    clear
    echo ""
    紫色 "┌────────────────────────────────────────────────────────────┐"
    紫色 "│        🌐 serv00 赛博重置终端 v3.0                         │"
    紫色 "│            「霓虹协议激活」                                 │"
    紫色 "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  $(粉色 "1.") $(青色 "🗑️  完全系统重置")"
    echo "  $(粉色 "2.") $(青色 "🕒 清除Cron作业")"
    echo "  $(粉色 "3.") $(青色 "💀 结束用户进程")"
    echo "  $(粉色 "4.") $(青色 "📊 系统状态")"
    echo "  $(粉色 "5.") $(青色 "🚪 退出终端")"
    echo ""
    青色 "────────────────────────────────────────────────────────────"
    read -p "$(粉色 ">> 选择选项 [1-5]: ")" choice

    case $choice in
        1) 初始化服务器 ;;
        2) echo ""; 青色 "执行: 清除cron"; 清理Cron ;;
        3)
            echo ""; 黄色 "⚠️  这将杀死所有你的进程（SSH连接可能会断开）"
            read -p "$(红色 "确认吗？ [y/N]: ")" c; [[ "$c" =~ ^[Yy]$ ]] && { sleep 2; 终止进程; }
            ;;
        4) 显示信息 ;;
        5)
            read -p "$(黄色 "退出终端吗？ [Y/n]: ")" e; [[ ! "$e" =~ ^[Nn]$ ]] && { 绿色 "🔌 终止会话..."; exit 0; }
            ;;
        *) 红色 "❌ 无效选项"; sleep 1 ;;
    esac
}

# === 信号处理 ===
trap '日志记录 "脚本被用户中断"; exit 130' INT TERM

# === 主程序 ===
main() {
    检查环境
    日志记录 "=== 脚本由 $(whoami) 启动 ==="
    while true; do
        显示菜单
        echo ""; read -p "$(青色 "按ENTER键返回菜单...")" -r
    done
}

main
