#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

plasxom->config->merge(
    server => {
        middleware  => [
            [ 'Plack::Middleware::foo', 'foo' => 'bar' ],
        ],
    },
);

plasxom->setup_engine;

is_deeply(
    plasxom->server,
    {
        middleware => [
            [ 'Plack::Middleware::foo', foo => 'bar' ],
        ],
    }
);