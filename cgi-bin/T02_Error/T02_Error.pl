#!/usr/bin/perl -w
$| = 1;

BEGIN {
    $CGI::POST_MAX = 1100 * 1024 * 1024;    # 1.1 GB, match position plot uploads
}

use CGI qw(param escapeHTML);
use FindBin;

use lib "$FindBin::Bin/../PositionPlot";
use JCMBSoft_Config qw(enforce_access parse_session_filename download_to_file upload_dir);

my $xhr = ( $ENV{HTTP_X_REQUESTED_WITH} || '' ) eq 'XMLHttpRequest';

if ($xhr) {
    eval { require CGI::Carp; CGI::Carp->import(qw(carpout)); 1 } and do {
        my $log_dir = ( -d '/run/shm' && -w '/run/shm' ) ? '/run/shm' : '/tmp';
        if ( open T02_CGI_LOG, '>>', "$log_dir/t02_error_cgi.log" ) {
            carpout( \*T02_CGI_LOG );
        }
    };
}
else {
    eval { require CGI::Carp; CGI::Carp->import(qw(fatalsToBrowser)); 1 };
}

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
    $s =~ s/\r?\n/ /g;
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

sub staging_upload_file {
    my ($basename) = @_;
    for my $dir ( '/run/shm', upload_dir() ) {
        my $staging_dir = "$dir";
        $staging_dir =~ s{/\z}{};
        next unless -d $staging_dir && -w $staging_dir;
        return "$staging_dir/$basename";
    }
    xhr_error('Upload directory is not writable on the server.');
}

my $query = new CGI;
JCMBSoft_Config::enforce_access($query);

my $filename  = scalar $query->param('file');
my $file_link = scalar $query->param('file_link');

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

my $upload_file = staging_upload_file($safe_filename);

if ( $query->param('file') ) {
    my $upload_filehandle = $query->upload('file');
    xhr_error('No GNSS file was uploaded.') unless $upload_filehandle;
    if ( !open UPLOADFILE, '>', $upload_file ) {
        xhr_error('Could not save uploaded file.');
    }
    binmode UPLOADFILE;
    while (<$upload_filehandle>) {
        print UPLOADFILE;
    }
    close UPLOADFILE;
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

print "Content-Type: text/html; charset=utf-8\r\n\r\n";
print "<html><head><title>GNSS Error Log</title></head><body>";
print "<h1>Error log for " . escapeHTML($safe_filename) . "</h1>\n";
print "<pre>\n";

system( $start_script, $upload_file );

print "</pre></body></html>";
