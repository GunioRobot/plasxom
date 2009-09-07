#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

my $hashA = {
    foo => 'AAA',
    bar => {
        baz => 'BBB',
    },
};

my $hashB = {
    foo => [qw( AAA BBB )],
    bar => {
        buz => 'CCC',
    },
};

is_deeply(
    hlosxom::util::merge_hash( $hashA, $hashB ),
    {
        foo => [qw( AAA BBB )],
        bar => {
            baz => 'BBB',
            buz => 'CCC',
        },
    },
);
