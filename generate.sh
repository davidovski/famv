#!/bin/bash

# Make some constants
FPS=60
TEMPDIR=/tmp/famv
INPUTWAV=song.wav
INPUTBG=bg.jpg
OUTPUT=output.mp4


mkdir $TEMPDIR

# Find colour that matches best with image
#TODO
COLOR=FFFFFFFF

# Generate background video
#TODO with bouncy / saturation brightness on bass thin
BG_IMG=$TEMPDIR/bg.jpg
convert $INPUTBG -resize 1920x1080 $BG 


IMAGE_HEIGHT=400
# Render mode 2 is mirrored one
RENDER_MODE=0
BAR_COUNT=80
BAR_SIZE=16
GAP_SIZE=8

# 0-1, more blend, kinda smoother(?)
BLEND=0.9


BARSFILE=$TEMPDIR/bars.mp4
# Creating temp img sequence in /tmp (more options to be added here)

mkdir $TEMPDIR/frames
rm $TEMPDIR/frames/*
fft2png -R$RENDER_MODE -s$GAP_SIZE -w$BAR_SIZE -c$BAR_COUNT -b$BLEND --image-height $IMAGE_HEIGHT --framerate $FPS -i $INPUTWAV -o $TEMPDIR/output-{:06}.png


# use ffpmeg to genereate an output mp4 file
ffmpeg -y -framerate $FPS -i $TEMPDIR/output-%06d.png -vf vflip $BARSFILE

# place this genereated file onto the background
#TODO

ffmpeg -y -i $BG -i $BARSFILE -filter_complex "[1:v]colorkey=0x000000:0.1:0.1[t];[0][t]overlay=y=540[out]" -map [out] -t 5 $TEMPDIR/combined.mp4




# decorate with 
#TODO4


#add audio
ffmpeg -y -i $TEMPDIR/combined.mp4 -i $INPUTWAV -c:v libx264 $OUTPUT
