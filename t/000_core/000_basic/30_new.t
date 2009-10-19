#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

isa_ok(
    plasxom->new,
    'plasxom',
);
