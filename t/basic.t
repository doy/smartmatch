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

BEGIN {
    package smartmatch::engine::foo;
    sub match { ref($_[1]) eq 'ARRAY' }
    $INC{'smartmatch/engine/foo.pm'} = 1;
}

{
    use smartmatch 'foo';
    ok(1 ~~ []);
    ok(!(1 ~~ sub { 0 }));
}

done_testing;
