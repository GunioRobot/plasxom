#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

my $config = plasxom::hash->new(
    foo => 'AAA',
    bar => {
        baz => 'BBB',
    },
);

$config->merge(
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

isa_ok( $config, 'plasxom::hash' );
