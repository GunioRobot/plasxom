#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 4;

BEGIN { require_plasxom; }

{
    package plasxom;

    no strict 'refs';
    no warnings 'redefine';
    *{'run'} = sub {
        our $app = shift;
        $app->res->body('hello world!');

        package main;
        my $plasxom = $plasxom::app;

        isa_ok( $plasxom->req, 'Plack::Request' );
        isa_ok( $plasxom->res, 'Plack::Response' );
    };

    package plugins;
    
    sub new { bless {}, shift }
    sub context {
        our ( $self, $context ) = @_;
        package main;
        isa_ok( $plugins::context, 'plasxom' );
    }

}

plasxom->config->merge(
    server => {
        interface => 'CGI',
    },
);

plasxom->setup_engine;
plasxom->plugins( plugins->new );

my $res = &plasxom::handler( { 'psgi.scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/', REQUEST_METHOD => 'GET' } );

is_deeply(
    $res,
    [
        200,
        [],
        ['hello world!'],
    ]
);
