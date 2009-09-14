#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

can_ok( 'hlosxom::util', 'parse_tags' );

is_deeply(
    [ hlosxom::util::parse_tags(q{[qw( AAA BBB CCC )]}) ],
    [qw( AAA BBB CCC )]
);
