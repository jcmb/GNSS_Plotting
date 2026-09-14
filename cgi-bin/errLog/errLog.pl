#!/usr/bin/perl -w
$| = 1;

use CGI qw(param escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use FindBin;

my $xhr = ( $ENV{HTTP_X_REQUESTED_WITH} || '' ) eq 'XMLHttpRequest';

$CGI::POST_MAX = 1024 * 190000;    # 190mb file max

sub json_string {
    my ($s) = @_;
    $s = "" unless defined $s;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\r?\n/ /g;
    return '"' . $s . '"';
}

sub errlog_css {
    return <<'CSS';
#errlog-root { margin-top: 0.5em; }
.errlog-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 16px;
  align-items: center;
  margin-bottom: 10px;
}
.errlog-status { color: #0063a3; font-size: 13px; }
.errlog-table-wrap {
  overflow: auto;
  max-width: 100%;
  border: 1px solid #ccc;
  background: #fff;
}
.errlog-table {
  border-collapse: collapse;
  width: 100%;
  font-size: 12px;
}
.errlog-table th,
.errlog-table td {
  border: 1px solid #ccc;
  padding: 4px 6px;
  vertical-align: top;
  text-align: left;
}
.errlog-table th {
  background: #e8eef3;
  white-space: nowrap;
  position: sticky;
  top: 0;
  z-index: 1;
}
.errlog-table th.sortable {
  cursor: pointer;
  user-select: none;
}
.errlog-table th.sortable:hover { background: #d5e2ec; }
.errlog-table th.not-sortable { color: #666; }
.errlog-table tr.row-error { background: #fff7f7; }
.errlog-table tr.row-warning { background: #fffdf5; }
.errlog-table td.type-error { color: #a00000; font-weight: bold; }
.errlog-table td.type-warning { color: #8a6d00; font-weight: bold; }
.errlog-table td.backtrace-cell pre {
  margin: 0;
  font-family: monospace;
  font-size: 11px;
  white-space: pre-wrap;
  max-height: 12em;
  overflow: auto;
}
.errlog-raw { margin-top: 1em; }
.errlog-raw pre {
  max-height: 320px;
  overflow: auto;
  padding: 8px;
  border: 1px solid #ccc;
  background: #f8f8f8;
  font-size: 11px;
  white-space: pre-wrap;
}
CSS
}

sub fail {
    my ($message) = @_;
    if ($xhr) {
        print "Content-Type: text/plain; charset=utf-8\r\n\r\n";
        print $message;
    }
    else {
        print "Content-Type: text/html; charset=utf-8\r\n\r\n";
        print "<html><body><pre>" . escapeHTML($message) . "</pre></body></html>";
    }
    exit;
}

my $query                   = new CGI;
my $safe_filename_characters = "a-zA-Z0-9_.-";
my $filename                = $query->param('file');

if ( !$filename ) {
    fail("Problem with the file: no SysLog.bin was uploaded.\n");
}

if ( $filename =~ m/^.*(\\|\/)(.*)/ ) {    # strip remote path, keep filename
    $filename = $2;
}

my ( $name, $path, $extension ) = fileparse( $filename, '\..*' );
$filename = $name . $extension;

$name =~ tr/ /_/;
$name =~ s/[^$safe_filename_characters]//g;

if ( $name =~ /^([$safe_filename_characters]+)$/ ) {
    $name = $1;
}
else {
    die "name contains invalid characters";
}

$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {
    $filename = $1;
}
else {
    die "Filename contains invalid characters";
}

my $upload_file = "/tmp/" . $filename;

my $upload_filehandle = $query->upload("file");
if ( !open( UPLOADFILE, ">$upload_file" ) ) {
    fail("Could not open output file $upload_file: $!\n");
}
binmode UPLOADFILE;
while (<$upload_filehandle>) {
    print UPLOADFILE;
}
close UPLOADFILE;

chdir $FindBin::Bin or fail("Could not chdir to CGI directory.\n");

my $output = "";
if ( open( my $fh, "-|", "./start_single.sh", $upload_file ) ) {
    local $/;
    $output = <$fh>;
    close $fh;
}
else {
    fail("Could not run errLog processor: $!\n");
}

$output = "" unless defined $output;

my $body = "Info for $filename:\n" . $output;

if ($xhr) {
    print "Content-Type: text/plain; charset=utf-8\r\n\r\n";
    print $body;
    exit;
}

my $safe_title = escapeHTML($filename);
my $css        = errlog_css();
my $js_name    = json_string($name);
my $safe_body  = escapeHTML($body);

print "Content-Type: text/html; charset=utf-8\r\n\r\n";
print <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css" />
<title>SysLog.bin information — $safe_title</title>
<style type="text/css">
$css
</style>
</head>
<body class="page">
<div class="container clearfix">
  <div style="padding: 10px 10px 10px 0;">
    <a href="http://construction.trimble.com/">
      <img src="/images/trimble-logo.jpg" alt="Trimble Logo" id="logo" />
    </a>
  </div>
</div>
<div id="top-header-trim"></div>
<div id="content-area">
<div id="content">
<div id="main-content" class="clearfix">
<h1>SysLog.bin information</h1>
<div id="errlog-root">
  <div class="errlog-toolbar">
    <span data-errlog-meta></span>
    <span data-errlog-count></span>
    <label><input type="checkbox" data-errlog-hide-warnings /> Hide warnings</label>
    <input type="button" data-errlog-download-raw value="Download raw output" />
    <input type="button" data-errlog-download-csv value="Download table CSV" />
    <span data-errlog-status class="errlog-status" aria-live="polite"></span>
  </div>
  <div class="errlog-table-wrap">
    <table class="errlog-table">
      <thead data-errlog-thead></thead>
      <tbody data-errlog-tbody></tbody>
    </table>
  </div>
  <details class="errlog-raw">
    <summary>Raw processor output</summary>
    <pre id="raw-errlog">$safe_body</pre>
  </details>
</div>
</div>
</div>
</div>
<script src="/errLog_view.js"></script>
<script type="text/javascript">
(function () {
  var raw = document.getElementById("raw-errlog").textContent;
  ErrLogView.mount(document.getElementById("errlog-root"), raw, $js_name);
})();
</script>
</body>
</html>
HTML
