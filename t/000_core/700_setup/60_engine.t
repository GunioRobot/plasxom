#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config->merge(
    server => {
        interface => 'CGI',
        middleware  => [
            [ 'Plack::Middleware::foo', 'foo' => 'bar' ],
        ],
        foobar  => 'baz',
    },
);

hlosxom->setup_engine;

is_deeply(
    hlosxom->server,
    {
        interface => 'CGI',
        middleware => [
            [ 'Plack::Middleware::foo', foo => 'bar' ],
        ],
        args    => {
            foobar => 'baz',
        }
    }
);