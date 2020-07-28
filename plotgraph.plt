set timefmt "%s"
set xdata time
set xrange [1595760720:1595826000]
set format x "%d/%m\n%H:%M"
set grid xtics lt -1 lw 1
#set grid mxtics
set grid ytics lt -1 lw 1
set samples 1000
set autoscale y

set key box opaque font "arial, 25" spacing 1.5

set term svg background rgb "white" size 1980,1020 dynamic enhanced font "arial,20"

set out "temp.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb "yellow" behind
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth bezier title "Temperatura"

set out "hum.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb "green" behind
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth bezier title "Umidita'"

set out "press.svg"
set obj 1 rect from graph 0, graph 0 to graph 1, graph 1 fc rgb "orange" behind
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth bezier title "Pressione"

set autoscale y
set term png background rgb "white" size 1920,1080 enhanced font "arial,20"

set out "temp.png"
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth bezier title "Temperatura"

set out "hum.png"
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth bezier title "Umidita'"

set out "press.png"
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth bezier title "Pressione"
