#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

can_ok( 'hlosxom::util', 'env_value' );

local $ENV{'HLOSXOM_FOO'} = 'bar';

is( hlosxom::util::env_value('foo'), 'bar' );
