#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More;

require_plasxom;

my @properties = qw( config plugins methods vars cache entries entries_schema_class server dispatcher api );

plan tests => 1 + scalar(@properties);

can_ok( 'plasxom', @properties );

for my $prop ( @properties ) {
    plasxom->$prop( {} );
    isa_ok( plasxom->$prop, 'HASH' );
}
