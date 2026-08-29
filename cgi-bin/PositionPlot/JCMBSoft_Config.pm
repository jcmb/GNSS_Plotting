package JCMBSoft_Config;

use strict;
use warnings;

use CGI qw(escapeHTML);
use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use Fcntl qw(:flock);
use File::Basename qw(dirname);
use MIME::Base64 qw(decode_base64);
use Socket qw(getaddrinfo inet_ntop inet_pton sockaddr_in sockaddr_in6 AF_INET AF_INET6 SOCK_STREAM);
use URI;
use LWP::UserAgent;

our $VERSION = 1.03;
our @EXPORT_OK = qw(
  TrimbleTools upload_dir
  auth_enabled auth_file
  rate_limit_enabled rate_limit_max_requests rate_limit_window_sec rate_limit_dir
  trust_proxy
  download_to_file enforce_access
  sanitize_path_segment normalize_project_path parse_session_filename
);
our @EXPORT = ();

sub sanitize_path_segment {
    my ($s) = @_;
    return '' unless defined $s && $s ne '';
    $s =~ s/[^a-zA-Z0-9_.-]//g;
    return $s;
}

sub normalize_project_path {
    my ($raw) = @_;
    $raw //= '';
    $raw =~ s/^\/+//;
    my @parts = grep { $_ ne '' } split m{/}, $raw;
    my @clean;
    for my $part (@parts) {
        my $seg = sanitize_path_segment($part);
        push @clean, $seg if $seg ne '';
    }
    return '/General' unless @clean;
    return join '', map { "/$_" } @clean;
}

sub parse_session_filename {
    my ($raw_filename) = @_;
    my $safe = "a-zA-Z0-9_.-";

    my $filename = defined $raw_filename ? $raw_filename : '';
    if ( $filename =~ m/^.*(\\|\/)(.*)/ ) {
        $filename = $2;
    }
    if ( $filename =~ m/^(.*)\?.*/ ) {
        $filename = $1;
    }

    my ( $name, $path, $extension ) = fileparse( $filename, '\..*' );
    $name =~ tr/ /_/;
    $filename = $name . $extension;
    $filename =~ tr/ /_/;
    $filename =~ s/[^$safe]//g;

    unless ( $filename =~ /^([$safe]+)$/ ) {
        die "Filename contains invalid characters";
    }
    $filename = $1;

    ( $name, $path, $extension ) = fileparse( $filename, '\..*' );
    if ( $name eq '' ) {
        die "Uploaded file must include a name before the file extension";
    }

    return ( $name, $extension, $filename );
}

sub TrimbleTools() {
    return 0;
}

sub upload_dir() {
    return "/tmp/";
}

sub _env_bool {
    my ( $name, $default ) = @_;
    my $value = $ENV{$name};
    return $default unless defined $value;
    return 1 if $value =~ /^(?:1|yes|true|on)$/i;
    return 0 if $value =~ /^(?:0|no|false|off)$/i;
    return $default;
}

sub auth_enabled {
    return _env_bool( 'GNSS_AUTH_ENABLED', 0 );
}

sub auth_file {
    if ( defined $ENV{GNSS_AUTH_FILE} && $ENV{GNSS_AUTH_FILE} ne '' ) {
        return $ENV{GNSS_AUTH_FILE};
    }

    my $system_path = '/etc/gnss-plot/htpasswd';
    return $system_path if -e $system_path;

    my $local_path = dirname(__FILE__) . '/auth.htpasswd';
    return $local_path if -e $local_path;

    return $system_path;
}

sub rate_limit_enabled {
    return _env_bool( 'GNSS_RATE_LIMIT_ENABLED', 0 );
}

sub rate_limit_max_requests {
    my $value = $ENV{GNSS_RATE_LIMIT_MAX};
    return 20 unless defined $value && $value =~ /^\d+$/;
    return 0 + $value;
}

sub rate_limit_window_sec {
    my $value = $ENV{GNSS_RATE_LIMIT_WINDOW};
    return 3600 unless defined $value && $value =~ /^\d+$/;
    return 0 + $value;
}

sub rate_limit_dir {
    if ( defined $ENV{GNSS_RATE_LIMIT_DIR} && $ENV{GNSS_RATE_LIMIT_DIR} ne '' ) {
        return $ENV{GNSS_RATE_LIMIT_DIR};
    }

    my $system_path = '/var/lib/gnss-plot/rate-limit';
    return $system_path if -d $system_path;

    return '/tmp/gnss-plot-rate-limit';
}

sub trust_proxy {
    return _env_bool( 'GNSS_TRUST_PROXY', 0 );
}

our $SAFEURL_MAX_REDIRECTS = 5;
our $SAFEURL_MAX_BYTES     = 300 * 1024 * 1024;
our $SAFEURL_TIMEOUT_SEC   = 300;

sub download_to_file {
    my ( $url, $dest_path ) = @_;
    return ( 0, 'URL is required' ) unless defined $url && $url =~ /\S/;

    $url =~ s/^\s+|\s+$//g;

    my $ua = LWP::UserAgent->new(
        agent    => 'GNSS-Plot/1.0',
        timeout  => $SAFEURL_TIMEOUT_SEC,
        max_size => $SAFEURL_MAX_BYTES,
    );
    $ua->protocols_allowed( ['http', 'https'] );
    $ua->max_redirect(0);

    my $current = $url;
    for ( my $hop = 0 ; $hop <= $SAFEURL_MAX_REDIRECTS ; $hop++ ) {
        my $err = _safeurl_validate_url($current);
        return ( 0, $err ) if $err;

        my $response = $ua->get($current);
        if ( $response->is_redirect ) {
            return ( 0, 'Too many redirects' ) if $hop >= $SAFEURL_MAX_REDIRECTS;

            my $location = $response->header('Location');
            return ( 0, 'Redirect missing Location header' ) unless defined $location && $location ne '';

            $current = URI->new_abs( $location, $response->request->uri )->as_string;
            next;
        }

        unless ( $response->is_success ) {
            my $code = $response->code // 'unknown';
            return ( 0, "Download failed (HTTP $code)" );
        }

        if ( open my $fh, '>', $dest_path ) {
            binmode $fh;
            print {$fh} $response->content;
            close $fh;
            return ( 1, '' );
        }
        return ( 0, "Could not write $dest_path: $!" );
    }

    return ( 0, 'Too many redirects' );
}

sub _safeurl_validate_url {
    my ($url) = @_;

    my $uri = eval { URI->new($url) };
    return 'Invalid URL' unless $uri;

    my $scheme = lc( $uri->scheme // '' );
    return 'Only http and https URLs are allowed' unless $scheme eq 'http' || $scheme eq 'https';

    return 'URLs with embedded credentials are not allowed' if $uri->userinfo;

    my $host = $uri->host;
    return 'URL is missing a hostname' unless defined $host && $host ne '';

    $host = lc($host);
    $host =~ s/\.$//;

    return 'Blocked hostname' if _safeurl_hostname_is_blocked($host);

    if ( _safeurl_looks_like_ip($host) ) {
        return _safeurl_ip_is_blocked($host) ? 'Blocked IP address' : '';
    }

    return _safeurl_resolve_host_is_blocked($host);
}

sub _safeurl_hostname_is_blocked {
    my ($host) = @_;
    return 1 if $host eq 'localhost';
    return 1 if $host eq 'ip6-localhost';
    return 1 if $host eq 'ip6-loopback';
    return 1 if $host eq 'metadata.google.internal';
    return 1 if $host =~ /\.local$/;
    return 1 if $host =~ /\.internal$/;
    return 0;
}

sub _safeurl_looks_like_ip {
    my ($host) = @_;
    return 1 if $host =~ /^[\d.]+$/;
    return 1 if $host =~ /:/;
    return 0;
}

sub _safeurl_resolve_host_is_blocked {
    my ($host) = @_;

    my ( $err, @res ) = getaddrinfo( $host, 'http', { socktype => SOCK_STREAM } );
    return "Could not resolve hostname: $err" if $err;

    my @addrs;
    for my $entry (@res) {
        if ( $entry->{family} == AF_INET ) {
            my ( $port, $iaddr ) = sockaddr_in( $entry->{addr} );
            push @addrs, inet_ntop( AF_INET, $iaddr ) if defined $iaddr;
        }
        elsif ( $entry->{family} == AF_INET6 ) {
            my ( $port, $iaddr ) = sockaddr_in6( $entry->{addr} );
            push @addrs, inet_ntop( AF_INET6, $iaddr ) if defined $iaddr;
        }
    }

    return 'Could not resolve hostname' unless @addrs;

    for my $addr (@addrs) {
        return 'Blocked IP address' if _safeurl_ip_is_blocked($addr);
    }

    return '';
}

sub _safeurl_ip_is_blocked {
    my ($addr) = @_;
    return 1 unless defined $addr && $addr ne '';

    if ( $addr =~ /:/ ) {
        my $bin = inet_pton( AF_INET6, $addr );
        return 1 unless defined $bin;

        return 1 if $bin eq pack( 'H*', '00000000000000000000000000000001' );

        my $b0 = ord( substr $bin, 0, 1 );
        return 1 if ( $b0 & 0xfe ) == 0xfe;
        return 1 if ( $b0 & 0xfe ) == 0xfc;

        if ( $bin =~ /^\x00{10}\xff\xff(.{4})$/s ) {
            return _safeurl_ipv4_packed_is_blocked($1);
        }
        return 0;
    }

    my $packed = inet_pton( AF_INET, $addr );
    return 1 unless defined $packed;
    return _safeurl_ipv4_packed_is_blocked($packed);
}

sub _safeurl_ipv4_packed_is_blocked {
    my ($packed) = @_;
    my $n = unpack( 'N', $packed );

    return 1 if ( $n >> 24 ) == 127;
    return 1 if ( $n >> 24 ) == 10;
    return 1 if ( $n & 0xfff00000 ) == 0xac100000;
    return 1 if ( $n >> 16 ) == ( 192 << 8 | 168 );
    return 1 if ( $n >> 16 ) == ( 169 << 8 | 254 );
    return 1 if ( $n >> 24 ) == 0;
    return 1 if $n == 0xffffffff;

    return 0;
}

sub enforce_access {
    my ($query) = @_;
    _access_check_rate_limit($query);
    return _access_check_auth($query);
}

sub _access_check_auth {
    my ($query) = @_;

    return _access_remote_user() if _access_remote_user() ne '';

    unless ( auth_enabled() ) {
        return 'anonymous';
    }

    my $auth_file_path = auth_file();
    unless ( -r $auth_file_path ) {
        _access_deny(
            $query,
            '503 Service Unavailable',
            'Authentication is enabled but the password file is missing or unreadable. '
              . 'Set GNSS_AUTH_FILE or create ' . escapeHTML($auth_file_path) . '.'
        );
    }

    my ( $user, $pass ) = _access_basic_credentials();
    if ( defined $user && defined $pass && _access_verify_password( $user, $pass, $auth_file_path ) ) {
        return $user;
    }

    _access_deny(
        $query,
        '401 Unauthorized',
        'Authentication required.',
        ( -WWW_Authenticate => 'Basic realm="GNSS Plotting"' )
    );
}

sub _access_check_rate_limit {
    my ($query) = @_;

    return unless rate_limit_enabled();

    my $client_ip  = _access_client_ip();
    my $max        = rate_limit_max_requests();
    my $window_sec = rate_limit_window_sec();
    my $dir        = rate_limit_dir();

    unless ( -d $dir || mkdir $dir, 0700 ) {
        return;
    }

    my $state_file = "$dir/" . sha256_hex($client_ip) . '.json';
    my $now        = time();
    my @times;

    if ( open my $fh, '+<', $state_file ) {
        flock $fh, LOCK_EX;
        my $raw = do { local $/; <$fh> };
        if ( defined $raw && $raw =~ /\S/ ) {
            @times = grep { $_ =~ /^\d+$/ } split /,/, $raw;
        }
        @times = grep { $_ > ( $now - $window_sec ) } @times;

        if ( @times >= $max ) {
            my $retry_after = $times[0] + $window_sec - $now;
            $retry_after = 1 if $retry_after < 1;
            flock $fh, LOCK_UN;
            close $fh;
            _access_deny(
                $query,
                '429 Too Many Requests',
                "Rate limit exceeded ($max requests per $window_sec seconds). Try again in $retry_after seconds.",
                ( -Retry_After => $retry_after )
            );
        }

        push @times, $now;
        seek $fh, 0, 0;
        truncate $fh, 0;
        print {$fh} join( ',', @times );
        flock $fh, LOCK_UN;
        close $fh;
        return;
    }

    if ( open my $fh, '>', $state_file ) {
        print {$fh} $now;
        close $fh;
    }
}

sub _access_client_ip {
    if ( trust_proxy() ) {
        my $xff = $ENV{HTTP_X_FORWARDED_FOR} // '';
        if ( $xff =~ /^\s*([^,\s]+)/ ) {
            return $1;
        }
    }
    return $ENV{REMOTE_ADDR} // '0.0.0.0';
}

sub _access_remote_user {
    my $user = $ENV{REMOTE_USER} // '';
    $user =~ s/^\s+|\s+$//g;
    return $user;
}

sub _access_basic_credentials {
    my $header = $ENV{HTTP_AUTHORIZATION} // '';
    return unless $header =~ /^Basic\s+(.+)$/i;
    my $decoded = decode_base64($1);
    return unless defined $decoded;
    my ( $user, $pass ) = split /:/, $decoded, 2;
    return unless defined $user && $user ne '';
    $pass = '' unless defined $pass;
    return ( $user, $pass );
}

sub _access_verify_password {
    my ( $user, $pass, $auth_file_path ) = @_;

    open my $fh, '<', $auth_file_path or return 0;
    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /^\s*#/ || $line !~ /\S/;
        my ( $entry_user, $hash ) = split /:/, $line, 2;
        next unless defined $hash && $hash ne '';
        next unless $entry_user eq $user;
        return crypt( $pass, $hash ) eq $hash;
    }
    return 0;
}

sub _access_deny {
    my ( $query, $status, $message, %extra_headers ) = @_;
    print $query->header(
        -type    => 'text/html',
        -charset => 'utf-8',
        -status  => $status,
        %extra_headers,
    );
    print '<!DOCTYPE html><html><head><title>', escapeHTML($status),
      '</title></head><body><p>', escapeHTML($message), "</p></body></html>\n";
    exit;
}

#$upload_dir = "/home8/trimblet/public_html/cgi-bin/tmp/"
#$upload_dir = "/run/shm/"

1;
