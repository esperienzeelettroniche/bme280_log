set timefmt "%s"
set xdata time
set xrange [1595760720:1595775360]
set format x "%H:%M"
set grid xtics lt -1 lw 1
set grid mxtics
set grid ytics lt -1 lw 1
set samples 1000
set autoscale y
set key box font "arial, 20" spacing 1.5

set term svg size 1980,1020 dynamic enhanced font "arial,20"

set out "temp.svg"
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth cspline title "Temperatura"

set out "hum.svg"
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth cspline title "Umidita' "

set out "press.svg"
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth cspline title "Pressione"

set autoscale y
set term png size 1920,1080 enhanced font "arial,25"
set key box

set out "temp.png"
plot "plotdata.dat" using 1:2 with lines lt 7 lw 2 smooth cspline title "Temperatura"

set out "hum.png"
plot "plotdata.dat" using 1:3 with lines lt 1 lw 2 smooth cspline title "Umidita' "

set out "press.png"
plot "plotdata.dat" using 1:5 with lines lt 2 lw 2 smooth cspline title "Pressione"
