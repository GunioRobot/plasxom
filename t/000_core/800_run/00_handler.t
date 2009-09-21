#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 3;

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
    }
}

hlosxom->config->merge(
    server => {
        interface => 'Test',
    },
);

hlosxom->setup_engine;

my $res = hlosxom->server->run( HTTP::Request->new( GET => 'http://localhost/' ) );

is( $res->content, 'hello world!' );
