package smartmatch::engine::rjbs;
use strict;
use warnings;

use overload ();
use Scalar::Util qw(blessed reftype);

sub match {
    my ($a, $b) = @_;

    if (!defined($b)) {
        return !defined($a);
    }
    elsif (blessed($b) && my $overload = overload::Method($b, '~~')) {
        return $b->$overload($a, 1);
    }
    elsif (reftype($b) eq 'REGEXP') {
        return $a =~ $b;
    }
    elsif (blessed($b) && my $overload = overload::Method($b, '=~')) {
        return $a =~ $b;
    }
    elsif (!blessed($b) && reftype($b) eq 'CODE') {
        return $b->($a);
    }
    else {
        die "invalid smart match: $a ~~ $b";
    }
}

1;
