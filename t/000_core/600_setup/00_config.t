#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 1;

require_hlosxom;

hlosxom->config( hlosxom::config->new( foo => 'bar' ) );

local $ENV{'HLOSXOM_CONFIG'} = $example->file('core/setup/config/config.pl');

hlosxom->setup_config;

is_deeply(
    hlosxom->config,
    {
        foo => 'bar',
        bar => 'baz',
    },
);

