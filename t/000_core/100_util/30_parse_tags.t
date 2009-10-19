#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

can_ok( 'plasxom::util', 'parse_tags' );

is_deeply(
    [ plasxom::util::parse_tags(q{[qw( AAA BBB CCC )]}) ],
    [qw( AAA BBB CCC )]
);
