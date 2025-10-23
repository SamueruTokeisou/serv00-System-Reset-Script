🌌 Serv00 星际重置
轻量级、高速脚本，用于重置 VPS，守护你的数字帝国。

  
  
  
  



  📖 查看英文版 README | 🌐 Typecho 博客 | 📝 Memos 笔记 | 📡 X



简介
Serv00 星际重置 是一个通过 SSH 快速初始化 VPS 环境的超光速工具。专为 Serv00 等平台设计，它清理杂乱数据，同时默认保护网站目录（如 Typecho、Memos）和关键配置。用精准与风格拥抱服务器管理的未来。

快速启动
一键进入星际模式：
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/serv00-reset.sh
chmod +x serv00-reset.sh
./serv00-reset.sh


功能特性

未来派 CLI：霓虹色界面，带来星际级用户体验。
网站保护：默认保留 ~/domains，守护 Typecho/Memos。
安全防护：多重确认，防止数据误删。
清理任务：
蒸发计划任务。
终止用户进程。
清理主目录，保留网站和配置。




安装说明
无缝集成到你的系统：
sudo mv serv00-reset.sh /usr/local/bin/serv00-reset

或设置星际别名：
echo "alias serv00-reset='~/serv00-reset.sh'" >> ~/.bashrc
source ~/.bashrc


注意事项
⚠️ 本脚本会删除非必要数据。启动前请备份关键文件。

贡献
加入星际使命！Fork 本仓库，提交 Pull Request，或在 X 上分享反馈。让我们共建更干净的宇宙！

  © 2025 Tokeisou Samueru · 重置星辰，征服虚空。
