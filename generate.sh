#!/bin/bash

# Make some constants
FPS=60
TEMPDIR=/tmp/famv
INPUTWAV=song.wav
INPUTBG=bg.jpg
OUTPUT=output.mp4

FOPTS="-vsync 0 -y"

ENCODER="-c:v libx264"
### Uncomment if you are using a gpu with CUDA
#FOPTS="-hwaccel cuvid $FOPTS"
#ENCODER="-c:v h264_nvenc"
#DECODER="-c:v h264_cuvid"
##############



# Make the temporary directory
mkdir $TEMPDIR

# Find colour that matches best with image
#TODO
COLOR=FFFFFFFF


# Generate background video
#TODO with bouncy / saturation brightness on bass thin
BG_STILL=$TEMPDIR/bg_still.mp4

BG=$TEMPDIR/bg.mp4

ffmpeg $FOPTS -loop 1 -i $INPUTBG -i $INPUTWAV -vf scale=1920:1080 -shortest $BG_STILL

source bounce.sh
bounce_filter $BG_STILL $INPUTWAV $BG


# Make Bars 
IMAGE_HEIGHT=400

RENDER_MODE=0
#BAR_SIZE=16
#GAP_SIZE=8
#BAR_COUNT=80

BAR_SIZE=4
GAP_SIZE=16
#BAR_SIZE=12
#GAP_SIZE=0
BAR_COUNT=$( bc <<< "1920 / ($BAR_SIZE + $GAP_SIZE)" )
echo "making $BAR_COUNT bars"

# 0-1, more blend, kinda smoother(?)
BLEND=0.2


BARSFILE=$TEMPDIR/bars.mp4
# Creating temp img sequence in /tmp (more options to be added here)

mkdir $TEMPDIR/frames
rm $TEMPDIR/frames/*
fft2png -R$RENDER_MODE -s$GAP_SIZE -w$BAR_SIZE -c$BAR_COUNT -b$BLEND --image-height $IMAGE_HEIGHT --framerate $FPS -i $INPUTWAV -o $TEMPDIR/frames/output-{:06}.png


# use ffpmeg to genereate an output mp4 file
ffmpeg $FOPTS $DECODER -framerate $FPS -i $TEMPDIR/frames/output-%06d.png $ENCODER $BARSFILE

# place this genereated file onto the background

#TRANSPOSE="=y=540"
TRANSPOSE="=y=680"

ffmpeg $FOPTS $DECODER -i $BG -i $BARSFILE -filter_complex "[1:v]colorkey=0x000000:0.1:0.1[t];[0][t]overlay$TRANSPOSE[out]" -map [out] $ENCODER $TEMPDIR/combined.mp4




# decorate with text and stuff 
#TODO


#add audio
ffmpeg $FOPTS $DECODER -i $TEMPDIR/combined.mp4 -i $INPUTWAV $ENCODER $OUTPUT


# Things that might come in handy...

#motion blur?
#ffmpeg -i in.mp4 -vf minterpolate=50,tblend=all_mode=average,framestep=2 out.mp4

