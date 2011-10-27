#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 3;

BEGIN { require_plasxom }

{
    package plasxom;

    no strict 'refs';
    no warnings 'redefine';
    for my $phase (qw( plugins flavour entries )) {
        *{"prepare_${phase}"} = sub {
            package main;
            ok(1);
        };
    }
}

my $app = plasxom->new;
   $app->prepare;