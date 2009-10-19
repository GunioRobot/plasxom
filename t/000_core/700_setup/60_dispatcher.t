#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

plasxom->config->merge(
    dispatch => {
        rule => [
            { path => '/{year}/{month}/{day}(?:[.]{flavour})' },
        ],
    },
);

plasxom->setup_dispatcher;

isa_ok( plasxom->dispatcher, 'plasxom::dispatcher' );
