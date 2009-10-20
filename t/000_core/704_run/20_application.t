#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 4;

BEGIN { require_plasxom };

{
    package plasxom;
    
    no strict 'refs';
    no warnings 'redefine';
    
    *{'setup'} = sub {
        package main;
        
        ok(1);
    };

    package test_middleware;

    use base qw( Plack::Middleware );
    
    sub call {
        my ( $self, $env ) = @_;
        return $self->app;
    }

    sub wrap {
        our ( $mw, $app, @args ) = @_;

        package main;

        is( $test_middleware::app, plasxom->can('handler') );
        is_deeply( [ @test_middleware::args ], [qw( foo  )] );

        package test_middleware;
        
        $mw->SUPER::wrap( @_ );
    }

}

plasxom->server({
    middleware => [
        [ 'test_middleware', qw( foo  ) ],
    ],
});

my $app = plasxom->application;

isa_ok( $app, 'CODE' );
