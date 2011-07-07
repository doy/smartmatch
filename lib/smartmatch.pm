package smartmatch;
use strict;
use warnings;
# ABSTRACT: pluggable smart matching backends

use parent 'DynaLoader';
use B::Hooks::OP::Check;

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap(
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $smartmatch::{VERSION}
        ? ${ $smartmatch::{VERSION} } : (),
);

sub import {
    my $package = shift;
    my ($cb) = @_;

    if (!ref($cb)) {
        my $engine = "smartmatch::engine::$cb";
        eval "require $engine; 1"
            or die "Couldn't load smartmatch engine $engine: $@";
        $cb = $engine->can('match') unless ref($cb);
    }

    smartmatch::register($cb);
}

sub unimport {
    smartmatch::unregister();
}

1;
