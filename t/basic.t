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
    use smartmatch 'rjbs';
    ok([] ~~ qr/ARRAY/);
    ok(!(1 ~~ sub { 0 }));
}

done_testing;
