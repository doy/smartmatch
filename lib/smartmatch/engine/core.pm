package smartmatch::engine::core;
use strict;
use warnings;

use B;
use Hash::Util::FieldHash qw(idhash);
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
        if ($flags & (B::SVf_IOK | B::SVf_NOK)) {
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
    my ($a, $b, $seen) = @_;

    if (type($b) eq 'undef') {
        return !defined($a);
    }
    elsif (type($b) eq 'Object') {
        my $overload = overload::Method($b, '~~');

        # XXX this is buggy behavior and may be changed
        # see http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2011-07/msg00214.html
        if (!$overload && overload::Overloaded($b)) {
            $overload = overload::Method($a, '~~');
            die "no ~~ overloading on $b"
                unless $overload;
            return $a->$overload($b, 0);
        }

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
            my @a = sort keys %$a;
            my @b = sort keys %$b;
            return unless @a == @b;
            for my $i (0..$#a) {
                return unless $a[$i] eq $b[$i];
            }
            return 1;
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
            if (!$seen) {
                $seen = {};
                idhash %$seen;
            }
            for my $i (0..$#$a) {
                if (defined($b->[$i]) && $seen->{$b->[$i]}++) {
                    return $a->[$i] == $b->[$i];
                }
                return unless match($a->[$i], $b->[$i], $seen);
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
            if (!$seen) {
                $seen = {};
                idhash %$seen;
            }
            return grep {
                if (defined($_) && $seen->{$_}++) {
                    return $a == $_;
                }
                match($a, $_, $seen)
            } @$b;
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

    if (type($a) eq 'undef') {
        return !defined($b);
    }
    elsif (type($b) eq 'Num') {
        no warnings 'uninitialized', 'numeric'; # ugh
        return $a == $b;
    }
    elsif (type($a) eq 'Num' && type($b) eq 'numish') {
        return $a == $b;
    }
    else {
        return $a eq $b;
    }
}

1;
