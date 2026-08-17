#!/usr/bin/env perl
use strict;
use warnings;

my ( $user, $pass ) = @ARGV;
if ( !defined $user || !defined $pass || $user eq '' ) {
    print STDERR "Usage: $0 username password\n";
    exit 1;
}

if ( $user =~ /:/ ) {
    print STDERR "Username must not contain ':'\n";
    exit 1;
}

my @salt_chars = ( '.', '/', '0' .. '9', 'A' .. 'Z', 'a' .. 'z' );
my $salt = '$6$' . join '', map { $salt_chars[ rand @salt_chars ] } 1 .. 16;
my $hash = crypt( $pass, $salt );

print "$user:$hash\n";
