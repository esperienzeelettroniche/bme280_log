#!/bin/bash

DATAFILE=plotdata.dat
PLOTFILE=plotgraph.plt

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

PLOT_START=$(date +%s -d "$(echo $PLOT_START | cut -d '/' -f 3 | cut -d ' ' -f 1)/$(echo $PLOT_START | cut -d '/' -f 2)/$(echo $PLOT_START | cut -d '/' -f 1) $(echo $PLOT_START | cut -d ' ' -f 2)")
PLOT_END=$(date +%s -d "$(echo $PLOT_END | cut -d '/' -f 3 | cut -d ' ' -f 1)/$(echo $PLOT_END | cut -d '/' -f 2)/$(echo $PLOT_END | cut -d '/' -f 1) $(echo $PLOT_END | cut -d ' ' -f 2)")
sed -i "s/xrange \[.*\]/xrange \[$PLOT_START:$PLOT_END\]/" $PLOTFILE

echo "Smoot mode [C(spline) or B(ezier)]?"
read SMOOTH_MODE
if [[ $SMOOTH_MODE == "C" || $SMOOTH_MODE == "c" ]];then
	sed -i 's/bezier/cspline/g' $PLOTFILE
fi
if [[ $SMOOTH_MODE == "B" || $SMOOTH_MODE == 'b' ]];then
	sed -i 's/cspline/bezier/g' $PLOTFILE
fi

echo "Temp min.:"
read TEMP_MIN
echo "Temp max.:"
read TEMP_MAX
#if [[ $TEMP_MIN != "" ]]; then
	sed -i "s/temp_min\=\".*\"/temp_min=\"$TEMP_MIN\"/" $PLOTFILE
	sed -i "s/temp_max\=\".*\"/temp_max=\"$TEMP_MAX\"/" $PLOTFILE
#fi

echo "Humidity min.:"
read HUM_MIN
echo "Humidity max.:"
read HUM_MAX
#if [[ $HUM_MIN != "" ]]; then
	sed -i "s/hum_min\=\".*\"/hum_min=\"$HUM_MIN\"/" $PLOTFILE
	sed -i "s/hum_max\=\".*\"/hum_max=\"$HUM_MAX\"/" $PLOTFILE
#fi

echo "Pressure min.:"
read PRESS_MIN
echo "Pressure max.:"
read PRESS_MAX
#if [[ $PRESS_MIN != "" ]]; then
	sed -i "s/press_min\=\".*\"/press_min=\"$PRESS_MIN\"/" $PLOTFILE
	sed -i "s/press_max\=\".*\"/press_max=\"$PRESS_MAX\"/" $PLOTFILE
#fi
echo "Plotting data..."

gnuplot $PLOTFILE
