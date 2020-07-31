set datafile commentschars "#"
set timefmt "%s"
set xdata time
set xrange [1596009480:1596054660]
set format x "%d/%m\n%H:%M"
set grid xtics lt -1 lw 1
#set grid mxtics
set grid ytics lt -1 lw 1
set samples 1000
set autoscale y

temp_bg="yellow"
press_bg="orange"
hum_bg="green"
temp_min=""
temp_max=""
hum_min=""
hum_max=""
press_min=""
press_max=""

set key box opaque font "arial, 25" spacing 1.5

set term svg background rgb "white" size 1980,1020 dynamic enhanced font "arial,20"

set out "temp.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb temp_bg behind
if ( temp_min eq "" ){
	set autoscale y
}else{
	set yrange [ temp_min : temp_max ]
}
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth cspline title "Temperatura"

set out "hum.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb hum_bg behind
if ( hum_min eq "" ){
	set autoscale y
}else{
	set yrange [ hum_min : hum_max ]
}
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth cspline title "Umidita'"

set out "press.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb press_bg behind
if ( press_min eq "" ){
	set autoscale y
}else{
	set yrange [ press_min : press_max ]
}
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth cspline title "Pressione"

set autoscale y
set term png background rgb "white" size 1920,1080 enhanced font "arial,20"

set out "temp.png"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb temp_bg behind
if ( temp_min eq "" ){
	set autoscale y
}else{
	set yrange [ temp_min : temp_max ]
}
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth cspline title "Temperatura"

set out "hum.png"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb hum_bg behind
if ( hum_min eq "" ){
	set autoscale y
}else{
	set yrange [ hum_min : hum_max ]
}
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth cspline title "Umidita'"

set out "press.png"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb press_bg behind
if ( press_min eq "" ){
	set autoscale y
}else{
	set yrange [ press_min : press_max ]
}
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth cspline title "Pressione"
