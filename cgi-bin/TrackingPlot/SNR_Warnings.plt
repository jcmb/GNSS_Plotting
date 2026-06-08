set datafile separator ","
set terminal png size 800,600 noenhanced
set xtics border mirror
set grid xtics mxtics ytics
set mxtics 5

set style data lines
set xdata time
set timefmt "%s"
set format x "%H:%M"
set yrange [0:*]
set ylabel "SV's"


#Local_Time_Offset=-3600*Local_TZ
#Local_Time_Offset=0
Local_Hours=Local_Time_Offset/3600

if (Local_Time_Offset == 0) {
    set xlabel "GPS Time"
} else {
    set xlabel "Local Time TimeZone ".Local_Hours
    }


set title name." ".band." SV's out of Tolerance"
set output band.".OUT.png"
plot \
     band.'.OUT' using ($1/1000)+Local_Time_Offset:($2) title "Out of Tolerance",\
     band.'.OUT' using ($1/1000)+Local_Time_Offset:($3) title "SV"

set y2tics
set y2label "Percentage SV's outside tolerance"
set y2range [0:100]


set title name." ".band." SV's out of Tolerance %"

set output band.".OUT-Percentage.png"
plot \
     band.'.OUT' using ($1/1000)+Local_Time_Offset:(($2/$3)*100) title "% Out of Tolerance" axis x1y2,\
     band.'.OUT' using ($1/1000)+Local_Time_Offset:($3) title "SV"

#plot \
#     band.'.OUT' using ($1+Local_Time_Offset):($2) title "External 1",\
#     band.'.OUT' using ($1+Local_Time_Offset):($3) title "External 2",\
#     band.'.OUT' using ($1+Local_Time_Offset):($4) title "Battery"



#plot \
#     band.'.OUT' using ($1+Local_Time_Offset):($2) title "External 1",\
#     band.'.OUT' using ($1+Local_Time_Offset):($3) title "External 2",\
#     band.'.OUT' using ($1+Local_Time_Offset):($4) title "Battery",\
#     band.'.OUT' using ($1+Local_Time_Offset):($6) title "Temperature" axis x1y2 lt 2

#print band.".OUT"


quit
