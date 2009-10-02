#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config->merge(
    dispatch => {
        rule => [
            { path => '/{year}/{month}/{day}(?:[.]{flavour})' },
        ],
    },
);

hlosxom->setup_dispatcher;

isa_ok( hlosxom->dispatcher, 'hlosxom::dispatcher' );
