#! /usr/bin/perl -n


if ( /Total Out of range\: +(.*) +(.*)/) {
    print $2;
}
    
