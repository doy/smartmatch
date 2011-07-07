package smartmatch;
use strict;
use warnings;
# ABSTRACT: pluggable smart matching backends

use parent 'DynaLoader';
use B::Hooks::OP::Check;
use B::Hooks::EndOfScope;

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
    $cb = $cb->can('match') unless ref($cb);

    $^H ||= 0x020000; # HINT_LOCALIZE_HH

    $package->unimport;
    $^H{'smartmatch_cb'} = smartmatch::register($cb);
    on_scope_end { $package->unimport };
}

sub unimport {
    return unless exists $^H{'smartmatch_cb'};
    smartmatch::unregister(delete $^H{'smartmatch_cb'});
}

1;
