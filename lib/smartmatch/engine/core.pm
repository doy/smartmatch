package smartmatch::engine::core;
use strict;
use warnings;

use B;
use Scalar::Util qw(blessed looks_like_number reftype);
use overload ();

sub type {
    my ($thing) = @_;

    if (!defined($thing)) {
        return 'undef';
    }
    elsif (blessed($thing) && reftype($thing) ne 'REGEXP') {
        return 'Object';
    }
    elsif (my $reftype = reftype($thing)) {
        if ($reftype eq 'ARRAY') {
            return 'Array';
        }
        elsif ($reftype eq 'HASH') {
            return 'Hash';
        }
        elsif ($reftype eq 'REGEXP') {
            return 'Regex';
        }
        elsif ($reftype eq 'CODE') {
            return 'CodeRef';
        }
        else {
            return 'unknown ref';
        }
    }
    else {
        my $b = B::svref_2object(\$thing);
        my $flags = $b->FLAGS;
        if (($flags & B::SVf_NOK) && !($flags & B::SVf_POK)) {
            return 'Num';
        }
        elsif (looks_like_number($thing)) {
            return 'numish';
        }
        else {
            return 'unknown';
        }
    }
}

sub match {
    my ($a, $b) = @_;

    if (type($b) eq 'undef') {
        return !defined($a);
    }
    elsif (type($b) eq 'Object') {
        my $overload = overload::Method($b, '~~');
        die "no ~~ overloading on $b"
            unless $overload;
        return $b->$overload($a, 1);
    }
    elsif (type($b) eq 'CodeRef') {
        if (type($a) eq 'Hash') {
            return !grep { !$b->($_) } keys %$a;
        }
        elsif (type($a) eq 'Array') {
            return !grep { !$b->($_) } @$a;
        }
        else {
            return $b->($a);
        }
    }
    elsif (type($b) eq 'Hash') {
        if (type($a) eq 'Hash') {
            return match([sort keys %$a], [sort keys %$b]);
        }
        elsif (type($a) eq 'Array') {
            return grep { exists $b->{$_ // ''} } @$a;
        }
        elsif (type($a) eq 'Regex') {
            return grep /$a/, keys %$b;
        }
        elsif (type($a) eq 'undef') {
            return;
        }
        else {
            return exists $b->{$a};
        }
    }
    elsif (type($b) eq 'Array') {
        if (type($a) eq 'Hash') {
            return grep { exists $a->{$_ // ''} } @$b;
        }
        elsif (type($a) eq 'Array') {
            return unless @$a == @$b;
            for my $i (0..$#$a) {
                return unless match($a->[$i], $b->[$i]);
            }
            return 1;
        }
        elsif (type($a) eq 'Regex') {
            return grep /$a/, @$b;
        }
        elsif (type($a) eq 'undef') {
            return grep !defined, @$b;
        }
        else {
            return grep { match($a, $_) } @$b;
        }
    }
    elsif (type($b) eq 'Regex') {
        if (type($a) eq 'Hash') {
            return grep /$b/, keys %$a;
        }
        elsif (type($a) eq 'Array') {
            return grep /$b/, @$a;
        }
        else {
            return $a =~ $b;
        }
    }
    elsif (type($a) eq 'Object') {
        my $overload = overload::Method($a, '~~');
        return $a->$overload($b, 0) if $overload;
    }

    if (type($b) eq 'Num') {
        return $a == $b;
    }
    elsif (type($a) eq 'Num' && type($b) eq 'numish') {
        return $a == $b;
    }
    elsif (type($a) eq 'undef') {
        return !defined($b);
    }
    else {
        return $a eq $b;
    }
}

1;
