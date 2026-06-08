package JCMBSoft_Config;

use strict;
use Exporter;

use vars qw($VERSION @EXPORT_OK);
@EXPORT_OK=qw(TrimbleTools upload_dir);
$VERSION     = 1.00;

sub TrimbleTools() {
    return 0;
}

sub upload_dir() {
    return "/tmp/";
}

#$upload_dir = "/home8/trimblet/public_html/cgi-bin/tmp/"
#$upload_dir = "/run/shm/"

1;
