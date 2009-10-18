#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 4;

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

        isa_ok( $hlosxom->req, 'Plack::Request' );
        isa_ok( $hlosxom->res, 'Plack::Response' );
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
        interface => 'CGI',
    },
);

hlosxom->setup_engine;
hlosxom->plugins( plugins->new );

my $res = &hlosxom::handler( { 'psgi.scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/', REQUEST_METHOD => 'GET' } );

is_deeply(
    $res,
    [
        200,
        [],
        ['hello world!'],
    ]
);
