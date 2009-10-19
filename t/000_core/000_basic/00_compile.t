#!perl

use strict;
use warnings;

use t::Util qw( $script );
use Test::More tests => 1;

BEGIN {
    local $ENV{'PLASXOM_LIBMODE'} = 1;
    require_ok( $script );
}
