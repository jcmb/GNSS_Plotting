set datafile separator ","
set terminal png size 800,600 noenhanced
#font '/usr/share/fonts/msttcorefonts/arial.ttf' 10
set xtics border mirror 
set grid xtics ytics lt 9
set mxtics 5
set y2tics

set style data lines
set xlabel "GPS Time"
set ylabel "Error (m)"
set y2label "Time (s)"


set yrange [0.00:vrange]


set xdata time
set timefmt "%s"
set format x "%H:%M"

set output "U_Range_2Sigma.png"
set title name."U Errors >3cm (2 Sigma)"
set ytics add (0.03, -0.03)

plot \
    'range2.csv' using ($1):($2) title "Error", \
    'range2.csv' using ($1):($5) axes x1y2 title "Time"


set ytics

set ytics add (0.045, -0.045)

set output "U_Range_3Sigma.png"
set title name."U Errors >4.5cm (3 Sigma)"

plot \
    'range3.csv' using ($1):($2) title "Error", \
    'range3.csv' using ($1):($5) axes x1y2 title "Time"


quit