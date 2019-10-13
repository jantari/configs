
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
        -fill $color6 \
        -stroke $color0 \
        -strokewidth 3 \
        -annotate 5x5+5-24 '' ~/.config/sxhkd/lock.png && \
    i3lock \
        --image="/home/jantari/.config/sxhkd/lock.png" \
        --timestr="%H:%M" \
        --insidevercolor=00000000 \
        --insidecolor=00000000 \
        --datecolor=00000000 \
        --timecolor=FFFFFFFF \
        --line-uses-ring \
        --radius=10\
        --veriftext='' \
        --wrongtext='' \
        #--clock
fi

#-draw "circle 2000,720 2000,760" \

