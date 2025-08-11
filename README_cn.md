serv00 系统重置脚本
快速启动
bash
复制
编辑
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
简介
serv00 是一个轻量且实用的系统重置脚本，专为通过 SSH 远程快速初始化和清理服务器而设计。
它集成了基本的清理功能，并添加多重确认机制以防止误删数据。

功能特性
简洁易用的命令行交互界面

彩色输出提升阅读体验

操作前多重确认，避免误操作

可选择保留用户配置信息

清理任务涵盖：

计划任务（cron）清空

用户进程强制终止

用户主目录清理

安装与使用
请参考快速启动章节进行立即使用。

如需更多控制，可以将脚本移动到系统 PATH 或创建别名，详见高级配置。

高级配置
将脚本移动到系统路径，方便调用：

bash
复制
编辑
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
或在 .bashrc 添加别名：

bash
复制
编辑
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
注意事项
⚠️ 本脚本将执行不可逆的数据删除操作，请务必提前备份重要文件。

贡献
欢迎提出 issue 和 pull request。
请遵守贡献指南与行为准则。

许可证
本项目采用 MIT 许可证，详情请见 LICENSE 文件。
