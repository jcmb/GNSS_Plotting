#!/usr/bin/perl -w
$| = 1;

use CGI qw(param);
use CGI::Carp;
use File::Basename;

use LWP::Simple;


sub urldecode {
    my $s = shift;
    $s =~ tr/\+/ /;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/eg;
    return $s;
}

$CGI::POST_MAX = 1024 * 190000; # 190mb file max

my $query = new CGI;
my $safe_filename_characters = "a-zA-Z0-9_.-";

my $TrimbleTools=0;
my $filename = $query->param('file');
my $file_link = $query->param('file_link');
my $project = $query->param('project');
my $Point = $query->param('Point');
my $Decimate = $query->param('Decimate');

if (defined ($project)) {
    if  ($project) {
        $project="/".$project;
        }
    else  {
        $project="/General";
        }
}
else {
    $project="/General";
}

if (defined ($Point)) {
    if  ($Point) {
        if  ($project) {
           $project=$project."/".$Point;
           }
        else  {
           $project="/".$Point;
           }
    }
}

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

my ( $name, $path, $extension ) = fileparse ( $filename, '\..*' );
$filename = $name . $extension;


$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

if ( $filename =~ /^([$safe_filename_characters]+)$/ )
{
    $filename = $1;
}
else
{
    die "Filename contains invalid characters";

}


#print "Content-type: text/html\n\n";
print "<html><head>";
print '<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">';
#print "<meta http-equiv=\"refresh\" content=\"5; url=/results/Tracking$project/$name\">";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />";
print "<title>Plotting GNSS Tracking Data</title></head><body><h1>Processing $filename:</h1>\n";

#print "Project: *$project*";

#print $filename."\n";
my $upload_file="";

if ($TrimbleTools) {
    $upload_file = "/home8/trimblet/public_html/cgi-bin/tmp/".$filename;
}
else {
    $upload_file = "/run/shm/".$filename;
}


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
    print "Getting file by url from " . $file_link."<br/>";
    system("curl -L --silent -o $upload_file $file_link")
}


#Content-type: text/html
#application/vnd.google-earth.kml+xml

print "Data is being processed: This will normally takes a few seconds but can take longer for very large files.<br>";
print "The graphs will be at \<a href=\"/results/Tracking$project/$name\"\>/results/Tracking$project/$name/\</a\>\n";
print "<p/>Processing will continue if you navigate away from this page<br/>";
print "<pre>\n";
system "./start_single.sh",$upload_file,$extension,$TrimbleTools,$Decimate,$project
