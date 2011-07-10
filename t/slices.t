#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my @nums = (1..10);

{
    use smartmatch sub {
        return ref $_[0] eq 'ARRAY'
            && ref $_[1] eq 'ARRAY'
            && @{ $_[0] } == @{ $_[1] };
    };
    ok(@nums[0..-1] ~~ []);
    ok(!(@nums[0..1] ~~ [0..2]));
    ok(@nums[0..4] ~~ [1..5]);
    ok(!(undef ~~ @nums[0..-1]));
    ok(!(@nums[0..1] ~~ 2));
}

done_testing;
