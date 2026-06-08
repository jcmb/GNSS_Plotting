#! /bin/bash

echo "<html>" >/tmp/Robbie.html
echo "<head><title>GNSS Status</title><meta http-equiv="refresh" content="300"></head>" >>/tmp/Robbie.html
echo "<body>" >>/tmp/Robbie.html
echo "<h1>GNSS receiver status</h1>" >>/tmp/Robbie.html
echo `date -u` >>/tmp/Robbie.html
echo "<h2>BASES</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/BASES 2 >>/tmp/Robbie.html
echo "<h2>GRK</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/GRK 2 >>/tmp/Robbie.html
echo "<h2>BTN</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/TestSite 2 >>/tmp/Robbie.html
echo "<h2>ROVERS</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/ROVERS 2 >>/tmp/Robbie.html
echo "<h2>IRELAND</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/IRELAND 2 >>/tmp/Robbie.html
echo "<h2>Judos</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/Judos 2 >>/tmp/Robbie.html
echo "<h2>RTX</h2><br/>">>/tmp/Robbie.html
/mnt/GPS_Admin/admin/GNSS/Robbie.py /mnt/GPS_Admin/GNSS_Data/RTX 2 >>/tmp/Robbie.html
echo "</body>" >>/tmp/Robbie.html
echo "</html>" >>/tmp/Robbie.html

mv /tmp/Robbie.html /mnt/GPS_Admin/html/Robbie.html
