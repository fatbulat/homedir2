#!/usr/bin/perl -w
use strict;

use IPC::Open3 qw(open3);

my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, 'git', 'br');
my $output;
while(<CHLD_OUT>) {
    $output = $_ if /^\*/;
}
close CHLD_IN;
close CHLD_OUT;
close CHLD_ERR;
waitpid $pid, 0;

if($output) {
    chomp $output;
    $output =~s/^[\s\*]*//g;
    $output =~s/[\s\*]*$//g;
    print "[$output]\n";
}




