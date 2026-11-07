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

# 去掉了 2>/dev/null
rm -f "$DIR/cmd.txt" "$DIR/out.txt"

setprop persist.sys.cmdservice.enable enable
sleep 1
echo "[-] Triggering root service..."

# 这里保留 2>&1 和 grep，因为它们是过滤 Cli32 报错的核心
echo "nohup sh $DIR/daemon.sh >/dev/null 2>&1 &" | /data/local/tmp/Cli32 2>&1 | grep -v -E "Error reading input|Try again"

echo "[-] Root channel is ready! Deployed at: $DIR"