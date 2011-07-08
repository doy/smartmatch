package smartmatch::engine::rjbs;
use strict;
use warnings;

use overload ();
use Scalar::Util qw(blessed reftype);

sub type {
    my ($thing) = @_;

    if (!defined($thing)) {
        return 'undef';
    }
    elsif (!ref($thing)) {
        return 'unknown non-ref';
    }
    elsif (reftype($thing) eq 'REGEXP') {
        return 'Regex';
    }
    elsif (blessed($thing)) {
        if (overload::Method($thing, '~~')) {
            return 'Overloaded';
        }
        elsif (overload::Method($thing, '=~')) {
            return 'Regex';
        }
        else {
            return 'unknown object';
        }
    }
    elsif (reftype($thing) eq 'CODE') {
        return 'Code';
    }
    else {
        return 'unknown';
    }
}

sub match {
    my ($a, $b) = @_;

    if (type($b) eq 'undef') {
        return !defined($a);
    }
    elsif (type($b) eq 'Overloaded') {
        my $overload = overload::Method($b, '~~');
        return $b->$overload($a, 1);
    }
    elsif (type($b) eq 'Regex') {
        return $a =~ $b;
    }
    elsif (type($b) eq 'Code') {
        return $b->($a);
    }
    else {
        $a //= 'undef';
        $b //= 'undef';
        die "invalid smart match: $a ~~ $b";
    }
}

1;
