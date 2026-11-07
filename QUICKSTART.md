# Quick Start / 极简启动指南

## English
1. Open a terminal with `uid=2000(shell)` (e.g., aShell You).
2. Run the following command to deploy and activate the root channel:
   `sh /sdcard/360_W370_Ghost_root/scripts/wake.sh`
3. Execute any command as root via the wrapper script (Note: the `sh` prefix is ALWAYS required because `/sdcard` is mounted as `noexec`):
   `sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"`

## 中文
1. 打开拥有 `uid=2000(shell)` 权限的终端（如 aShell You）。
2. 输入以下命令以部署并启动 Root 通道：
   `sh /sdcard/360_W370_Ghost_root/scripts/wake.sh`
3. 通过包装脚本以 Root 身份执行命令（注意：因为 `/sdcard` 是 noexec 挂载，执行命令时必须加上 `sh` 前缀）：
   `sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"`