#!perl

use strict;
use warnings;

use t::Util qw( $script );
use Test::More tests => 1;

BEGIN {
    local $ENV{'HLOSXOM_BOOTSTRAP'} = 0;
    local $ENV{'HLOSXOM_PSGI'}      = 0;
    require_ok( $script );
}
