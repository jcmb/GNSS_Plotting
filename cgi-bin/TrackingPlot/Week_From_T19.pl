#! /usr/bin/perl
while (<>) {
    chomp;
    if ($_ =~ /Time: .* \(sec\) +GPS Week: *([\d]+)/) {
        print $1;
        exit (0);
        }
    }
print "-1";
exit(1);
