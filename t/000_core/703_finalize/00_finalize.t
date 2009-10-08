#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

{
    package plugins;
    
    sub new { bless {}, shift }
    
    sub run_plugins {
        our ( $self, $method ) = @_;
        package main;
        
        is( $plugins::method, 'end' );
    }
}

my $app = hlosxom->new;
   $app->plugins( plugins->new );
   $app->finalize;
