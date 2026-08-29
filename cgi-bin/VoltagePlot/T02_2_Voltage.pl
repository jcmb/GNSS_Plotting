#!/usr/bin/perl -w
$| = 1;

use CGI qw(param);
use CGI::Carp;
use File::Basename;

use FindBin qw($Bin);
use lib "$Bin/../PositionPlot";
use JCMBSoft_Config qw(enforce_access sanitize_path_segment normalize_project_path parse_session_filename);

sub urldecode {
    my $s = shift;
    $s =~ tr/\+/ /;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/eg;
    return $s;
}

$CGI::POST_MAX = 1024 * 190000; # 190mb file max

my $query = new CGI;
my $gnss_user = JCMBSoft_Config::enforce_access($query);
my $safe_filename_characters = "a-zA-Z0-9_.-";

my $filename = $query->param('file');
my $file_link = $query->param('file_link');

print $query->header (-charset=>'utf-8' );

#print $filename;
#print "<br>";
#print $file_link;
#print "<br>";

if ( !$filename && !$file_link )
{
    print "Problem with the file, either a problem loading your GNSS file or file/file url not selected\n";
    exit;
}

my $file_uploaded=0;
my $file_linked=0;

if ($filename) {
    if ($filename=~m/^.*(\\|\/)(.*)/) {  # strip the remote path and keep the filename
	$filename=$2;
    }
   $file_uploaded=1
    
}

if ($file_link){
    $file_linked=1;
#    print "file link<br>";
    $filename=urldecode($file_link);
    if ($filename=~m/^.*(\\|\/)(.*)/) {
	# strip the remote path and keep the filename
#	print "matched<br>";
	$filename=$2;
	if ($filename=~m/^(.*)\?.*/) {
	    $filename=$1;
        }
	
    }
}

#print "<br>";
#print "Filename: ". $filename;
#print "<br>";

my ( $name, $extension );
( $name, $extension, $filename ) = parse_session_filename($filename);

my $project = normalize_project_path( scalar $query->param('project') );
$project =~ s{^/}{};
my $Point = sanitize_path_segment( scalar $query->param('Point') );
$Point = '.' if !defined($Point) || $Point eq '';

#print "Content-type: text/html\n\n";
print "<html><head>";
print '<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">';
#print "<meta http-equiv=\"refresh\" content=\"5; url=/results/Voltage/$project/$Point/$name\">";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />";
print "<title>Plotting GNSS Tracking Data</title></head><body><h1>Processing $filename:</h1>\n";

#print "Project: *$project*";

#print $filename."\n";
my $upload_file="";

$upload_file = "/tmp/".$filename;
#print "upload file $upload_file";

#my $upload_file = $filename;

if ($file_uploaded) {
    print "Getting uploaded file<br>";
    my $upload_filehandle = $query->upload("file");

#print $upload_file;
    if (!open ( UPLOADFILE, ">$upload_file" )) {
	print "\n could not open output file".$upload_file;
	die "$!";
    }
# or die "$!";
    binmode UPLOADFILE;

    while ( <$upload_filehandle> )
    {
	print UPLOADFILE;
    }

    close UPLOADFILE;
}

if ($file_linked) {
    print "Getting file by url from " . CGI::escapeHTML($file_link) . "<br/>";
    my ( $ok, $dl_err ) = JCMBSoft_Config::download_to_file( $file_link, $upload_file );
    unless ($ok) {
        print "<p>Could not download file: " . CGI::escapeHTML($dl_err) . "</p></body></html>";
        exit;
    }
}

my $TZ=0;
print "Data is being processed: This will normally takes a few seconds but can take longer for very large files.<br>";
print "The graphs will be at \<a href=\"/results/Voltage/$project/$Point/$name\"\>/results/Voltage/$project/$Point/$name\</a\>\n";
print "<p/>Processing will continue if you navigate away from this page<br/>";
print "<pre>\n";
print "./start_single.sh",$extension," ",$project," ",$Point," ",$TZ," ",$upload_file;
system "./start_single.sh",$extension,$project,$Point,$TZ,$upload_file
