#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

can_ok( 'plasxom::util', 'env_value' );

local $ENV{'PLASXOM_FOO'} = 'bar';

is( plasxom::util::env_value('foo'), 'bar' );
