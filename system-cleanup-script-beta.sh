#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# 辅助函数
red() { echo -e "${RED}$1${RESET}"; }
green() { echo -e "${GREEN}$1${RESET}"; }
yellow() { echo -e "${YELLOW}$1${RESET}"; }
blue() { echo -e "${BLUE}$1${RESET}"; }

# 显示横幅
show_banner() {
    clear
    echo "========================================="
    echo -e "    ${BLUE}Serv00 系统恢复脚本 v1.0${RESET}"
    echo "========================================="
}

# 清理 Cron 任务
clean_cron() {
    if crontab -l >/dev/null 2>&1; then
        crontab -r 2>/dev/null
        green "✓ 已清空所有 Cron 任务"
    else
        yellow "⊘ 无 Cron 任务需要清理"
    fi
}

# 清理用户进程（保护 SSH 和脚本自身）
clean_processes() {
    local user=$(whoami)
    local script_pid=$$
    local parent_pid=$PPID
    
    yellow "正在清理用户进程..."
    
    # 获取所有用户进程，排除关键进程
    local pids=$(ps -u "$user" -o pid= | grep -v -E "^($script_pid|$parent_pid|1)$" || true)
    
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        green "✓ 已终止非关键用户进程"
    else
        yellow "⊘ 无需清理的用户进程"
    fi
}

# 清理磁盘文件
clean_files() {
    local keep_config="$1"
    
    yellow "正在清理磁盘文件..."
    
    # 删除所有非隐藏文件
    rm -rf "$HOME"/* 2>/dev/null || true
    
    if [[ "$keep_config" == "n" ]]; then
        # 完全清理模式：删除所有隐藏文件，但保留关键配置
        local protected=(".ssh" ".bashrc" ".profile" ".bash_profile" ".bash_logout")
        
        for item in "$HOME"/.*; do
            local base=$(basename "$item")
            
            # 跳过 . 和 ..
            [[ "$base" == "." || "$base" == ".." ]] && continue
            
            # 检查是否在保护列表中
            local skip=false
            for protected_item in "${protected[@]}"; do
                if [[ "$base" == "$protected_item" ]]; then
                    skip=true
                    break
                fi
            done
            
            # 删除非保护项
            if [[ "$skip" == "false" ]]; then
                rm -rf "$item" 2>/dev/null || true
            fi
        done
        
        green "✓ 已清理所有文件（保留 .ssh 和 shell 配置）"
    else
        # 安全模式：只删除非隐藏文件和常见缓存目录
        rm -rf "$HOME"/.cache 2>/dev/null || true
        rm -rf "$HOME"/.local 2>/dev/null || true
        rm -rf "$HOME"/.npm 2>/dev/null || true
        rm -rf "$HOME"/.pip 2>/dev/null || true
        rm -rf "$HOME"/go 2>/dev/null || true
        rm -rf "$HOME"/node_modules 2>/dev/null || true
        
        green "✓ 已清理可见文件和缓存（保留隐藏配置）"
    fi
}

# 主恢复函数
reset_system() {
    show_banner
    
    red "⚠️  警告：此操作将执行以下清理 ⚠️"
    echo "  • 删除所有 Cron 定时任务"
    echo "  • 终止所有用户后台进程"
    echo "  • 清空磁盘文件（可选保留配置）"
    echo ""
    
    read -p "$(red '是否继续？[y/N]: ')" confirm
    confirm=${confirm:-n}
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        yellow "操作已取消"
        return
    fi
    
    echo ""
    read -p "$(blue '是否保留配置文件（.bashrc/.profile/.ssh 等）？[Y/n]: ')" keep
    keep=${keep:-y}
    
    echo ""
    yellow "========================================="
    yellow "开始执行系统恢复..."
    yellow "========================================="
    
    # 执行清理（允许单步失败）
    set +e
    
    clean_cron
    echo ""
    
    clean_processes
    echo ""
    
    clean_files "$keep"
    echo ""
    
    set -e
    
    green "========================================="
    green "✅ 系统恢复完成！"
    green "========================================="
    
    if [[ "$keep" == "y" || "$keep" == "Y" ]]; then
        yellow "提示：已保留 SSH 配置和 shell 配置文件"
    else
        yellow "提示：仅保留了 .ssh 和必要的 shell 配置"
    fi
}

# 显示菜单
show_menu() {
    show_banner
    echo "请选择操作："
    echo ""
    echo "  1) 恢复系统（清理 Cron + 进程 + 文件）"
    echo "  2) 仅清理 Cron 任务"
    echo "  3) 退出"
    echo ""
    echo "========================================="
    read -p "$(blue '请输入选项 [1-3]: ')" choice
}

# 主循环
main() {
    while true; do
        show_menu
        
        case $choice in
            1)
                reset_system
                ;;
            2)
                show_banner
                clean_cron
                ;;
            3)
                yellow "感谢使用，再见！"
                exit 0
                ;;
            *)
                red "无效选项，请输入 1-3"
                ;;
        esac
        
        echo ""
        read -p "$(yellow '按 Enter 返回菜单...')"
    done
}

# 脚本入口
main
