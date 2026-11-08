#!/system/bin/sh
# 字体文件和本脚本放在同一个目录
DIR="/sdcard/360_W370_Ghost_root/tools/change_font"
ROOTCMD="/sdcard/360_W370_Ghost_root/scripts/rootcmd"
FONT_DIR="/data/local/tmp/fonts"
SYS_FONT="/system/fonts/NotoSansCJK-Regular.ttc"

echo "[-] Scanning for font files in $DIR..."

COUNT=0
for f in "$DIR"/*.ttf "$DIR"/*.ttc; do
    if [ -f "$f" ]; then
        COUNT=$((COUNT+1))
        echo "  $COUNT) $(basename "$f")"
    fi
done

if [ "$COUNT" -eq 0 ]; then
    echo "[-] Error: No .ttf or .ttc font files found in $DIR"
    echo "[-] Please place your font files in the directory above."
    exit 1
fi

echo ""
echo -n "Enter the number of the font to apply (1-$COUNT): "
read choice

case "$choice" in
    ''|*[!0-9]*) 
        echo ""
        echo "[-] Error: Invalid input. Please enter a number."
        exit 1
        ;;
esac

INDEX=0
SELECTED=""
for f in "$DIR"/*.ttf "$DIR"/*.ttc; do
    if [ -f "$f" ]; then
        INDEX=$((INDEX+1))
        if [ "$INDEX" -eq "$choice" ]; then
            SELECTED="$f"
            break
        fi
    fi
done

if [ -z "$SELECTED" ]; then
    echo "[-] Error: Number out of range."
    exit 1
fi

echo "[-] Selected font: $(basename "$SELECTED")"

FONT_SRC="$SELECTED"
FONT_DEST="$FONT_DIR/current_font.ttf"

echo "[-] Preparing font file..."
sh $ROOTCMD "mkdir -p $FONT_DIR"
sh $ROOTCMD "cp \"$FONT_SRC\" $FONT_DEST"
sh $ROOTCMD "chmod 644 $FONT_DEST"

echo "[-] Mounting new font to system (NotoSansCJK only)..."
sh $ROOTCMD "mount --bind $FONT_DEST $SYS_FONT"

echo "[-] Refreshing UI (screen will flash for a few seconds)..."
sh $ROOTCMD "killall system_server"

echo "[-] Done! If it fails, check if the Root channel is active."
