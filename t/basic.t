#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

ok(1 ~~ 1);
{
    use smartmatch sub { 0 };
    ok(!(1 ~~ 1));
    ok(!(1 ~~ 2));
}
ok(1 ~~ 1);

{
    use smartmatch 'core';
    ok(1 ~~ 1);
    ok(!(1 ~~ 2));
}

done_testing;
