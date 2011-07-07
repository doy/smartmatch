#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    ok(1 ~~ 1);
    ok(!(1 ~~ 0));
    {
        ok(1 ~~ 1);
        ok(!(1 ~~ 0));
        use smartmatch sub { 0 };
        ok(!(1 ~~ 1));
        ok(!(1 ~~ 0));
        {
            ok(!(1 ~~ 1));
            ok(!(1 ~~ 0));
            use smartmatch sub { 1 };
            ok(1 ~~ 1);
            ok(1 ~~ 0);
            use smartmatch sub { 0 };
            ok(!(1 ~~ 1));
            ok(!(1 ~~ 0));
            use smartmatch sub { 1 };
            ok(1 ~~ 1);
            ok(1 ~~ 0);
        }
        ok(!(1 ~~ 1));
        ok(!(1 ~~ 0));
    }
    ok(1 ~~ 1);
    ok(!(1 ~~ 0));
}

{
    ok(eval "1 ~~ 1");
    ok(!eval "1 ~~ 0");
    {
        ok(eval "1 ~~ 1");
        ok(!eval "1 ~~ 0");
        use smartmatch sub { 0 };
        ok(!eval "1 ~~ 1");
        ok(!eval "1 ~~ 0");
        {
            ok(!eval "1 ~~ 1");
            ok(!eval "1 ~~ 0");
            use smartmatch sub { 1 };
            ok(eval "1 ~~ 1");
            ok(eval "1 ~~ 0");
            use smartmatch sub { 0 };
            ok(!eval "1 ~~ 1");
            ok(!eval "1 ~~ 0");
            use smartmatch sub { 1 };
            ok(eval "1 ~~ 1");
            ok(eval "1 ~~ 0");
        }
        ok(!eval "1 ~~ 1");
        ok(!eval "1 ~~ 0");
    }
    ok(eval "1 ~~ 1");
    ok(!eval "1 ~~ 0");
}

{
    use smartmatch sub { 0 };
    require 't/lib/lexical.pl';
}

done_testing;
