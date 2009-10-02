#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config->merge(
    vars => {
        foo => 'bar',
    },
);

hlosxom->setup_vars;

is_deeply(
    hlosxom->vars,
    hlosxom::hash->new( foo => 'bar' ),
);
