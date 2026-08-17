#!/usr/bin/perl -w
$| = 1;

use CGI qw(param escapeHTML);
use File::Basename;
use FindBin;

use lib "$FindBin::Bin/../PositionPlot";
use JCMBSoft_Config;

if (($ENV{HTTP_X_REQUESTED_WITH} || '') eq 'XMLHttpRequest') {
    eval { require CGI::Carp; CGI::Carp->import(qw(carpout)); 1 } and do {
        if (open(my $cgi_log, '>>', '/run/shm/trackingplot_cgi.log')) {
            carpout($cgi_log);
        }
    };
}
else {
    eval { require CGI::Carp; CGI::Carp->import(qw(fatalsToBrowser)); 1 };
}

$CGI::POST_MAX = 1024 * 190000; # 190mb file max

my $xhr = ($ENV{HTTP_X_REQUESTED_WITH} || '') eq 'XMLHttpRequest';

sub sanitize_path_segment {
    my ($s) = @_;
    return '' unless defined $s && $s ne '';
    $s =~ s/[^a-zA-Z0-9_.-]//g;
    return $s;
}

sub json_string {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    return $s;
}

sub print_json {
    my ($payload) = @_;
    print "Content-Type: application/json; charset=utf-8\r\n\r\n";
    print $payload;
}

sub xhr_error {
    my ($message) = @_;
    if ($xhr) {
        print_json("{\"error\":\"" . json_string($message) . "\"}");
        exit;
    }
    die $message;
}

sub gnss_results_dir {
    my $cfg_dir = "$FindBin::Bin/../../admin/GNSS";
    my $cfg = "$cfg_dir/GNSS_Paths.cfg";
    if (!-f $cfg) {
        $cfg = '/mnt/GPS_Admin/admin/GNSS/GNSS_Paths.cfg';
    }
    if (-f $cfg) {
        open(my $fh, '<', $cfg) or return '/mnt/Data/results';
        while (my $line = <$fh>) {
            if ($line =~ /^\s*GNSS_RESULTS_DIR\s*=\s*(.+?)\s*$/) {
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

sub results_dir_for {
    my ($project, $name) = @_;
    return gnss_results_dir() . "/Tracking$project/$name";
}

sub urldecode {
    my $s = shift;
    $s =~ tr/\+/ /;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/eg;
    return $s;
}

my $query = new CGI;
my $gnss_user = JCMBSoft_Config::enforce_access($query);
my $safe_filename_characters = "a-zA-Z0-9_.-";

my $filename = scalar $query->param('file');
my $file_link = scalar $query->param('file_link');
my $project = sanitize_path_segment(scalar $query->param('project'));
my $Point = sanitize_path_segment(scalar $query->param('Point'));
my $Decimate = scalar $query->param('Decimate');

if (defined $Decimate && $Decimate ne '' && $Decimate !~ /^-?\d+(\.\d+)?$/) {
    xhr_error("Invalid decimation value");
}
$Decimate = '-1' unless defined $Decimate && $Decimate ne '';

if ($project) {
    $project = "/" . $project;
}
else {
    $project = "/General";
}

if ($Point) {
    $project = $project . "/" . $Point;
}

unless ($filename || $file_link) {
    if ($xhr) {
        print_json("{\"error\":\"No GNSS file was uploaded.\"}");
    }
    else {
        print $query->header(-charset => 'utf-8');
        print "Problem with the file: no GNSS file was uploaded\n";
    }
    exit;
}

if ($file_link) {
    $filename = urldecode($file_link);
    if ($filename =~ m/^.*(\\|\/)(.*)/) {
        $filename = $2;
        if ($filename =~ m/^(.*)\?.*/) {
            $filename = $1;
        }
    }
}

if ($filename =~ m/^.*(\\|\/)(.*)/) {
    $filename = $2;
}

my ($name, $path, $extension) = fileparse($filename, '\..*');
$filename = $name . $extension;

$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

unless ($filename =~ /^([$safe_filename_characters]+)$/) {
    xhr_error("Filename contains invalid characters");
}
$filename = $1;

my $upload_file = "/run/shm/" . $filename;

if ($query->param('file')) {
    my $upload_filehandle = $query->upload("file");
    if (!open(UPLOADFILE, ">", $upload_file)) {
        xhr_error("Could not save uploaded file.");
    }
    binmode UPLOADFILE;
    while (<$upload_filehandle>) {
        print UPLOADFILE;
    }
    close UPLOADFILE;
}
else {
    my ( $ok, $dl_err ) = JCMBSoft_Config::download_to_file( $file_link, $upload_file );
    unless ($ok) {
        if ($xhr) {
            xhr_error("Could not download file: $dl_err");
        }
        print $query->header(-charset => 'utf-8');
        print "<p>Could not download file: " . escapeHTML($dl_err) . "</p></body></html>";
        exit;
    }
}

my $results_dir = results_dir_for($project, $name);
system('mkdir', '-p', $results_dir);

if (open(my $processing, '>', "$results_dir/.processing")) {
    print $processing "started\n";
    close $processing;
}

my $start_script = "$FindBin::Bin/start_single.sh";
unless (-x $start_script) {
    xhr_error("Processing script is not available on the server.");
}

system($start_script, $upload_file, $extension, $Decimate, $project);

my $results_url = "/results/Tracking$project/$name/";

if ($xhr) {
    print_json("{\"redirect\":\"" . json_string($results_url) . "\",\"processing\":true}");
    exit;
}

print $query->header(-charset => 'utf-8');
print "<html><head>";
print '<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">';
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />";
print "<meta http-equiv=\"refresh\" content=\"0; url=$results_url\" />";
print "<title>Plotting GNSS Tracking Data</title></head><body><h1>Processing $filename:</h1>\n";
print "Data is being processed: This will normally take a few seconds but can take longer for very large files.<br>";
print "The graphs will be at <a href=\"$results_url\">$results_url</a><br>";
print "<p/>Redirecting to the results page...<br/>";
print "<p/>Processing will continue if you navigate away from this page<br/>";
print "<pre>\n";
