#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

can_ok( 'plasxom::util', 'format_tags' );

is( plasxom::util::format_tags(qw( foo bar baz )), q{['foo','bar','baz']} );
