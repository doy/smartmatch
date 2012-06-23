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

        my $recurse = get_smartmatch_callback();
        return List::MoreUtils::any { $recurse->($lval, $_) } @rvals;
    }
}

sub get_smartmatch_callback {
    my $hh = (caller(2))[10];
    my $engine = $hh ? $hh->{'smartmatch/engine'} : undef;

    my $recurse;
    if ($engine) {
        $recurse = eval <<"RECURSE";
            use smartmatch '$engine';
            sub { \$_[0] ~~ \$_[1] }
RECURSE
    }
    else {
        $recurse = sub { $_[0] ~~ $_[1] };
    }
}

done_testing;
