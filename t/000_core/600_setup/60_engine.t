#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config->merge(
    server => {
        interface => 'MinimalCGI',
    },
);

hlosxom->setup_engine;

isa_ok(
    hlosxom->server,
    'HTTP::Engine',
);
