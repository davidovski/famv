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

	ffmpeg $FOPTS $DECODER -i $AUDIOFILE -af lowpass=f=200 $ENCODER $BASS_FILE
	ffmpeg -i $BASS_FILE -af astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=$BASS_LOG -f null -

	filter_line() 
	{ 
		V="$2^4"
		SHIFT=20
		echo "$1 rgbashift bh '$V * $SHIFT';"
		echo "$1 rgbashift rh '$V * -$SHIFT';"
	#crop=in_h*9/16:in_h,scale=-2:400
	#echo "$1 crop w 'iw *(1- $2)';"
	#echo "$1 crop h 'ih *(1- $2)';"
	} 

	read_value() {
		p=$( echo "$1" | sed 's/.*=//' | sed 's/-//')
		if [[ $p = "inf" || $( bc -l <<< "p > 100" ) -eq 1 ]]; then
			p=100
		fi
		
		value=$( ( echo "1.0 - ($p / 100.0)" | bc -l ) | sed 's/\n//')
		echo "$value";
	}

	MAX=100
	MIN=0

	rm $OF
	touch $OF

	SIZE=$( wc -l $BASS_LOG )

	# Parse the bass log and create a filter file
	i=0
	while read line; do
		timecode=$(printf "$line" | sed 's:.*\:::')
		read p
		value=$( echo "($( read_value $p) )" | bc -l )
		
		echo "$(filter_line $timecode $value)" >> $OF

		((i=i+2))
		echo -ne "$i / $SIZE      \r"

	done < $BASS_LOG

	# Apply the filter file onto the final product
	ffmpeg $FOPTS $DECODER  -i $VIDEOFILE -filter_complex "[0:v]sendcmd=f=$OF,rgbashift" $ENCODER $DEST
	
}
