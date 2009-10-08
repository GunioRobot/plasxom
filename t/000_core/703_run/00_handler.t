#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 4;

use HTTP::Request;

BEGIN { require_hlosxom; }

{
    package hlosxom;

    no strict 'refs';
    no warnings 'redefine';
    *{'run'} = sub {
        our $app = shift;
        $app->res->body('hello world!');

        package main;
        my $hlosxom = $hlosxom::app;

        isa_ok( $hlosxom->req, 'HTTP::Engine::Request' );
        isa_ok( $hlosxom->res, 'HTTP::Engine::Response' );
    };

    package plugins;
    
    sub new { bless {}, shift }
    sub context {
        our ( $self, $context ) = @_;
        package main;
        isa_ok( $plugins::context, 'hlosxom' );
    }

}

hlosxom->config->merge(
    server => {
        interface => 'Test',
    },
);

hlosxom->setup_engine;
hlosxom->plugins( plugins->new );

my $res = hlosxom->server->run( HTTP::Request->new( GET => 'http://localhost/' ) );

is( $res->content, 'hello world!' );
