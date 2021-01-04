#!/bin/bash

bounce_filter() {
	VIDEOFILE=$1
	AUDIOFILE=$2
	DEST=$3

	BASS_FILE=$TEMPDIR/bass.wav
	MAX=100
	MIN=0
	OF=$TEMPDIR/filter_script.txt
	BASS_LOG=$TEMPDIR/log.txt
	echo "Making lowpass version of song.wav"
	ffmpeg $FOPTS  -i $AUDIOFILE -af "[0]lowpass=f=100[o1]"  $BASS_FILE

	echo "Gathering data for the bass"
	ffmpeg $FOPTS -i $BASS_FILE -af astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=$BASS_LOG -f null -

	filter_line() 
	{ 
		V="$2^20"
		SHIFT=40
		echo "$1 rgbashift bh '$V * $SHIFT';"
		echo "$1 rgbashift rh '$V * -$SHIFT';"
	#crop=in_h*9/16:in_h,scale=-2:400
	#echo "$1 crop w 'iw *(1- $2)';"
	#echo "$1 crop h 'ih *(1- $2)';"
	} 

	read_value() {
		p=$(sed 's/.*-//' <<< $1)

		if [[ $p = "inf" ]]; then
			echo 0
		else		
			echo "if ($p < 100.0) (1.0 - ($p / 100.0)) else (0)" | bc -l

		fi
	}

	MAX=100
	MIN=0

	rm $OF
	touch $OF

	SIZE=$( wc -l $BASS_LOG )

	# Parse the bass log and create a filter file
	echo "Parsing bass levels and creating the filter"
	time(
	i=0
	while read line; do
		timecode=$( sed 's:.*\:::' <<< $line )
		read p
		value=$( read_value $p )
		
		echo "$( filter_line $timecode $value )" >> $OF

		((i=i+2))
		echo -ne "$i / $SIZE      \r"

	done < $BASS_LOG

)
	# Apply the filter file onto the final product
	echo "Applying filter" 
	ffmpeg $FOPTS $DECODER  -i $VIDEOFILE -filter_complex "[0:v]sendcmd=f=$OF,rgbashift" $ENCODER $DEST
	
}
