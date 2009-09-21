#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

isa_ok(
    hlosxom->new,
    'hlosxom',
);
