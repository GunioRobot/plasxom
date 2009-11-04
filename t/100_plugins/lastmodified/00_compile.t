#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $plugindir );
use Test::More tests => 1;

BEGIN {
    require_plasxom;
    require_ok( $plugindir->file('lastmodified') );
};
