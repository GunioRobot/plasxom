#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 1;

require_plasxom;

plasxom->config( plasxom::hash->new( foo => 'bar' ) );

local $ENV{'PLASXOM_CONFIG'} = $example->file('core/setup/config/config.pl');

plasxom->setup_config;

is_deeply(
    plasxom->config,
    {
        foo => 'bar',
        bar => 'baz',
    },
);

