#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

our @phase = qw( config vars cache plugins methods entries dispatcher engine );

plan tests => scalar(@phase);

{
    package hlosxom;

    for my $phase ( @main::phase ) {
        no strict 'refs';
        no warnings 'redefine';
        *{"setup_${phase}"} = sub {
            package main;
            ok(1);
        };
    }
}

hlosxom->setup;