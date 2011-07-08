#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use smartmatch 'rjbs';

{
    package SmartOverload;
    use overload '~~' => sub {
        no warnings 'uninitialized';
        return $_[1] eq ${ $_[0] };
    }, fallback => 1;
}

{
    package RegexOverload;
    use overload 'qr' => sub {
        return $_[0]->[0];
    }, fallback => 1;
}

{
    package StringOverload;
    use overload '""' => sub {
        return $_[0]->{val};
    }, fallback => 1;
}

sub smart  { my $val = shift; bless \$val,           SmartOverload::  }
sub regex  { my $val = shift; bless [qr/$val/],      RegexOverload::  }
sub string { my $val = shift; bless { val => $val }, StringOverload:: }

my @tests = (
    # undef
    [ 1,     undef,        undef ],
    [ 0,     '',           undef ],
    [ 0,     0,            undef ],
    [ 0,     '0',          undef ],
    [ 0,     '0.0',        undef ],
    [ 0,     '0 but true', undef ],
    [ 0,     1,            undef ],
    [ 0,     'x',          undef ],
    [ 0,     [],           undef ],
    [ 0,     {},           undef ],
    [ 0,     sub {},       undef ],
    [ 0,     smart(''),    undef ],
    [ 0,     regex(''),    undef ],
    [ 0,     string(''),   undef ],
    # smart match overload
    [ 1,     "smart",         smart('smart') ],
    [ 1,     string('smart'), smart('smart') ],
    [ 0,     "SMART",         smart('smart') ],
    [ 0,     string('SMART'), smart('smart') ],
    [ 0,     smart('smart'),  smart('smart') ],
    [ 0,     undef,           smart('smart') ],
    [ 0,     1,               smart('smart') ],
    # regex
    [ 0,     undef,         qr/a/             ],
    [ 1,     undef,         qr/a?/            ],
    [ 1,     "foo",         qr/f/             ],
    [ 0,     "foo",         qr/g/             ],
    [ 1,     1,             qr/1/             ],
    [ 0,     ['z'],         qr/z/             ],
    [ 1,     ['z'],         qr/^ARRAY/        ],
    [ 0,     {'y' => 'y'},  qr/y/             ],
    [ 1,     {'y' => 'y'},  qr/^HASH/         ],
    [ 1,     string('foo'), qr/^foo$/         ],
    [ 0,     regex('foo'),  qr/foo/           ],
    [ 1,     regex('foo'),  qr/^Regex/        ],
    [ 1,     qr/foo/,       qr/\(\?\^\:foo\)/ ],
    # regex overload
    [ 0,     undef,         regex('a')             ],
    [ 1,     undef,         regex('a?')            ],
    [ 1,     "foo",         regex('f')             ],
    [ 0,     "foo",         regex('g')             ],
    [ 1,     1,             regex('1')             ],
    [ 0,     ['z'],         regex('z')             ],
    [ 1,     ['z'],         regex('^ARRAY')        ],
    [ 0,     {'y' => 'y'},  regex('y')             ],
    [ 1,     {'y' => 'y'},  regex('^HASH')         ],
    [ 1,     string('foo'), regex('^foo$')         ],
    [ 0,     regex('foo'),  regex('foo')           ],
    [ 1,     regex('foo'),  regex('^Regex')        ],
    [ 1,     qr/foo/,       regex('\(\?\^\:foo\)') ],
    # code
    [ 1,     undef,        sub { 1 }                    ],
    [ 1,     '',           sub { 1 }                    ],
    [ 1,     0,            sub { 1 }                    ],
    [ 1,     '0',          sub { 1 }                    ],
    [ 1,     '0.0',        sub { 1 }                    ],
    [ 1,     '0 but true', sub { 1 }                    ],
    [ 1,     1,            sub { 1 }                    ],
    [ 1,     'x',          sub { 1 }                    ],
    [ 1,     [],           sub { 1 }                    ],
    [ 1,     {},           sub { 1 }                    ],
    [ 1,     sub {},       sub { 1 }                    ],
    [ 1,     smart(''),    sub { 1 }                    ],
    [ 1,     regex(''),    sub { 1 }                    ],
    [ 1,     string(''),   sub { 1 }                    ],
    [ 0,     undef,        sub { 0 }                    ],
    [ 0,     '',           sub { 0 }                    ],
    [ 0,     0,            sub { 0 }                    ],
    [ 0,     '0',          sub { 0 }                    ],
    [ 0,     '0.0',        sub { 0 }                    ],
    [ 0,     '0 but true', sub { 0 }                    ],
    [ 0,     1,            sub { 0 }                    ],
    [ 0,     'x',          sub { 0 }                    ],
    [ 0,     [],           sub { 0 }                    ],
    [ 0,     {},           sub { 0 }                    ],
    [ 0,     sub {},       sub { 0 }                    ],
    [ 0,     smart(''),    sub { 0 }                    ],
    [ 0,     regex(''),    sub { 0 }                    ],
    [ 0,     string(''),   sub { 0 }                    ],
    [ 1,     ['a', 'b'],   sub { ref $_[0] eq 'ARRAY' } ],
    [ 1,     ['a', 'b'],   sub { $_[0]->[0] eq 'a' }    ],
    [ 1,     string('x'),  sub { $_[0] eq 'x' }         ],
    [ 1,     smart('x'),   sub { 'x' ~~ $_[0] }         ],
    [ 0,     smart('x'),   sub { 'y' ~~ $_[0] }         ],
    # any
    [ 'die', undef, ''           ],
    [ 'die', undef, 0            ],
    [ 'die', undef, '0'          ],
    [ 'die', undef, '0.0'        ],
    [ 'die', undef, '0 but true' ],
    [ 'die', undef, 1            ],
    [ 'die', undef, 'x'          ],
    [ 'die', undef, []           ],
    [ 'die', undef, {}           ],
    [ 0,     undef, sub {}       ],
    [ 1,     undef, smart('')    ],
    [ 1,     undef, regex('')    ],
    [ 'die', undef, string('')   ],
);

for my $test (@tests) {
    # shut up warnings about undef =~ regex
    $SIG{__WARN__} = sub { } unless defined $test->[1];

    if ($test->[0] eq 'die') {
        ok(!eval { $test->[1] ~~ $test->[2]; 1 });
        like($@, qr/invalid smart match/);
    }
    elsif ($test->[0]) {
        ok($test->[1] ~~ $test->[2]);
    }
    else {
        ok(!($test->[1] ~~ $test->[2]));
    }

    delete $SIG{__WARN__};
}

done_testing;
