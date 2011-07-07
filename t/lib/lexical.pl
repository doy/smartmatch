#!/usr/bin/env perl
use strict;
use warnings;

Test::More::ok(1 ~~ 1);
Test::More::ok(!(1 ~~ 0));

1;
