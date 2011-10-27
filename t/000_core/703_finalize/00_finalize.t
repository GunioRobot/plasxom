#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

{
    package plugins;

    sub new { bless {}, shift }

    sub run_plugins {
        our ( $self, $method ) = @_;
        package main;

        is( $plugins::method, 'end' );
    }
}

my $app = plasxom->new;
   $app->plugins( plugins->new );
   $app->finalize;
