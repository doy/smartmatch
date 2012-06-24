#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use List::MoreUtils;

{
    use smartmatch sub {
        if (ref($_[1])) {
            return $_[1]->($_[0]);
        }
        else {
            return $_[1] eq "foo";
        }
    };

    ok("a" ~~ any(1, 2, "foo"));
    ok(!("a" ~~ any(1, 2, 3)));
}

sub any {
    my @rvals = @_;

    return sub {
        my ($lval) = @_;

        my $recurse = smartmatch::get_smartmatch_callback(1);
        return List::MoreUtils::any { $recurse->($lval, $_) } @rvals;
    }
}

done_testing;
