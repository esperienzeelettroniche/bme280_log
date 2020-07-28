#!/bin/bash

DATAFILE=plotdata.dat
FORMAT="%d/%m/%Y %H:%M"

if [ $# -eq 0 ]; then
	echo "Usage: $0 <file>"
	exit 1
else
	if [ -f $1 ]; then
		# Cleanup input file and save as DATAFILE
		cat $1 | sed -E -n '/[0-9]+ [0-9]{2,2}\.[0-9]{2,2}/p' > $DATAFILE

		# Find logging start and end
		LOG_START=$(date +"$FORMAT" -d @$(head -n 1 $DATAFILE | cut -d ' ' -f 1))
		LOG_END=$(date +"$FORMAT" -d @$(tail -n 1 $DATAFILE | cut -d ' ' -f 1))

		echo Log period: $LOG_START "<=====>" $LOG_END
	else
		echo Error opening $1
		exit 1
	fi
fi

echo "Plot start ($LOG_START):"
read PLOT_START
if [[ $PLOT_START == "" ]]; then
	PLOT_START=$LOG_START
fi

echo "Plot end ($LOG_END):"
read PLOT_END
if [[ $PLOT_END == "" ]]; then
	PLOT_END=$LOG_END
fi

echo "Smoot mode < c (cspline) or b (bezier) >"
read SMOOTH_MODE
if [[ $SMOOTH_MODE == "c" ]];then
	sed -i 's/bezier/cspline/g' plotgraph.plt
fi
if [[ $SMOOTH_MODE == "b" ]];then
	sed -i 's/cspline/bezier/g' plotgraph.plt
fi

PLOT_START_D=$(echo $PLOT_START | cut -d '/' -f 1)
PLOT_START_M=$(echo $PLOT_START | cut -d '/' -f 2)
PLOT_START_Y=$(echo $PLOT_START | cut -d '/' -f 3 | cut -d ' ' -f 1)
PLOT_START_T=$(echo $PLOT_START | cut -d ' ' -f 2)
PLOT_END_D=$(echo $PLOT_END| cut -d '/' -f 1)
PLOT_END_M=$(echo $PLOT_END| cut -d '/' -f 2)
PLOT_END_Y=$(echo $PLOT_END| cut -d '/' -f 3 | cut -d ' ' -f 1)
PLOT_END_T=$(echo $PLOT_END| cut -d ' ' -f 2)

PLOT_START=$(date +%s -d "$(echo $PLOT_START_Y/$PLOT_START_M/$PLOT_START_D $PLOT_START_T)")
PLOT_END=$(date +%s -d "$(echo $PLOT_END_Y/$PLOT_END_M/$PLOT_END_D $PLOT_END_T)")

sed -i "s/xrange \[.*\]/xrange \[$PLOT_START:$PLOT_END\]/" plotgraph.plt

gnuplot plotgraph.plt
