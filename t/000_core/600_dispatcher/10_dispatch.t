#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1 + 6 + 2 + 8 + 1;
use HTTP::Engine::Test::Request;

require_hlosxom;

my $dispatcher = hlosxom::dispatcher->new(
    rule => [
        {
            path        => '/{year}/{month}/{day}(?:[.]{flavour})',
            condition   => {
                method      => 'POST',
                function    => sub {
                    my ( $req ) = @_;
                    isa_ok( $req, 'HTTP::Engine::Request' );
                    return 1;
                },
            },
        },
        {
            path        => '/{meta.author}/{year}/{month}/{day}/{stash.datesection}(?:[.]{flavour})',
            flavour     => {
                'meta.category' => 'foo',
                'stash.foo'     => 'bar',
                'filename'      => 'bar',
            },
            after_hook  => sub {
                my ( $req, $flav ) = @_;
                isa_ok( $req, 'HTTP::Engine::Request' );
                isa_ok( $flav, 'hlosxom::flavour' );
            },
        },
    ],
    regexp  => {
        'meta.author'       => qr{([a-zA-z0-9]+)},
        'stash.datesection'  => qr{(\d+)},
    },
);

my $req     = HTTP::Engine::Test::Request->new( uri => 'http://localhost/2009/01/10.html', method => 'POST', env => [ PATH_INFO => '/2009/01/10.html' ] );
my $flav    = $dispatcher->dispatch( $req );

is( $flav->url, 'http://localhost' );
is( $flav->path_info, '/2009/01/10.html' );
is( $flav->year, 2009 );
is( $flav->month, '01' );
is( $flav->day, 10 );
is( $flav->flavour, 'html' );

$req    = HTTP::Engine::Test::Request->new( uri => 'http://localhost/nyarla/2008/02/21/3.json', method => 'GET', env => [ PATH_INFO => '/nyarla/2008/02/21/3.json' ] );
$flav   = $dispatcher->dispatch( $req );

is( $flav->url, 'http://localhost' );
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

$req    = HTTP::Engine::Test::Request->new( uri => 'http://localhost/foo/bar/baz.html', method => 'GET', headers => [ PATH_INFO => '/foo/bar/baz.html' ] );
$flav   = $dispatcher->dispatch( $req );

ok( $flav->no_matched );
