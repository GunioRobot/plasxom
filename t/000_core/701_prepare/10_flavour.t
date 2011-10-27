#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Plack::Request;
use Test::More tests => 4;

require_plasxom;

{
    package plugins;

    sub new { bless {}, shift }

    sub run_plugins {
        our ( $self, $method, @args ) = @_;
        package main;

        is( $plugins::method, 'flavour' );
        is( scalar( @plugins::args ), 1 );

        is_deeply(
            [ @plugins::args ],
            [ plasxom::flavour->new( no_matched => 1, flavour => 'atom', url => 'http://localhost/', path_info => '/foo/bar.html' ) ],
        );
    }
}

plasxom->config->merge(
    dispatch => {
        regexp  => {},
        rule    => [],
    },
    flavour => {
        default => 'atom',
    }
);

plasxom->setup_dispatcher;

my $app = plasxom->new;
   $app->req( Plack::Request->new({ 'psgi.url_scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/foo/bar.html', REQUEST_METHOD => 'GET', }) );
   $app->plugins( plugins->new );
   $app->prepare_flavour;

is_deeply(
    $app->flavour,
    plasxom::flavour->new( no_matched => 1, flavour => 'atom', url => 'http://localhost/', path_info => '/foo/bar.html' ),
);