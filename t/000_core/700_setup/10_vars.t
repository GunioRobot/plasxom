#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

plasxom->config->merge(
    vars => {
        foo => 'bar',
    },
);

plasxom->setup_vars;

is_deeply(
    plasxom->vars,
    plasxom::hash->new( foo => 'bar' ),
);
