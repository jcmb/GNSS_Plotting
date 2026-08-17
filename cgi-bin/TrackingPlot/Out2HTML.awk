BEGIN {
    print "<table border=\"1\">"
    header = 1
}
{
    print "<tr>"
    for (i = 1; i <= NF; i++) {
        if (header) {
            print "<th>" $i "</th>"
        } else {
            print "<td>" $i "</td>"
        }
    }
    print "</tr>"
    header = 0
}
END {
    print "</table>"
