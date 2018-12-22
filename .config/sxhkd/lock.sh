
source ~/.cache/wal/colors.sh

if [ "$1" = "blur" ];
    then
    # Blur effect
    i3lock --blur 5
else
    # Pixelate effect
    maim -u | convert png:- \
        -scale 20% \
        -scale 500% \
        -gravity center \
        -pointsize 160 \
        -font FontAwesome \
        -fill $color7 \
        -stroke $color0 \
        -strokewidth 4 \
        -annotate +0+100 '' ~/Pictures/lock.png && \
    i3lock \
        --image="/home/jantari/Pictures/lock.png" \
        --clock \
        --timestr="%H:%M" \
        --datecolor=00000000 \
        --timecolor=FFFFFFFF \
        #--timepos="x+155:y+624" \
        #--indpos="x+50:y+614" \
        --radius=25 \
        --veriftext='' \
        --wrongtext=''
fi

#-draw "circle 2000,720 2000,760" \

