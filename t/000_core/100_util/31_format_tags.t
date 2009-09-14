#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

can_ok( 'hlosxom::util', 'format_tags' );

is( hlosxom::util::format_tags(qw( foo bar baz )), q{['foo','bar','baz']} );
