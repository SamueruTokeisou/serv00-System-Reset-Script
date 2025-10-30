#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# 辅助函数
red() {
    echo -e "${RED}$1${RESET}"
}

green() {
    echo -e "${GREEN}$1${RESET}"
}

yellow() {
    echo -e "${YELLOW}$1${RESET}"
}

# 清理cron任务
cleanCron() {
    # 创建一个空文件用于清空 crontab
    local temp_file=$(mktemp)
    echo "" > "$temp_file"
    crontab "$temp_file"
    rm "$temp_file"
    green "✅ Cron 任务已清理"
}

# 结束所有用户进程
killUserProc() {
    local user=$(whoami)
    # 排除当前脚本进程，避免自杀
    local current_pid=$$
    local pids_to_kill=$(ps -U "$user" -o pid= 2>/dev/null | grep -v "^$current_pid$")
    if [ -n "$pids_to_kill" ]; then
        echo "$pids_to_kill" | xargs kill -9 2>/dev/null
        green "✅ 用户进程已清理 (可能断开SSH)"
    else
        yellow "⚠️  未发现其他用户进程"
    fi
}

# 创建默认目录结构
createDefaultDirs() {
    local username=$(whoami)
    local domain_base="$HOME/domains/$username.serv00.net"

    # 创建基础目录
    mkdir -p "$HOME/mail" "$HOME/repo" "$HOME/logs" "$HOME/tmp"
    chmod 755 "$HOME/mail" "$HOME/repo" "$HOME/logs" "$HOME/tmp" 2>/dev/null

    # 创建域名目录结构
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access" "$domain_base/cgi-bin"
    chmod -R 755 "$domain_base" 2>/dev/null

    # 创建一个简单的默认首页
    cat > "$domain_base/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Serv00 Reset Complete</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        h1 {
            margin-top: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .status {
            background: rgba(0,255,0,0.2);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ 系统重置完成</h1>
        <div class="status">
            <h2>系统已就绪</h2>
            <p>您的 Serv00 服务器已重置</p>
        </div>
        <p>开始部署您的应用吧！</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html" 2>/dev/null

    green "✅ 默认目录结构和首页已创建"
}

# 系统初始化函数
initServer() {
    read -p "$(red "确定要初始化系统吗？这将删除大部分数据。 [y/n] [n]: ")" input
    input=${input:-n}
    
    if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
        read -p "是否保留用户配置？[y/n] [y]: " saveProfile
        saveProfile=${saveProfile:-y}

        green "清理cron任务..."
        cleanCron

        green "清理磁盘..."
        # 清理 $HOME/go 文件夹
        if [ -d "$HOME/go" ]; then
            chmod -R 755 "$HOME/go" 2>/dev/null
            rm -rf "$HOME/go" 2>/dev/null
        fi
        
        if [[ "$saveProfile" = "y" ]] || [[ "$saveProfile" = "Y" ]]; then
            # 保留配置文件，删除其他文件
            find "$HOME" -maxdepth 1 -type f -not -path "$HOME/.serv00_logs/*" -not -name ".*" -delete 2>/dev/null
            find "$HOME" -maxdepth 1 -type d -not -name "." -not -name ".." -not -name ".serv00_logs" -not -name "mail" -not -name "repo" -not -name "domains" -not -name "logs" -not -name "tmp" -exec rm -rf {} + 2>/dev/null
        else
            # 删除所有非系统目录和文件（保留 . 和 ..）
            # 更安全的方式：先列出要删除的，再删除
            for item in "$HOME"/* "$HOME"/.*; do
                [[ ! -e "$item" ]] && continue # 跳过不存在的
                case "$item" in
                    "$HOME/." | "$HOME/..") continue ;; # 跳过 . 和 ..
                esac
                rm -rf "$item" 2>/dev/null
            done
        fi

        # 创建默认目录结构
        green "创建默认目录结构..."
        createDefaultDirs

        # 在最后清理进程，避免脚本自己被终止
        yellow "准备清理用户进程，SSH连接可能会断开..."
        sleep 3
        green "清理用户进程..."
        killUserProc

        yellow "系统初始化完成"
    else
        yellow "操作已取消"
    fi
}

# 显示菜单
showMenu() {
    clear
    echo "========================================="
    echo "         系统清理脚本 - SSH面板          "
    echo "========================================="
    echo "1. 初始化系统（清理数据）"
    echo "2. 退出"
    echo "========================================="
    read -p "请选择操作 [1-2]: " choice

    case $choice in
        1)
            initServer
            ;;
        2)
            echo "退出脚本"
            exit 0
            ;;
        *)
            red "无效的选择，请重新输入"
            ;;
    esac
}

# 主循环
while true; do
    showMenu
    read -p "按Enter键继续..."
done
