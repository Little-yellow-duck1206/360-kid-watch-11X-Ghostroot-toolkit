#!/system/bin/sh
DIR="/sdcard/360_W370_Ghost_root/scripts"

while true; do 
  if [ -f "$DIR/cmd.txt" ]; then 
    sh "$DIR/cmd.txt" > "$DIR/out.txt" 2>&1
    # 去掉了 2>/dev/null
    chmod 666 "$DIR/out.txt"
    rm -f "$DIR/cmd.txt"
  fi
  sleep 1
done