#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use List::MoreUtils;
use Scalar::Util 'blessed';

{
    use smartmatch sub {
        if (blessed($_[1])) {
            return overload::Method($_[1], '~~')->($_[1], $_[0]);
        }
        elsif (ref($_[1])) {
            return $_[1]->($_[0]);
        }
        else {
            return $_[1] eq "foo";
        }
    };

    ok("a" ~~ any(1, 2, "foo"));
    ok(!("a" ~~ any(1, 2, 3)));

    ok("a" ~~ all("foo", "foo", "foo"));
    ok(!("a" ~~ all("a", 2, "foo")));
}

sub any {
    my @rvals = @_;

    return sub {
        my ($lval) = @_;

        my $recurse = smartmatch::callback_at_level(1);
        return List::MoreUtils::any { $recurse->($lval, $_) } @rvals;
    }
}

{
    package Sugar::All;
    use overload '~~' => 'sm_overload';

    sub new {
        my $class = shift;
        my (%params) = @_;
        return bless { rvals => $params{rvals} }, $class;
    }

    sub sm_overload {
        my $self = shift;
        my ($lval) = @_;

        my $recurse = smartmatch::callback_at_level(1);
        return List::MoreUtils::all { $recurse->($lval, $_) }
                                    @{ $self->{rvals} };
    }
}

sub all {
    my @rvals = @_;
    return Sugar::All->new(rvals => \@rvals);
}

done_testing;
