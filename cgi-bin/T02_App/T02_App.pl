#!/usr/bin/perl -w
$| = 1;

use CGI qw(param escapeHTML);
use FindBin;

use lib "$FindBin::Bin/../PositionPlot";
use JCMBSoft_Config qw(enforce_access parse_session_filename download_to_file);

if ( ( $ENV{HTTP_X_REQUESTED_WITH} || '' ) eq 'XMLHttpRequest' ) {
    eval { require CGI::Carp; CGI::Carp->import(qw(carpout)); 1 } and do {
        if ( open my $cgi_log, '>>', '/run/shm/t02_app_cgi.log' ) {
            carpout($cgi_log);
        }
    };
}
else {
    eval { require CGI::Carp; CGI::Carp->import(qw(fatalsToBrowser)); 1 };
}

$CGI::POST_MAX = 1024 * 190000;    # 190 MB file max

my $xhr = ( $ENV{HTTP_X_REQUESTED_WITH} || '' ) eq 'XMLHttpRequest';

sub urldecode {
    my $s = shift;
    $s =~ tr/\+/ /;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack( 'C', hex($1) )/eg;
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
        print_json( "{\"error\":\"" . json_string($message) . "\"}" );
        exit;
    }
    print "Content-Type: text/html; charset=utf-8\r\n\r\n";
    print "<html><body><p>" . escapeHTML($message) . "</p></body></html>";
    exit;
}

my $query = new CGI;
JCMBSoft_Config::enforce_access($query);

my $filename  = scalar $query->param('file');
my $file_link = scalar $query->param('file_link');
my $app_mode  = defined $query->param('APP');

unless ( $filename || $file_link ) {
    xhr_error('No GNSS file was uploaded.');
}

my ( $name, $extension, $safe_filename );
eval {
    if ($file_link) {
        $filename = urldecode($file_link);
    }
    ( $name, $extension, $safe_filename ) = parse_session_filename($filename);
    1;
} or do {
    my $err = $@ || 'Invalid filename';
    $err =~ s/\s at .*//s;
    xhr_error($err);
};

my $upload_file = "/run/shm/$safe_filename";

if ( $query->upload('file') ) {
    my $upload_filehandle = $query->upload('file');
    if ( !open my $fh, '>', $upload_file ) {
        xhr_error('Could not save uploaded file.');
    }
    binmode $fh;
    while (<$upload_filehandle>) {
        print $fh $_;
    }
    close $fh;
}
elsif ($file_link) {
    my ( $ok, $dl_err ) = download_to_file( $file_link, $upload_file );
    unless ($ok) {
        xhr_error("Could not download file: $dl_err");
    }
}
else {
    xhr_error('No GNSS file was uploaded.');
}

my $start_script = "$FindBin::Bin/start_single.sh";
unless ( -x $start_script ) {
    xhr_error('Processing script is not available on the server.');
}

if ($app_mode) {
    print "Content-Type: application/octet-stream\r\n";
    print "Content-Disposition: attachment; filename=\"" . $name . ".cfg\"\r\n\r\n";
}
else {
    print "Content-Type: text/html; charset=utf-8\r\n\r\n";
    print "<html><head><title>GNSS Configuration</title></head><body>";
    print "<h1>Configuration for " . escapeHTML($safe_filename) . "</h1>\n";
    print "<pre>\n";
}

if ($app_mode) {
    system( $start_script, $upload_file, '1' );
}
else {
    system( $start_script, $upload_file );
    print "</pre></body></html>";
}
