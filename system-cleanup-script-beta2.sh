#!/bin/bash

# serv00 系统重置脚本 - 终极增强版
# 版本: 4.0 Ultimate Edition
# 适配: FreeBSD (serv00.com)
# 作者: Tokeisou Samueru
# 风格: 赛博朋克终端 UI + 增强安全特性

set -o pipefail

# === 颜色定义（赛博朋克霓虹色系）===
NEON_PURPLE='\033[38;5;129m'   # 主色调：霓虹紫
NEON_CYAN='\033[38;5;51m'      # 辅助色：霓虹青
NEON_PINK='\033[38;5;201m'     # 点缀色：霓虹粉
NEON_GREEN='\033[38;5;46m'     # 状态色：霓虹绿
NEON_YELLOW='\033[38;5;226m'   # 警示色：明黄
NEON_RED='\033[38;5;196m'      # 危险色：警报红
NEON_BLUE='\033[38;5;39m'      # 信息色：霓虹蓝
RESET='\033[0m'

# 检测终端颜色支持
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# === 彩色输出函数 ===
color() {
    local code="$1"; shift
    if [ "$USE_COLOR" = 1 ]; then
        echo -e "${code}$*${RESET}"
    else
        echo "$*"
    fi
}
purple() { color "$NEON_PURPLE" "$1"; }
cyan()   { color "$NEON_CYAN" "$1"; }
pink()   { color "$NEON_PINK" "$1"; }
green()  { color "$NEON_GREEN" "$1"; }
yellow() { color "$NEON_YELLOW" "$1"; }
red()    { color "$NEON_RED" "$1"; }
blue()   { color "$NEON_BLUE" "$1"; }

# === 配置区 ===
SCRIPT_VERSION="4.0"
LOG_DIR="$HOME/.serv00_logs"
LOG_FILE="$LOG_DIR/reset_$(date +%Y%m%d_%H%M%S).log"
BACKUP_LIST="$LOG_DIR/backup_list.txt"
SCRIPT_PID=$$

# 创建日志目录
mkdir -p "$LOG_DIR" 2>/dev/null

# === 增强日志函数 ===
log() {
    local level="$1"; shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE" 2>/dev/null
}

log_info() { log "INFO" "$*"; }
log_warn() { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }
log_success() { log "SUCCESS" "$*"; }

# === 进度条函数 ===
show_progress() {
    local current=$1
    local total=$2
    local text="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r  ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%% - %s" "$percent" "$text"
    
    [ "$current" -eq "$total" ] && echo ""
}

# === 环境检查（增强版）===
check_env() {
    local missing_cmds=()
    for cmd in whoami crontab ps rm mkdir chmod find df awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        red "❌ 错误: 缺少必要命令: ${missing_cmds[*]}"
        log_error "缺少命令: ${missing_cmds[*]}"
        exit 1
    fi
    
    # 检查是否在 serv00 环境
    if [[ ! "$HOME" =~ serv00 ]] && [[ ! -d "$HOME/domains" ]]; then
        yellow "⚠️  警告: 当前似乎不在 serv00 环境"
        read -p "是否继续？[y/N]: " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
    fi
}

# === 备份重要文件列表 ===
create_backup_list() {
    log_info "创建备份清单"
    {
        echo "=== 重置前文件清单 ==="
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "用户: $(whoami)"
        echo ""
        echo "=== Cron 任务 ==="
        crontab -l 2>/dev/null || echo "无 cron 任务"
        echo ""
        echo "=== 进程列表 ==="
        ps -U "$(whoami)" 2>/dev/null || echo "无法获取进程列表"
        echo ""
        echo "=== 目录结构 ==="
        find "$HOME" -maxdepth 2 -type d 2>/dev/null | head -50
        echo ""
        echo "=== 磁盘使用 ==="
        df -h "$HOME" 2>/dev/null
    } > "$BACKUP_LIST" 2>/dev/null
    
    if [ -f "$BACKUP_LIST" ]; then
        blue "📋 备份清单已保存: $BACKUP_LIST"
        log_success "备份清单创建成功"
    fi
}

# === 清空 Cron 任务 ===
clean_cron() {
    log_info "开始清理 cron 任务"
    
    # 先备份当前 cron
    local cron_backup="$LOG_DIR/cron_backup_$(date +%Y%m%d_%H%M%S).txt"
    if crontab -l > "$cron_backup" 2>/dev/null; then
        blue "  💾 已备份 cron 到: $cron_backup"
    fi
    
    if crontab -r 2>/dev/null; then
        green "  ✅ cron 任务已清空"
        log_success "Cron 任务清理成功"
    else
        if crontab -l >/dev/null 2>&1; then
            yellow "  ⚠️  清理失败（权限问题）"
            log_warn "Cron 清理失败"
        else
            green "  ✅ 无 cron 任务"
            log_info "未发现 cron 任务"
        fi
    fi
}

# === 终止用户进程（智能版）===
kill_user_proc() {
    local user=$(whoami)
    log_info "开始清理用户进程 (排除 PID: $SCRIPT_PID)"
    
    local pids=()
    local count=0
    
    # 收集进程列表
    while IFS= read -r pid; do
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        pids+=("$pid")
    done < <(ps -U "$user" -o pid= 2>/dev/null)
    
    local total=${#pids[@]}
    if [ "$total" -eq 0 ]; then
        yellow "  ⚠️  未发现可终止的进程"
        log_info "无可终止进程"
        return 0
    fi
    
    echo "  📊 发现 $total 个进程，开始清理..."
    
    for pid in "${pids[@]}"; do
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
        fi
        show_progress "$count" "$total" "终止进程中..."
    done
    
    green "  ✅ 已终止 $count/$total 个进程"
    log_success "成功终止 $count 个进程"
}

# === 智能目录清理 ===
clean_directory() {
    local dir="$1"
    local name="$2"
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    
    if rm -rf "$dir" 2>/dev/null; then
        green "  ✅ 已删除 $name ($size)"
        log_success "删除目录: $dir ($size)"
    else
        yellow "  ⚠️  无法删除 $name"
        log_warn "删除失败: $dir"
    fi
}

# === 选择性清理（新功能）===
selective_clean() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              🎯 选择性清理模式                             │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local options=(
        "缓存目录 (.cache, .npm, .yarn)"
        "编程环境 (go, .cargo, node_modules)"
        "临时文件 (tmp, .local/share/Trash)"
        "日志文件 (*.log)"
        "全部以上"
    )
    
    echo "选择要清理的项目（多选用空格分隔）:"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done
    echo ""
    
    read -p "请输入选项 (如: 1 3 5): " choices
    
    if [[ "$choices" == *"5"* ]] || [[ "$choices" == *"全"* ]]; then
        choices="1 2 3 4"
    fi
    
    echo ""
    cyan "开始清理..."
    
    for choice in $choices; do
        case $choice in
            1)
                echo ""; blue "[1] 清理缓存目录..."
                clean_directory "$HOME/.cache" "缓存"
                clean_directory "$HOME/.npm" "NPM 缓存"
                clean_directory "$HOME/.yarn" "Yarn 缓存"
                ;;
            2)
                echo ""; blue "[2] 清理编程环境..."
                clean_directory "$HOME/go" "Go 环境"
                clean_directory "$HOME/.cargo/registry" "Cargo 缓存"
                find "$HOME" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null
                green "  ✅ node_modules 已清理"
                ;;
            3)
                echo ""; blue "[3] 清理临时文件..."
                clean_directory "$HOME/tmp" "临时目录"
                clean_directory "$HOME/.local/share/Trash" "回收站"
                ;;
            4)
                echo ""; blue "[4] 清理日志文件..."
                find "$HOME" -name "*.log" -type f -delete 2>/dev/null
                green "  ✅ 日志文件已清理"
                ;;
        esac
    done
    
    echo ""
    green "✅ 选择性清理完成"
    log_success "选择性清理完成: $choices"
}

# === 恢复默认结构（增强版）===
restore_defaults() {
    local username=$(whoami)
    log_info "开始恢复默认目录结构"

    cyan "  🏗️  创建基础目录..."
    mkdir -p "$HOME/mail" "$HOME/repo" && chmod 755 "$HOME/mail" "$HOME/repo"
    green "  ✅ 已创建 ~/mail 与 ~/repo"

    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"

    # 增强版默认首页
    cat > "$domain_base/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Online - Serv00</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%);
            color: #00ffea;
            font-family: 'Courier New', 'Consolas', monospace;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
        }
        .cyber-container {
            position: relative;
            width: 90%;
            max-width: 700px;
            padding: 40px;
        }
        .cyber-box {
            border: 2px solid #ff00ff;
            box-shadow: 
                0 0 20px rgba(255, 0, 255, 0.5),
                inset 0 0 15px rgba(0, 255, 255, 0.2);
            padding: 40px;
            border-radius: 12px;
            background: rgba(15, 12, 41, 0.8);
            backdrop-filter: blur(10px);
            position: relative;
        }
        .cyber-box::before {
            content: '';
            position: absolute;
            top: -2px; left: -2px; right: -2px; bottom: -2px;
            background: linear-gradient(45deg, #ff00ff, #00ffff, #ff00ff);
            border-radius: 12px;
            opacity: 0;
            animation: border-glow 3s ease-in-out infinite;
            z-index: -1;
        }
        @keyframes border-glow {
            0%, 100% { opacity: 0; }
            50% { opacity: 0.3; }
        }
        h1 {
            font-size: 2.5em;
            text-align: center;
            text-shadow: 
                0 0 10px #ff00ff,
                0 0 20px #ff00ff,
                0 0 30px #ff00ff;
            margin-bottom: 30px;
            animation: glitch 3s infinite;
        }
        @keyframes glitch {
            0%, 90%, 100% { text-shadow: 0 0 10px #00ffff; }
            25% { text-shadow: -3px 0 #ff00ff, 3px 0 #00ffff; }
            75% { text-shadow: 3px 0 #ff00ff, -3px 0 #00ffff; }
        }
        .status-line {
            display: flex;
            justify-content: space-between;
            padding: 15px 0;
            border-bottom: 1px solid rgba(0, 255, 255, 0.2);
            font-size: 1.1em;
        }
        .status-line:last-child { border-bottom: none; }
        .status-label { opacity: 0.8; }
        .status-value { 
            color: #00ff00;
            font-weight: bold;
            text-shadow: 0 0 5px #00ff00;
        }
        .pulse {
            display: inline-block;
            width: 10px;
            height: 10px;
            background: #00ff00;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; box-shadow: 0 0 5px #00ff00; }
            50% { opacity: 0.3; box-shadow: 0 0 15px #00ff00; }
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 0, 255, 0.3);
            font-size: 0.9em;
            opacity: 0.7;
        }
        .particles {
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            pointer-events: none;
            z-index: -1;
        }
        .particle {
            position: absolute;
            width: 2px;
            height: 2px;
            background: #00ffff;
            border-radius: 50%;
            animation: float 10s linear infinite;
        }
        @keyframes float {
            0% { transform: translateY(100vh) translateX(0); opacity: 0; }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { transform: translateY(-100vh) translateX(100px); opacity: 0; }
        }
    </style>
</head>
<body>
    <div class="particles" id="particles"></div>
    <div class="cyber-container">
        <div class="cyber-box">
            <h1>🌐 SYSTEM ONLINE</h1>
            <div class="status-line">
                <span class="status-label">服务器状态</span>
                <span class="status-value"><span class="pulse"></span>正常运行</span>
            </div>
            <div class="status-line">
                <span class="status-label">域名</span>
                <span class="status-value" id="domain">加载中...</span>
            </div>
            <div class="status-line">
                <span class="status-label">系统时间</span>
                <span class="status-value" id="time">--:--:--</span>
            </div>
            <div class="footer">
                <p>// Powered by Serv00.com //</p>
                <p style="margin-top: 10px; font-size: 0.85em;">Ready for deployment</p>
            </div>
        </div>
    </div>
    <script>
        // 粒子效果
        const particles = document.getElementById('particles');
        for(let i = 0; i < 30; i++) {
            const p = document.createElement('div');
            p.className = 'particle';
            p.style.left = Math.random() * 100 + '%';
            p.style.animationDelay = Math.random() * 10 + 's';
            particles.appendChild(p);
        }
        
        // 显示域名
        document.getElementById('domain').textContent = window.location.hostname;
        
        // 实时时钟
        function updateTime() {
            const now = new Date();
            const timeStr = now.toTimeString().split(' ')[0];
            document.getElementById('time').textContent = timeStr;
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html"
    green "  ✅ 增强版默认页面已生成"
    log_success "创建增强版 index.html"

    echo ""
    green "  ✅ 默认结构恢复完成"
    log_success "默认结构恢复完成"
}

# === 完整系统重置（增强版）===
init_server() {
    clear
    red "┌────────────────────────────────────────────────────────────┐"
    red "│                  ⚠️  危险操作警告 ⚠️                       │"
    red "│                此操作将不可撤销！                           │"
    red "└────────────────────────────────────────────────────────────┘"
    echo ""
    yellow "执行后将进行以下操作："
    echo "  • 🔥 清空所有定时任务 (cron)"
    echo "  • 💀 终止当前用户的全部进程"
    echo "  • 🧹 删除用户目录下的大部分内容"
    echo ""
    cyan "💡 serv00 自动保留最近 7 天备份（可在面板中恢复）"
    blue "💾 操作前会自动创建文件清单备份"
    echo ""

    read -p "$(red '是否继续执行系统重置？[y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        yellow "🛑 操作已取消"
        log_info "用户取消完整重置操作"
        return 0
    fi

    echo ""
    read -p "$(cyan '是否保留配置文件 (.bashrc, .ssh 等)? [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    pink "🚀 启动系统重置协议 v$SCRIPT_VERSION"
    cyan "════════════════════════════════════════════════════════════"
    log_info "=== 开始完整系统重置 ==="

    # 0. 创建备份清单
    echo ""; cyan "[0/6] 📋 创建备份清单..."
    create_backup_list
    sleep 1

    # 1. 清理定时任务
    echo ""; cyan "[1/6] 🕒 清理 cron 任务..."
    clean_cron
    sleep 1

    # 2. 清理缓存目录
    echo ""; cyan "[2/6] 🧹 清理缓存目录..."
    local cache_dirs=("go" ".cache" ".npm" ".yarn" ".cargo/registry" ".local/share/Trash")
    local cleaned=0
    for d in "${cache_dirs[@]}"; do
        if [ -d "$HOME/$d" ]; then
            clean_directory "$HOME/$d" "$d"
            ((cleaned++))
        fi
    done
    green "  ✅ 已清理 $cleaned 个缓存目录"
    sleep 1

    # 3. 清理主目录
    echo ""; cyan "[3/6] 🗑️  清理主目录..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        green "  → 保留模式：保留隐藏配置文件"
        rm -rf "$HOME"/* 2>/dev/null
        green "  ✅ 已清理非隐藏文件"
        log_info "清理非隐藏文件（保留模式）"
    else
        yellow "  → 完全清理模式：包括隐藏文件"
        local protected=("." ".." "$LOG_DIR")
        
        shopt -s nullglob dotglob 2>/dev/null || true
        for item in "$HOME"/* "$HOME"/.*; do
            local skip=0
            for p in "${protected[@]}"; do
                [[ "$item" == "$HOME/$p" ]] && { skip=1; break; }
            done
            [ "$skip" -eq 1 ] && continue
            rm -rf "$item" 2>/dev/null
        done
        shopt -u nullglob dotglob 2>/dev/null || true
        
        green "  ✅ 已完全清空主目录"
        log_info "完全清空主目录"
    fi
    sleep 1

    # 4. 恢复默认结构
    echo ""; cyan "[4/6] 🏗️  恢复默认结构..."
    restore_defaults
    sleep 1

    # 5. 清理用户进程
    echo ""; cyan "[5/6] 💀 终止用户进程..."
    yellow "  ⚠️  SSH 连接可能在 3 秒内断开..."
    for i in 3 2 1; do
        echo -n "  $i..."
        sleep 1
    done
    echo ""
    kill_user_proc

    # 6. 生成完成报告
    echo ""; cyan "[6/6] 📊 生成重置报告..."
    sleep 1

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    green "✅ 系统重置完成"
    cyan "════════════════════════════════════════════════════════════"
    log_success "=== 系统重置完成 ==="

    local username=$(whoami)
    echo ""
    pink "📌 重置后信息:"
    echo "  • 备份清单: $BACKUP_LIST"
    echo "  • 日志文件: $LOG_FILE"
    echo "  • 默认网站: https://$username.serv00.net"
    echo "  • serv00 备份: 面板中可恢复最近 7 天快照"
    echo ""
    blue "💡 提示: 使用选项 6 查看详细重置报告"
    echo ""
}

# === 查看重置报告（新功能）===
show_report() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                📊 系统重置报告                             │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    if [ ! -f "$LOG_FILE" ]; then
        yellow "暂无重置记录"
        return 0
    fi
    
    echo "📁 当前日志: $LOG_FILE"
    echo ""
    
    local total_logs=$(ls -1 "$LOG_DIR"/reset_*.log 2>/dev/null | wc -l)
    echo "📚 历史记录数: $total_logs"
    echo ""
    
    if [ -f "$BACKUP_LIST" ]; then
        echo "📋 备份清单预览:"
        head -20 "$BACKUP_LIST"
        echo "..."
        echo ""
    fi
    
    echo "最近操作日志:"
    tail -15 "$LOG_FILE" 2>/dev/null || echo "无日志内容"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 系统状态显示（增强版）===
show_info() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                🖥️  系统状态报告                            │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local username=$(whoami)
    echo "👤 用户: $username"
    echo "🏠 主目录: $HOME"
    echo "📍 当前路径: $(pwd)"
    echo ""

    # 磁盘使用情况
    if command -v df >/dev/null; then
        local disk_info=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "💾 磁盘使用: $disk_info"
        
        local usage_percent=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
        if [ "$usage_percent" -gt 80 ]; then
            red "   ⚠️  磁盘使用率超过 80%"
        fi
    fi

    # 统计信息
    local cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l | tr -d ' ')
    local proc_n=$(ps -U "$username" 2>/dev/null | wc -l | tr -d ' ')
    local file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    local dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)

    echo ""
    echo "📊 资源统计:"
    printf "  %-20s %s\n" "Cron 任务:" "$cron_n 个"
    printf "  %-20s %s\n" "运行进程:" "$proc_n 个"
    printf "  %-20s %s\n" "根目录文件:" "$file_n 个"
    printf "  %-20s %s\n" "根目录子目录:" "$dir_n 个"
    
    # 检查关键目录
    echo ""
    echo "📁 关键目录状态:"
    for dir in "mail" "repo" "domains"; do
        if [ -d "$HOME/$dir" ]; then
            green "  ✅ ~/$dir"
        else
            red "  ❌ ~/$dir (不存在)"
        fi
    done
    
    # 网站状态
    if [ -d "$HOME/domains/$username.serv00.net/public_html" ]; then
        echo ""
        echo "🌐 默认网站:"
        local index_file="$HOME/domains/$username.serv00.net/public_html/index.html"
        if [ -f "$index_file" ]; then
            green "  ✅ https://$username.serv00.net"
            local size=$(du -sh "$index_file" 2>/dev/null | awk '{print $1}')
            echo "     首页大小: $size"
        else
            yellow "  ⚠️  首页文件不存在"
        fi
    fi
    
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 快速恢复功能（新增）===
quick_restore() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              ⚡ 快速恢复向导                               │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    yellow "此功能将快速恢复基本目录结构和默认网站"
    echo ""
    
    read -p "$(cyan '是否继续？[Y/n]: ')" confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    echo ""
    cyan "开始快速恢复..."
    log_info "启动快速恢复"
    
    restore_defaults
    
    echo ""
    green "✅ 快速恢复完成！"
    log_success "快速恢复完成"
}

# === 清理历史日志（新增）===
clean_old_logs() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              🗑️  日志清理工具                              │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local log_count=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    
    if [ "$log_count" -eq 0 ]; then
        yellow "没有找到日志文件"
        return 0
    fi
    
    echo "📊 当前日志统计:"
    echo "  文件数量: $log_count"
    
    if command -v du >/dev/null; then
        local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
        echo "  总大小: $total_size"
    fi
    
    echo ""
    yellow "选项:"
    echo "  1. 保留最近 5 个日志"
    echo "  2. 保留最近 10 个日志"
    echo "  3. 清空所有日志"
    echo "  4. 取消"
    echo ""
    
    read -p "$(cyan '请选择 [1-4]: ')" choice
    
    case $choice in
        1|2)
            local keep=${choice}
            [ "$keep" -eq 1 ] && keep=5 || keep=10
            
            echo ""
            cyan "保留最近 $keep 个日志，删除其余..."
            
            ls -1t "$LOG_DIR"/*.log 2>/dev/null | tail -n +$((keep+1)) | while read -r f; do
                rm -f "$f" && echo "  已删除: $(basename "$f")"
            done
            
            green "✅ 清理完成"
            log_success "清理旧日志（保留 $keep 个）"
            ;;
        3)
            echo ""
            red "⚠️  将删除所有日志文件！"
            read -p "确认？[y/N]: " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$LOG_DIR"/*.log 2>/dev/null
                green "✅ 已清空所有日志"
                log_success "清空所有日志"
            else
                yellow "操作取消"
            fi
            ;;
        *)
            yellow "操作取消"
            ;;
    esac
}

# === 主菜单界面（增强版）===
show_menu() {
    clear
    echo ""
    purple "╔════════════════════════════════════════════════════════════╗"
    purple "║      🌐 Serv00 终极系统重置终端 v$SCRIPT_VERSION            ║"
    purple "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "  $(pink "1.") $(cyan "🗑️   执行完整系统重置      ") $(yellow "[危险操作]")"
    echo "  $(pink "2.") $(cyan "🎯  选择性清理             ") $(green "[推荐]")"
    echo "  $(pink "3.") $(cyan "⚡  快速恢复默认结构       ") $(blue "[安全]")"
    echo ""
    echo "  $(pink "4.") $(cyan "🕒  清空 cron 定时任务    ")"
    echo "  $(pink "5.") $(cyan "💀  终止用户进程           ")"
    echo "  $(pink "6.") $(cyan "📊  查看系统状态           ")"
    echo ""
    echo "  $(pink "7.") $(cyan "📋  查看重置报告           ")"
    echo "  $(pink "8.") $(cyan "🗑️   清理历史日志          ")"
    echo "  $(pink "9.") $(cyan "🚪  退出终端               ")"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    
    # 显示快捷提示
    if [ -f "$LOG_FILE" ]; then
        local last_reset=$(grep "系统重置完成" "$LOG_FILE" | tail -1 | awk '{print $1, $2}')
        if [ -n "$last_reset" ]; then
            echo ""
            blue "💡 上次重置: ${last_reset:1:16}"
        fi
    fi
    
    echo ""
    read -p "$(pink ">> 请选择操作 [1-9]: ")" choice

    case $choice in
        1)
            init_server
            ;;
        2)
            selective_clean
            ;;
        3)
            quick_restore
            ;;
        4)
            echo ""
            cyan "执行中: 清理 cron 定时任务"
            clean_cron
            ;;
        5)
            echo ""
            yellow "⚠️  此操作将终止全部用户进程 (SSH 可能断开)"
            read -p "$(red "确认执行？[y/N]: ")" c
            
            if [[ "$c" =~ ^[Yy]$ ]]; then
                echo ""
                cyan "准备终止进程..."
                sleep 2
                kill_user_proc
            else
                yellow "操作取消"
            fi
            ;;
        6)
            show_info
            ;;
        7)
            show_report
            ;;
        8)
            clean_old_logs
            ;;
        9)
            echo ""
            read -p "$(yellow "确定退出终端？[Y/n]: ")" e
            e=${e:-Y}
            
            if [[ "$e" =~ ^[Yy]$ ]]; then
                green "🔌 感谢使用，再见！"
                log_info "用户正常退出"
                exit 0
            fi
            ;;
        *)
            red "❌ 无效选项，请输入 1-9"
            sleep 1
            ;;
    esac
}

# === 启动欢迎界面 ===
show_welcome() {
    clear
    echo ""
    purple "╔════════════════════════════════════════════════════════════╗"
    purple "║                                                            ║"
    purple "║          🚀 Serv00 终极系统重置工具 v$SCRIPT_VERSION        ║"
    purple "║                                                            ║"
    purple "╚════════════════════════════════════════════════════════════╝"
    echo ""
    cyan "  作者: Tokeisou Samueru"
    cyan "  适配: FreeBSD (serv00.com)"
    cyan "  风格: 赛博朋克终端 UI"
    echo ""
    blue "  ✨ 新特性:"
    echo "    • 🎯 选择性清理模式"
    echo "    • ⚡ 快速恢复功能"
    echo "    • 📋 自动备份清单"
    echo "    • 📊 增强的系统报告"
    echo "    • 🎨 升级版默认网站"
    echo ""
    yellow "  ⚠️  重要提示:"
    echo "    • 所有危险操作都有二次确认"
    echo "    • serv00 自动保留 7 天快照备份"
    echo "    • 日志保存在 ~/.serv00_logs/"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    echo ""
    read -p "$(green "按 ENTER 进入主菜单...")" -r
}

# === 信号处理 ===
cleanup_on_exit() {
    log_info "脚本异常退出"
    echo ""
    yellow "⚠️  脚本已中断"
    exit 130
}

trap cleanup_on_exit INT TERM

# === 主程序入口 ===
main() {
    # 环境检查
    check_env
    
    # 记录启动
    log_info "=== 脚本启动 v$SCRIPT_VERSION ==="
    log_info "执行用户: $(whoami)"
    log_info "主目录: $HOME"
    
    # 显示欢迎界面（仅首次）
    if [ ! -f "$LOG_DIR/.welcomed" ]; then
        show_welcome
        touch "$LOG_DIR/.welcomed" 2>/dev/null
    fi
    
    # 主循环
    while true; do
        show_menu
        echo ""
        read -p "$(cyan "按 ENTER 返回主菜单...")" -r
    done
}

# 启动脚本
main
