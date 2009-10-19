#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1 + 6 + 2 + 8 + 1;
use Plack::Request;

require_plasxom;

my $dispatcher = plasxom::dispatcher->new(
    rule => [
        {
            path        => '/{year}/{month}/{day}(?:[.]{flavour})',
            condition   => {
                method      => 'POST',
                function    => sub {
                    my ( $req ) = @_;
                    isa_ok( $req, 'Plack::Request' );
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
                isa_ok( $req, 'Plack::Request' );
                isa_ok( $flav, 'plasxom::flavour' );
            },
        },
    ],
    regexp  => {
        'meta.author'       => qr{([a-zA-z0-9]+)},
        'stash.datesection'  => qr{(\d+)},
    },
);

my $req     = Plack::Request->new({ 'psgi.url_scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/2009/01/10.html', REQUEST_METHOD => 'POST', });
my $flav    = $dispatcher->dispatch( $req );

is( $flav->url, 'http://localhost' );
is( $flav->path_info, '/2009/01/10.html' );
is( $flav->year, 2009 );
is( $flav->month, '01' );
is( $flav->day, 10 );
is( $flav->flavour, 'html' );

$req     = Plack::Request->new({ 'psgi.url_scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/nyarla/2008/02/21/3.json', REQUEST_METHOD => 'GET', });
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

$req     = Plack::Request->new({ 'psgi.url_scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/foo/bar/baz.html', REQUEST_METHOD => 'GET', });
$flav   = $dispatcher->dispatch( $req );

ok( $flav->no_matched );
