# Quick Start / 极简启动指南

## English
1. Download the repository ZIP and extract it. Rename the extracted folder to **`360_W370_Ghost_root`**.
2. Move the `360_W370_Ghost_root` folder to the root of your device's internal storage. (The final path MUST be `/sdcard/360_W370_Ghost_root/`).
3. Download `Cli32` and place it inside the `scripts` folder (e.g., `/sdcard/360_W370_Ghost_root/scripts/Cli32`).
4. Open a terminal with `uid=2000(shell)` (e.g., aShell You) and run:
   `sh /sdcard/360_W370_Ghost_root/scripts/wake.sh`
5. Execute any command as root (Note: the `sh` prefix is ALWAYS required):
   `sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"`

* **Note for Font Changer:** Running the font script will restart the UI and cause Shizuku to lose its shell privileges. You must reboot the watch and re-activate Shizuku afterwards.

## 中文
1. 下载本仓库的 ZIP 压缩包并解压。将解压出来的文件夹重命名为 **`360_W370_Ghost_root`**。
2. 将这个文件夹移动到手机内部存储的根目录（最终路径**必须**是 `/sdcard/360_W370_Ghost_root/`）。
3. 下载 `Cli32` 并把它放进 `scripts` 文件夹内（即 `/sdcard/360_W370_Ghost_root/scripts/Cli32`）。
4. 打开拥有 `uid=2000(shell)` 权限的终端，运行以下命令以部署并启动 Root 通道：
   `sh /sdcard/360_W370_Ghost_root/scripts/wake.sh`
5. 通过包装脚本以 Root 身份执行命令（执行命令时必须加上 `sh` 前缀）：
   `sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"`

* **换字体注意事项**：运行字体替换脚本刷新 UI 后，会导致 Shizuku 的 shell 权限丢失。你必须重启手表，重新激活 Shizuku，然后再恢复 Root。
