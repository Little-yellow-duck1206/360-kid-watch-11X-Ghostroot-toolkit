# 360 11X W370 GhostRoot (CVE-2025-31710)

A stealthy, persistent Local Privilege Escalation (LPE) research tool for the 360 11X W370 smartwatch (Unisoc SC8541E, Android 8.1, 32-bit ARM). It achieves root access without a PC, without unlocking the bootloader, and without modifying the system partition.

## Disclaimer and Compliance
FOR EDUCATIONAL AND RESEARCH PURPOSES ONLY. 
This project is a Local Privilege Escalation (LPE) tool and requires a pre-existing local shell with uid=2000(shell). It is NOT a remote exploit, nor is it an automated jailbreak for general consumer devices. Please DO NOT use this tool on any device you do not own or have explicit permission to test. 

The exploitation of CVE-2025-31710 has been publicly documented and prior work by Skorpion96 was authorized by Unisoc for publication. This repository implements an alternative post-exploitation persistence mechanism (GhostRoot) on top of that vulnerability.

## Overview
This project exploits CVE-2025-31710, a command injection vulnerability in the Unisoc com.sprd.engineermode application. The exploit leverages a trusted socket (cmd_skt) belonging to the root-level cmd_services to execute commands with the highly privileged u:r:cmd_services:s0 SELinux context.

Because the target device aggressively kills background apps and locks the /system partition (dm-verity), traditional root methods (like Magisk or modifying /system/bin/su) are either impossible or highly risky. 

This repository implements GhostRoot: a file-based background daemon that survives app-killing, does not require TTY interaction, and can be revived instantly after a reboot.

## Vulnerability Mechanics & Design Trade-offs
### Why cmd_skt?
In the Unisoc platform, cmd_services runs as root and listens on the cmd_skt abstract Unix socket. To prevent unauthorized access, it only accepts connections from trusted clients (e.g., com.sprd.engineermode). CVE-2025-31710 allows command injection via the engineermode component, enabling an attacker to communicate with cmd_skt and execute arbitrary commands in the context of cmd_services.

### Why GhostRoot (File-Based Channel)?
On the 360 11X W370, background processes are aggressively killed by the OEM's task killer. Standard reverse shells (nc, socat) or interactive TTY sessions are instantly terminated. Furthermore, Android 8.1 lacks robust terminal emulators that can hold a persistent interactive root shell without triggering SELinux denials. 

GhostRoot bypasses these limitations by using the file system as an IPC (Inter-Process Communication) channel. A background daemon (daemon.sh) runs in the root context, polling a specific text file (cmd.txt). When a command is written to the file, the root daemon executes it and writes the output to out.txt. This design ensures 100% persistence as long as the daemon is alive, with minimal attack surface and zero TTY dependency.

## Prerequisites & Toolkit
1. Shell Access: You must have a local shell running as uid=2000(shell). On the 360 11X W370, this can be achieved via Shizuku using an ADB-capable terminal app (e.g., aShell You, Termux, or ADB shell).
   * Note: Installation packages for Shizuku and aShell You are provided in the /apks folder for convenience.
   * Tip: If you are unsure how to enable USB debugging and use ADB to install third-party applications on this watch, you can find relevant video tutorials on platforms like Bilibili.
2. Exploit Binary: You need the Cli32 binary (a 32-bit ARM build of cli-pie). 
   * Download it directly from TomKing062's release page: https://github.com/TomKing062/cmd_services_client/releases/tag/v0.2.2 (look for the Cli32 asset).
   * Integrity Verification (SHA-256): 3a893825922a4933035aeff6900a0ca9c816f9d159f42a20c11abae370b2268e
     * Please verify the hash before use to ensure the binary has not been tampered with.
     * On Linux/macOS: sha256sum Cli32
     * On Windows (PowerShell): Get-FileHash .\Cli32 -Algorithm SHA256
     * On Android (Termux/aShell You): sha256sum /sdcard/path/to/Cli32
3. Root Trigger: The com.sprd.engineermode package must be present (it is a system app by default).

## Repository Contents
* /apks: Contains the installation packages for Shizuku and aShell You.
* /scripts/daemon.sh: The background monitor script running in the root context.
* /scripts/rootcmd: The wrapper script to execute commands as root.
* /scripts/wake.sh: The one-click script to reactivate the root channel after a reboot.

* Note: `cmd.txt` and `out.txt` are runtime-generated IPC files. They are created and managed automatically by the scripts during execution. You do not need to create them manually. *

---

## Step-by-Step Setup Guide

### Phase 1: Preparation
1. Download `Cli32` from the release page above, verify its SHA-256 hash, and place it inside the `/scripts` folder of this repository.
2. Transfer the entire `/scripts` folder to your device (The default path assumed by the scripts is `/sdcard/360_W370_Ghost_root/scripts/`).
3. Open your terminal app and ensure you have `uid=2000(shell)`.

### Phase 2: One-Click Deployment
Because the watch kills background apps rapidly, and `/sdcard` is mounted as `noexec`, we need to move `Cli32` to a safe directory and start the background daemon. 

The provided `wake.sh` script handles this automatically. Simply run inside any shell environment with uid=2000:

   sh /sdcard/360_W370_Ghost_root/scripts/wake.sh

This script will:
1. Automatically copy `Cli32` to `/data/local/tmp/` and grant it execution permissions.
2. Trigger the root service.
3. Start the `daemon.sh` in the background.
* Note: During the deployment, you will see "Connected to the server". The script automatically filters out the natural EOF exit warnings from the socket client, so you can safely ignore any leftover terminal prompts.

### Phase 3: Usage
Once the script outputs "Root channel is ready!", you can execute any command as root via the file channel.

In a normal shell (uid=2000), run:
/sdcard/360_W370_Ghost_root/scripts/rootcmd "id"

In an unprivileged app (like MT Manager's terminal), run:
sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"

* Note: If the daemon is not running (e.g., you haven't executed `wake.sh` after a reboot), `rootcmd` will now strictly prompt an error message (`Daemon not responding`). It will NOT display stale historical results from previous sessions. *

### Phase 4: Surviving a Reboot
If the watch reboots, the daemon dies. Reopen your shell environment (uid=2000) and simply run `wake.sh` again:
sh /sdcard/360_W370_Ghost_root/scripts/wake.sh
Within 2 seconds, your root access is fully restored.

---

## Script Sources

### 1. daemon.sh
#!/system/bin/sh
DIR="/sdcard/360_W370_Ghost_root/scripts"

while true; do 
  if [ -f "$DIR/cmd.txt" ]; then 
    sh "$DIR/cmd.txt" > "$DIR/out.txt" 2>&1
    chmod 666 "$DIR/out.txt"
    rm -f "$DIR/cmd.txt"
  fi
  sleep 1
done

### 2. rootcmd
#!/system/bin/sh
DIR="/sdcard/360_W370_Ghost_root/scripts"

rm -f "$DIR/out.txt"
echo "$@" > "$DIR/cmd.txt"

if [ ! -f "$DIR/cmd.txt" ]; then
    echo "[-] Error: Cannot write cmd.txt. Permission denied."
    exit 1
fi

sleep 1.5

if [ ! -f "$DIR/out.txt" ]; then
    echo "[-] Error: Daemon not responding. Did you run wake.sh in a shell with uid=2000?"
    exit 1
fi

cat "$DIR/out.txt"

### 3. wake.sh
#!/system/bin/sh
DIR="/sdcard/360_W370_Ghost_root/scripts"

CURRENT_UID=$(id -u)
if [ "$CURRENT_UID" != "2000" ] && [ "$CURRENT_UID" != "0" ]; then
    echo "[-] Error: Permission denied."
    echo "[-] This script MUST be run in a shell environment with uid=2000."
    exit 1
fi

if [ -f "$DIR/Cli32" ]; then
    echo "[-] Found Cli32 in current directory, deploying to /data/local/tmp..."
    mkdir -p /data/local/tmp
    cp "$DIR/Cli32" /data/local/tmp/Cli32
    chmod 755 /data/local/tmp/Cli32
fi

if [ ! -f "/data/local/tmp/Cli32" ]; then
    echo "[-] Error: /data/local/tmp/Cli32 not found. Deployment failed."
    exit 1
fi

rm -f "$DIR/cmd.txt" "$DIR/out.txt"

setprop persist.sys.cmdservice.enable enable
sleep 1
echo "[-] Triggering root service..."
echo "nohup sh $DIR/daemon.sh >/dev/null 2>&1 &" | /data/local/tmp/Cli32 2>&1 | grep -v -E "Error reading input|Try again"

echo "[-] Root channel is ready! Deployed at: $DIR"

---

## Warnings & Limitations
* DO NOT attempt to run "mount -o remount,rw /system". The system is protected by dm-verity. Attempting to write to /system will cause a bootloop.
* DO NOT attempt to flash a patched boot.img unless the bootloader is explicitly unlocked. 
* This is a temporary root (until reboot) that can be instantly revived via wake.sh. Because it runs under cmd_services, it bypasses standard Android SELinux restrictions, allowing access to /data/data/ and system app modifications.
* No TTY support: interactive commands like top or vi will not render correctly through the file channel.
* Compatibility: This tool is specifically tested on the 360 11X W370 (Unisoc SC8541E, Android 8.1). Behavior on other Unisoc-based wearables is unknown and untested.

---

## Credits & Acknowledgements
* Vulnerability Discovery: Skorpion96 (CVE-2025-31710).
* Exploit Client: TomKing062 (cli-pie).
* GhostRoot Architecture & Implementation: Developed through a collaborative debugging and reverse-engineering session with DeepSeek (AI Assistant). The file-channel daemon workaround was co-designed to bypass aggressive app-killing and non-TTY limitations on the 360 11X W370.

If you find any errors or have any questions, please feel free to send an email to huangxuanran.china@gmail.com for corrections.

---
---

# 360 11X W370 幽灵Root提权工具 (CVE-2025-31710)

一款针对 360 11X W370 智能手表（展锐 SC8541E，Android 8.1，32位 ARM）的隐蔽、持久化本地提权（LPE）研究工具。它无需电脑、无需解锁 Bootloader，且不会修改系统分区即可获取 Root 权限。

## 免责声明与合规性
仅供教育和研究目的使用。
本项目是一个本地提权（LPE）工具，需要设备上已有 uid=2000(shell) 的本地终端环境。它不是远程漏洞利用，也不是针对普通消费设备的自动化越狱工具。请勿在您不拥有或未经授权测试的设备上使用此工具。

CVE-2025-31710 的利用细节已被公开记录，且 Skorpion96 的早期工作已获得展锐（Unisoc）的发布授权。本仓库在该漏洞的基础上，实现了一种替代的“后利用”持久化机制（即 GhostRoot）。

## 概述
本项目利用了展锐 com.sprd.engineermode 应用中的命令注入漏洞 CVE-2025-31710。该漏洞利用属于 root 级别服务 cmd_services 的受信任套接字（cmd_skt），以极高特权的 u:r:cmd_services:s0 SELinux 上下文执行命令。

由于目标设备会激进地查杀后台应用，并锁定 /system 分区（dm-verity），传统的 Root 方法（如 Magisk 或修改 /system/bin/su）要么不可行，要么风险极高。

本仓库实现了 GhostRoot（幽灵Root）：一个基于文件的驻留后台服务，它可以抵抗后台查杀，无需交互式终端（TTY）支持，并且可以在重启后瞬间复活。

## 漏洞原理与设计权衡
### 为什么是 cmd_skt？
在展锐平台中，cmd_services 以 root 权限运行，并监听 cmd_skt 抽象 Unix 套接字。为了防止未授权访问，它仅接受受信任客户端（如 com.sprd.engineermode）的连接。CVE-2025-31710 允许通过 engineermode 组件进行命令注入，使攻击者能够与 cmd_skt 通信，并在 cmd_services 的上下文中执行任意命令。

### 为什么采用 GhostRoot（基于文件通道）？
在 360 11X W370 上，后台进程会被厂商的任务查杀器无情干掉。标准的反弹 Shell（nc, socat）或交互式 TTY 会话会瞬间终止。此外，Android 8.1 缺乏能维持持久交互式 Root Shell 且不触发 SELinux 拒绝的健壮终端模拟器。

GhostRoot 通过将文件系统用作 IPC（进程间通信）通道来绕过这些限制。后台守护进程（daemon.sh）在 root 上下文中运行，轮询特定的文本文件（cmd.txt）。当命令被写入文件时，root 守护进程执行它并将输出写入 out.txt。只要守护进程存活，这种设计就能确保 100% 的持久性，且具有最小的攻击面和零 TTY 依赖。

## 前置要求与工具包
1. Shell 权限：你必须拥有 uid=2000(shell) 的本地终端。在 360 11X W370 上，可以通过 Shizuku 配合支持 ADB 的终端应用（如 aShell You、Termux 或 ADB shell）来实现。
   * 注意：为了方便，/apks 文件夹中提供了 Shizuku 和 aShell You 的安装包。
   * 提示：如果你不知道如何开启 USB 调试并使用 ADB 在此手表上安装第三方应用，可以在 Bilibili 等平台搜索相关视频教程。
2. 漏洞利用二进制文件：你需要 Cli32 二进制文件（cli-pie 的 32 位 ARM 版本）。
   * 直接从 TomKing062 的发布页面下载：https://github.com/TomKing062/cmd_services_client/releases/tag/v0.2.2 （寻找 Cli32 资产）。
   * 完整性校验 (SHA-256)：3a893825922a4933035aeff6900a0ca9c816f9d159f42a20c11abae370b2268e
     * 使用前请验证哈希值，以确保二进制文件未被篡改。
     * 在 Linux/macOS 上：sha256sum Cli32
     * 在 Windows (PowerShell) 上：Get-FileHash .\Cli32 -Algorithm SHA256
     * 在 Android (Termux/aShell You) 上：sha256sum /sdcard/path/to/Cli32
3. Root 触发条件：com.sprd.engineermode 包必须存在（默认情况下它是系统应用）。

## 仓库内容
* /apks：包含 Shizuku 和 aShell You 的安装包。
* /scripts/daemon.sh：在 root 上下文中运行的后台监控脚本。
* /scripts/rootcmd：用于以 root 身份执行命令的包装脚本。
* /scripts/wake.sh：重启后一键重新激活 root 通道的脚本。

* 注意：`cmd.txt` 和 `out.txt` 是运行时生成的 IPC 文件。它们由脚本在执行过程中自动创建和管理，你不需要手动创建它们。*

---

## 逐步设置指南

### 阶段一：准备工作
1. 从上面的发布页面下载 `Cli32`，验证其 SHA-256 哈希，并将其放入本仓库的 `/scripts` 文件夹中。
2. 将整个 `/scripts` 文件夹传输到你的设备上（脚本默认假定路径为 `/sdcard/360_W370_Ghost_root/scripts/`）。
3. 打开你的终端应用，并确保你拥有 `uid=2000(shell)` 权限。

### 阶段二：一键部署
由于手表会快速杀掉后台应用，且 `/sdcard` 挂载为 `noexec`（不可执行），我们需要将 `Cli32` 移动到安全的目录并启动后台守护进程。

提供的 `wake.sh` 脚本会自动处理这一切。只需在拥有 uid=2000 权限的终端中运行：

   sh /sdcard/360_W370_Ghost_root/scripts/wake.sh

该脚本将：
1. 自动将 `Cli32` 复制到 `/data/local/tmp/` 并授予执行权限。
2. 触发 root 服务。
3. 在后台启动 `daemon.sh`。
* 注意：在部署过程中，你会看到 "Connected to the server"。脚本会自动过滤掉套接字客户端自然的 EOF 退出警告，因此你可以安全地忽略任何残留的终端提示。

### 阶段三：使用方法
一旦脚本输出 "Root channel is ready!"，你就可以通过文件通道以 root 身份执行任何命令。

在普通 Shell (uid=2000) 中，运行：
/sdcard/360_W370_Ghost_root/scripts/rootcmd "id"

在非特权应用（如 MT 管理器的终端）中，运行：
sh /sdcard/360_W370_Ghost_root/scripts/rootcmd "id"

* 注意：如果守护进程未运行（例如重启后未执行 `wake.sh`），`rootcmd` 现在会严格报错提示（`Daemon not responding`），绝不会再读取并显示上一次的历史结果。*

### 阶段四：重启后复活
如果手表重启，守护进程会死亡。重新打开你的 Shell 终端 (uid=2000) 并再次运行 `wake.sh`：
sh /sdcard/360_W370_Ghost_root/scripts/wake.sh
2秒内，你的 root 权限将完全恢复。

---

## 警告与限制
* 切勿尝试运行 "mount -o remount,rw /system"。系统受 dm-verity 保护。尝试写入 /system 会导致无限重启（变砖）。
* 除非 Bootloader 已明确解锁，否则切勿尝试刷入修补后的 boot.img。
* 这是一个临时 root（重启前有效），可以通过 wake.sh 瞬间复活。由于它在 cmd_services 下运行，它绕过了标准的 Android SELinux 限制，允许访问 /data/data/ 和修改系统应用。
* 不支持交互式终端 (TTY)：像 top 或 vi 这样的交互式命令通过文件通道无法正常显示。
* 兼容性：本工具专门在 360 11X W370（展锐 SC8541E，Android 8.1）上测试过。在其他基于展锐芯片的穿戴设备上的行为未知且未经测试。

---

## 致谢
* 漏洞发现：Skorpion96 (CVE-2025-31710)。
* 利用客户端：TomKing062 (cli-pie)。
* GhostRoot 架构与实现：通过与 DeepSeek（AI 助手）的协作调试与逆向工程会话开发完成。文件通道守护进程的变通方案是共同设计的，旨在绕过 360 11X W370 上的激进后台查杀和非 TTY 限制。

如果你发现任何错误或有任何疑问，欢迎发送邮件至 huangxuanran.china@gmail.com 进行指正。