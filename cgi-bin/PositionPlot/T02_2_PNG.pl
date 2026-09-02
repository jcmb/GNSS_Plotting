#!/usr/bin/perl -w
$| = 1;

use CGI qw(param);
use CGI::Carp;
use File::Basename;

use FindBin qw($Bin);
use lib $Bin;
use JCMBSoft_Config qw(enforce_access sanitize_path_segment normalize_project_path parse_session_filename);

use Sys::Syslog;

openlog( 'T02_Pos_PNG', 'ndelay', 'daemon' );
syslog (LOG_INFO,"T02_Pos_PNG Started");

#print JCMBSoft_Config::TrimbleTools();

sub urldecode {
    my $s = shift;
    $s =~ tr/\+/ /;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/eg;
    return $s;
}

sub tz_hours_from_form {
    my ( $hours_raw, $minutes_raw ) = @_;
    return undef if !defined $hours_raw || $hours_raw eq "";
    my $hours = int($hours_raw);
    my $minutes = defined $minutes_raw && $minutes_raw ne "" ? int($minutes_raw) : 0;
    $minutes = 0  if $minutes < 0;
    $minutes = 59 if $minutes > 59;
    $hours = -14 if $hours < -14;
    $hours = 14  if $hours > 14;
    if ( $hours == 0 ) {
        return $minutes / 60.0;
    }
    if ( $hours < 0 ) {
        return $hours - $minutes / 60.0;
    }
    return $hours + $minutes / 60.0;
}

sub sanitize_upload_basename {
    my ($raw) = @_;
    return undef if !defined $raw || $raw eq "";
    my $name = $raw;
    $name =~ s/^.*[\\\/]//;
    $name =~ tr/ /_/;
    $name =~ s/[^a-zA-Z0-9_.-]//g;
    if ( $name !~ /^([a-zA-Z0-9_.-]+)$/ ) {
        return undef;
    }
    return $1;
}

sub drain_upload_handle {
    my ($handle) = @_;
    return if !$handle;
    while ( defined( my $line = <$handle> ) ) {
        1;
    }
    close $handle;
}

sub gnss_results_dir {
    my $cfg_dir = "$Bin/../../admin/GNSS";
    my $cfg = "$cfg_dir/GNSS_Paths.cfg";
    if ( !-f $cfg ) {
        $cfg = '/mnt/GPS_Admin/admin/GNSS/GNSS_Paths.cfg';
    }
    if ( -f $cfg ) {
        open my $fh, '<', $cfg or return '/mnt/Data/results';
        while ( my $line = <$fh> ) {
            if ( $line =~ /^\s*GNSS_RESULTS_DIR\s*=\s*(.+?)\s*$/ ) {
                my $dir = $1;
                $dir =~ s/^["']|["']$//g;
                close $fh;
                return $dir if $dir ne '';
            }
        }
        close $fh;
    }
    return '/mnt/Data/results';
}


$CGI::POST_MAX = 1100 * 1024 * 1024; # 1.1 GB file max
my $query = new CGI;
my $gnss_user = JCMBSoft_Config::enforce_access($query);
my $safe_filename_characters = "a-zA-Z0-9_.-";

my $testing_mode = defined $query->param('testing_mode');
my $keep_x29 = defined $query->param('keep_x29');
my $skip_gnss_upload = defined $query->param('skip_gnss_upload');
my $skip_truth_upload = defined $query->param('skip_truth_upload');
my $gnss_basename = sanitize_upload_basename( scalar $query->param('gnss_basename') );
my $truth_basename = sanitize_upload_basename( scalar $query->param('truth_basename') );

my $filename = $query->param('file');
my $file_link = $query->param('file_link');
my $Sol = $query->param('Sol');
my $Point = $query->param('Point');
my $Ant = $query->param('Ant');
my $Fixed_Range = $query->param('Range');
my $SaveFile = $query->param('SaveFile');
my $MeanSol = $query->param('MeanSol');
my $SessionType = $query->param('SessionType');
if (defined($MeanSol)) {
    $MeanSol =~ s/^\s+|\s+$//g;
}
if ( !defined($SessionType) || $SessionType eq "" )
{
    $SessionType="-1";
}

#$file_link="https://www.dropbox.com/s/yjupry9omdvm2og/6343_D5.T02?dl=0";

#$Point = "0";
$Ant = "0";

my $project = normalize_project_path( scalar $query->param('project') );
my $Decimate = $query->param('Decimate');

my $TrimbleTools=1;

print $query->header (-charset=>'utf-8' );

my $gnss_upload_handle = $query->upload('file');
my $file_uploaded = defined $gnss_upload_handle ? 1 : 0;

if ($file_uploaded) {
    if ($filename =~ m/^.*(\\|\/)(.*)/) {
        $filename = $2;
    }
    syslog( LOG_INFO, "File provided" );
}
elsif ($gnss_basename) {
    $filename = $gnss_basename;
}
elsif ($skip_gnss_upload) {
    print "GNSS filename is required when skipping upload.\n";
    exit;
}

if ( !$filename && !$file_link )
{
    print "There was a problem uploading your GNSS file, or not file/file url not selected\n";
    exit;
}

if ( !defined($Sol) || $Sol eq "" )
{
    $Sol="-1";
}

if ( defined ($Point) && $Point ne "" )
{
    $Point = sanitize_path_segment($Point);
    if ( $Point ne "" )
    {
        $Point_Dir="/".$Point;
    }
    else
    {
        $Point="-1";
        $Point_Dir="";
    }
}
else 
{
    $Point="-1";
    $Point_Dir="";
}

if ( !$Ant )
{
    $Ant="-1";
}

if ( !$Fixed_Range )
{
    $Fixed_Range="0";
}


if ( !$Decimate )
{
    $Decimate="0";
}

if ( !defined($SaveFile) )
{
    $SaveFile="0";
}

if ( !defined($MeanSol) || $MeanSol eq "" )
{
    $MeanSol="-1";
}

$ENV{GNSS_MEAN_SOL} = $MeanSol;
$ENV{GNSS_KEEP_UPLOADS} = 1 if $testing_mode;
$ENV{GNSS_KEEP_X29} = 1 if $keep_x29;

my $tz_decimal = tz_hours_from_form( scalar $query->param('tz_hours'), scalar $query->param('tz_minutes') );
if ( defined $tz_decimal ) {
    $ENV{GNSS_LOCAL_TZ_HOURS} = $tz_decimal;
}

my $file_linked=0;

if ($file_link){
    $file_linked=1;
    syslog (LOG_INFO,"File Link");
    $filename=urldecode($file_link);

    if ($filename=~m/^.*(\\|\/)(.*)/) {
        $filename=$2;
        if ($filename=~m/^(.*)\?.*/) {
            $filename=$1;
        }

    }
    $file_uploaded = 0;
}

my ( $gnss_name, $extension, $session_basename ) = parse_session_filename($filename);
my $name = $gnss_name;

print "<html><head><title>Plotting GNSS Data</title>";
print "</head>";
print "<body><h1>Processing $session_basename:</h1>\n";

$upload_file = JCMBSoft_Config::upload_dir().$session_basename;

my $truth_upload = "";
my $truth_upload_handle = $query->upload('truth_file');
my $truth_file_uploaded = defined $truth_upload_handle ? 1 : 0;
my $truth_filename = $truth_basename;

if ($truth_file_uploaded) {
    $truth_filename = $query->param('truth_file');
    if ($truth_filename =~ m/^.*(\\|\/)(.*)/) {
        $truth_filename = $2;
    }
}
elsif ($skip_truth_upload && !$truth_basename) {
    print "ATS truth filename is required when skipping upload.\n";
    closelog();
    exit;
}

if ($truth_filename) {
    $truth_filename =~ tr/ /_/;
    $truth_filename =~ s/[^$safe_filename_characters]//g;
    if ($truth_filename =~ /^([$safe_filename_characters]+)$/) {
        $truth_filename = $1;
    } else {
        die "Truth filename contains invalid characters";
    }
    my ($ats_name) = parse_session_filename($truth_filename);
    $name = $ats_name;
    $truth_upload = JCMBSoft_Config::upload_dir() . $name . "_truth_" . $truth_filename;
}

my $report_url = "/results/Position$project$Point_Dir/$name/";
$ENV{GNSS_REPORT_URL} = $report_url;
$ENV{GNSS_SESSION_NAME} = $name;
print "<base href=\"$report_url\">";

if ($skip_gnss_upload || ( $testing_mode && $file_uploaded && -f $upload_file ) ) {
    unless ( -f $upload_file ) {
        print "Cached GNSS file not found on server: " . CGI::escapeHTML($upload_file) . "\n";
        closelog();
        exit;
    }
    drain_upload_handle($gnss_upload_handle) if $file_uploaded;
    print "Using cached GNSS file on server (" . CGI::escapeHTML($session_basename) . ")<br>";
}
elsif ($file_uploaded) {
    print "Getting uploaded file<br>";
    if (!open ( UPLOADFILE, ">$upload_file" )) {
        print "\n could not open output file".$upload_file;
        die "$!";
    }
    binmode UPLOADFILE;

    while ( <$gnss_upload_handle> )
    {
        print UPLOADFILE;
    }

    close UPLOADFILE;
}

if ($truth_upload) {
    if ( $skip_truth_upload || ( $testing_mode && $truth_file_uploaded && -f $truth_upload ) ) {
        unless ( -f $truth_upload ) {
            print "Cached ATS truth file not found on server: " . CGI::escapeHTML($truth_upload) . "\n";
            closelog();
            exit;
        }
        drain_upload_handle($truth_upload_handle) if $truth_file_uploaded;
        $ENV{GNSS_TRUTH_ATS} = $truth_upload;
        print "Using cached ATS truth file on server (" . CGI::escapeHTML($truth_filename) . ")<br>";
    }
    elsif ($truth_file_uploaded) {
        print "Getting uploaded truth file<br>";
        if (!open(UPLOADTRUTH, ">$truth_upload")) {
            print "\n could not open truth output file" . $truth_upload;
            die "$!";
        }
        binmode UPLOADTRUTH;
        while (<$truth_upload_handle>) {
            print UPLOADTRUTH;
        }
        close UPLOADTRUTH;
        $ENV{GNSS_TRUTH_ATS} = $truth_upload;
    }
}

if ($file_linked) {
    print "Getting file by url from " . CGI::escapeHTML($file_link) . "<br/>";
    my ( $ok, $dl_err ) = JCMBSoft_Config::download_to_file( $file_link, $upload_file );
    unless ($ok) {
        print "<p>Could not download file: " . CGI::escapeHTML($dl_err) . "</p></body></html>";
        syslog( LOG_WARNING, "URL download failed: $dl_err" );
        closelog();
        exit;
    }
}


print "Data is being processed: This will normally takes a few seconds but can take longer for very large files.<br>";
print "The report will be at <a href=\"$report_url\">$report_url</a><br/>\n";
print "<p/>Processing will continue if you navigate away from this page<br/>";
print "<pre>\n";

my $results_dir = gnss_results_dir() . "/Position$project$Point_Dir/$name";
system( 'mkdir', '-p', $results_dir );
$ENV{GNSS_RESULT_DIR} = $results_dir;

my $start_script = "$Bin/start_single.sh";
unless ( -x $start_script ) {
    print "</pre><p>Processing script is not available on the server.</p></body></html>";
    closelog();
    exit;
}

syslog( LOG_INFO, "Starting processing: " . $upload_file );
if ( JCMBSoft_Config::TrimbleTools() ) {
    exec( '/bin/bash', $start_script, $upload_file, $extension, $Sol, $Point, $Ant,
        $Decimate, $Fixed_Range, $project, $SaveFile, $MeanSol,
        $report_url, $SessionType, $truth_upload );
}
exec( $start_script, $upload_file, $extension, $Sol, $Point, $Ant,
    $Decimate, $Fixed_Range, $project, $SaveFile, $MeanSol,
    $report_url, $SessionType, $truth_upload );
