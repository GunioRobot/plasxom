#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More;

require_plasxom;

our @phase = qw( config vars cache plugins templates entries dispatcher engine );

plan tests => scalar(@phase);

{
    package plasxom;

    for my $phase ( @main::phase ) {
        no strict 'refs';
        no warnings 'redefine';
        *{"setup_${phase}"} = sub {
            package main;
            ok(1);
        };
    }
}

plasxom->setup;