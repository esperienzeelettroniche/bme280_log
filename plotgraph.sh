#!/bin/bash

DATAFILE=plotdata.dat
FORMAT="%d/%m/%Y %H:%M"

if [ $# -eq 0 ]; then
	echo "Usage: plotgraph <file>"
	exit 1
else
	if [ -f $1 ]; then
		# Cleanup input file and save as DATAFILE
		cat $1 | sed -E -n '/[0-9]+ [0-9]{2,2}\.[0-9]{2,2}/p' > $DATAFILE

		# Find logging start and end
		LOG_START=$(head -n 1 $DATAFILE | cut -d ' ' -f 1)
		LOG_START=$(date -d @$LOG_START +"$FORMAT")
		LOG_END=$(tail -n 1 $DATAFILE | cut -d ' ' -f 1)
		LOG_END=$(date -d @$LOG_END +"$FORMAT")

		echo Log period: $LOG_START "<=====>" $LOG_END
	else
		echo Error opening $1
		exit 1
	fi
fi

echo Plot start:
read PLOT_START
if [[ $PLOT_START == "" ]]; then
	PLOT_START=$LOG_START
fi

echo Plot end:
read PLOT_END
if [[ $PLOT_END == "" ]]; then
	PLOT_END=$LOG_END
fi

PLOT_START_D=$(echo $PLOT_START | cut -d '/' -f 1)
PLOT_START_M=$(echo $PLOT_START | cut -d '/' -f 2)
PLOT_START_Y=$(echo $PLOT_START | cut -d '/' -f 3 | cut -d ' ' -f 1)
PLOT_START_T=$(echo $PLOT_START | cut -d ' ' -f 2)
PLOT_END_D=$(echo $PLOT_END| cut -d '/' -f 1)
PLOT_END_M=$(echo $PLOT_END| cut -d '/' -f 2)
PLOT_END_Y=$(echo $PLOT_END| cut -d '/' -f 3 | cut -d ' ' -f 1)
PLOT_END_T=$(echo $PLOT_END| cut -d ' ' -f 2)

PLOT_START=$(echo $PLOT_START_Y/$PLOT_START_M/$PLOT_START_D $PLOT_START_T)
PLOT_START=$(date -d "$PLOT_START" +%s)
PLOT_END=$(echo $PLOT_END_Y/$PLOT_END_M/$PLOT_END_D $PLOT_END_T)
PLOT_END=$(date -d "$PLOT_END" +%s)

sed -i "s/xrange \[.*\]/xrange \[$PLOT_START:$PLOT_END\]/" plotgraph.plt

gnuplot plotgraph.plt
