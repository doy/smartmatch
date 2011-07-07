#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

ok(1 ~~ 1);
{
    use smartmatch sub { 0 };
    ok(!(1 ~~ 1));
}
ok(1 ~~ 1);

done_testing;
