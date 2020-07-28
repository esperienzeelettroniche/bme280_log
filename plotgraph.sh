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

echo "Plot start [$LOG_START]?"
read PLOT_START
if [[ $PLOT_START == "" ]]; then
	PLOT_START=$LOG_START
fi

echo "Plot end [$LOG_END]?"
read PLOT_END
if [[ $PLOT_END == "" ]]; then
	PLOT_END=$LOG_END
fi

echo "Smoot mode [C(spline) or B(ezier)]?"
read SMOOTH_MODE
if [[ $SMOOTH_MODE == "C" || $SMOOTH_MODE == "c" ]];then
	sed -i 's/bezier/cspline/g' plotgraph.plt
fi
if [[ $SMOOTH_MODE == "B" || $SMOOTH_MODE == 'b' ]];then
	sed -i 's/cspline/bezier/g' plotgraph.plt
fi

echo "Plotting data..."

PLOT_START=$(date +%s -d "$(echo $PLOT_START | cut -d '/' -f 3 | cut -d ' ' -f 1)/$(echo $PLOT_START | cut -d '/' -f 2)/$(echo $PLOT_START | cut -d '/' -f 1) $(echo $PLOT_START | cut -d ' ' -f 2)")
PLOT_END=$(date +%s -d "$(echo $PLOT_END | cut -d '/' -f 3 | cut -d ' ' -f 1)/$(echo $PLOT_END | cut -d '/' -f 2)/$(echo $PLOT_END | cut -d '/' -f 1) $(echo $PLOT_END | cut -d ' ' -f 2)")

sed -i "s/xrange \[.*\]/xrange \[$PLOT_START:$PLOT_END\]/" plotgraph.plt

gnuplot plotgraph.plt
