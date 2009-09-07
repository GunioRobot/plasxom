#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

my $config = hlosxom::config->new(
    foo => 'AAA',
    bar => {
        baz => 'BBB',
    },
);

$config->merge_config(
    bar => {
        baz => 'CCC',
        foo => 'BBB',
    },
);

is_deeply(
    $config,
    {
        foo => 'AAA',
        bar => {
            baz => 'CCC',
            foo => 'BBB',
        },
    },
);

isa_ok( $config, 'hlosxom::config' );
