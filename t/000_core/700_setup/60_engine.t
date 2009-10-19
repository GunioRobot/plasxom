#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config->merge(
    server => {
        middleware  => [
            [ 'Plack::Middleware::foo', 'foo' => 'bar' ],
        ],
    },
);

hlosxom->setup_engine;

is_deeply(
    hlosxom->server,
    {
        middleware => [
            [ 'Plack::Middleware::foo', foo => 'bar' ],
        ],
    }
);