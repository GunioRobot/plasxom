#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 14;
use HTTP::Engine::MinimalCGI;
use HTTP::Request;
use HTTP::Request::AsCGI;

require_hlosxom;

my $dispatcher = hlosxom::dispatcher->new(
    rule => [
        {
            path        => '/{year}/{month}/{day}(?:[.]{flavour})',
            condition   => {
                method      => 'POST',
            },
        },
        {
            path        => '/{meta.author}/{year}/{month}/{day}/{stash.datesection}(?:[.]{flavour})',
            flavour     => {
                'meta.category' => 'foo',
                'stash.foo'     => 'bar',
                'filename'      => 'bar',
            },
        },
    ],
    regexp  => {
        'meta.author'       => qr{([a-zA-z0-9]+)},
        'stash.datesection'  => qr{(\d+)},
    },
);


{
    my $req = HTTP::Request->new( POST => 'http://localhost/2009/01/10.html' );
    my $ctx = HTTP::Request::AsCGI->new($req)->setup;
    my $engine = HTTP::Engine->new(
        interface => {
            module          => 'MinimalCGI',
            request_handler => sub {
                my ( $req ) = @_;
                my $flav = $dispatcher->dispatch( $req );
                is( $flav->url, 'http://localhost:80' );
                is( $flav->path_info, '/2009/01/10.html' );
                is( $flav->year, 2009 );
                is( $flav->month, '01' );
                is( $flav->day, 10 );
                is( $flav->flavour, 'html' );
            
                return HTTP::Engine::Response->new;
            },
        },
    );

    $engine->run;
}

{
    my $req = HTTP::Request->new( GET => 'http://localhost/nyarla/2008/02/21/3.json' );
    my $ctx = HTTP::Request::AsCGI->new($req)->setup;
    my $engine = HTTP::Engine->new(
        interface => {
            module          => 'MinimalCGI',
            request_handler => sub {
                my ( $req ) = @_;
                my $flav = $dispatcher->dispatch( $req );
                is( $flav->url, 'http://localhost:80' );
                is( $flav->path_info, '/nyarla/2008/02/21/3.json' );
                is( $flav->year, 2008 );
                is( $flav->month, '02' );
                is( $flav->day, '21' );
                is( $flav->filename, 'bar' );
                is_deeply(
                    $flav->meta,
                    {
                        author      => 'nyarla',
                        category    => 'foo',
                    },
                );
                is_deeply(
                    $flav->stash,
                    {
                        datesection => 3,
                        foo         => 'bar',
                    }
                );
                
                return HTTP::Engine::Response->new;
            },
        },
    );

    $engine->run;
}