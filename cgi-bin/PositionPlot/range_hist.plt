set datafile separator ","
set terminal png size 800,600 noenhanced
#font '/usr/share/fonts/msttcorefonts/arial.ttf' 10
set xtics border mirror 
set grid xtics ytics lt 9
set mxtics 5
set y2tics

set style data boxes
set xlabel "GPS Time"
set ylabel "Error (m)"
set yrange[-vrange:vrange]
set xdata time
set timefmt "%s"
set format x "%H:%M"

set output "U_Hist_2Sigma.png"
set title name."U Errors >3cm (2 Sigma)"

plot 'outage2.csv' using ($1):($2):($3) title "Error"



set ytics add (0.045, -0.045)

set output "U_Hist_3Sigma.png"
set title name."U Errors >4.5cm (3 Sigma)"

plot 'outage3.csv' using ($1):($2):($3) title "Error"





quit