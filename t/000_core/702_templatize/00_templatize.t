#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 11;
use HTTP::Engine::Test::Request;
use HTTP::Engine::Response;

require_hlosxom;

{
    package plugins;
    
    sub new { bless {}, shift }
    
    sub run_plugins {
        our ( $self, $method, @args ) = @_;

        package main;
        
        if ( $plugins::method eq 'templatize' ) {
            is_deeply(
                [ @plugins::args ],
                [
                    \q{text/plain;},
                    \q{text/plain;},
                    {
                        entries => [qw( foo bar baz )],
                        flavour => hlosxom::flavour->new( flavour => 'atom', path_info => '/foo/bar/baz.atom' ),
                    }
                ]
            );
        }
        elsif ( $plugins::method eq 'output' ) {
            is_deeply(
                [ @plugins::args ],
                [ \q{bar}, ],
            );
        }

    }

    package entries;
    
    sub new { bless {}, shift }
    
    sub filtered { [qw( foo bar baz )] }

}

my $app = hlosxom->new;
   $app->flavour( hlosxom::flavour->new( flavour => 'atom', path_info => '/foo/bar/baz.atom' ) );
   $app->plugins( plugins->new );
   $app->entries( entries->new );
   $app->methods->{'template'}      = sub {
        my ( $app, $path, $chunk, $flavour ) = @_;

        is( $path, '/foo/bar/baz.atom' );
        is( $flavour, 'atom' );
        ok( $chunk eq 'template' || $chunk eq 'content_type' );

        return 'text/plain;';
   };
   $app->methods->{'interpolate'}   = sub {
        my ( $app, $template, $vars ) = @_;
        is_deeply(
            [ $template, $vars ],
            [ 'text/plain;', { entries => [qw( foo bar baz )], flavour => hlosxom::flavour->new( flavour => 'atom', path_info => '/foo/bar/baz.atom' ), } ],
        );

        return 'bar';
   };
   $app->req( HTTP::Engine::Test::Request->new( uri => 'http://localhost/foo/bar/baz.atom', method => 'GET', env => [ PATH_INFO => '/foo/bar/baz.atom' ] ) );
   $app->res( HTTP::Engine::Response->new );
   $app->templatize;
   
   is( $app->res->headers->header('Content-Type'), 'text/plain;' );
   is( $app->res->body, 'bar' );
