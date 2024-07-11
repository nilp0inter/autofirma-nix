#!/usr/bin/env perl
use strict;
use warnings;

my $specified_hash = "";
my $got_hash = "";

while (my $line = <STDIN>) {
    print $line;

    if ($line =~ /specified:\s+(\S+)/) {
        $specified_hash = $1;
    } elsif ($line =~ /got:\s+(\S+)/) {
        $got_hash = $1;
    }

    if ($specified_hash && $got_hash) {
        my $command = "find . -type f -name '*.nix' -print0 | xargs -0 sed -i -e 's/$specified_hash/$got_hash/g'";
        system($command);
        print "Executed: $command\n";

        $specified_hash = "";
        $got_hash = "";
    }
}
