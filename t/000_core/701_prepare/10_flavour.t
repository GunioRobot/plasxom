#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use HTTP::Engine::Test::Request;
use Test::More tests => 4;

require_hlosxom;

{
    package plugins;
    
    sub new { bless {}, shift }
    
    sub run_plugins {
        our ( $self, $method, @args ) = @_;
        package main;
        
        is( $plugins::method, 'prepare_flavour' );
        is( scalar( @plugins::args ), 1 );

        is_deeply(
            [ @plugins::args ],
            [ hlosxom::flavour->new( no_matched => 1, url => 'http://localhost/foo/bar.html' ) ],
        );
    }
}

hlosxom->config->merge(
    dispatch => {
        regexp  => {},
        rule    => [],
    }
);

hlosxom->setup_dispatcher;

my $app = hlosxom->new;
   $app->req( HTTP::Engine::Test::Request->new( uri => 'http://localhost/foo/bar.html', method => 'GET' ) );
   $app->plugins( plugins->new );
   $app->prepare_flavour;

is_deeply(
    $app->flavour,
    hlosxom::flavour->new( no_matched => 1, url => 'http://localhost/foo/bar.html' ),
);