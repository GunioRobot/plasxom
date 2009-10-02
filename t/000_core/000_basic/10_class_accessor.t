#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

my @properties = qw( config plugins methods vars cache entries entries_schema_class server dispatcher );

plan tests => 1 + scalar(@properties);

can_ok( 'hlosxom', @properties );

for my $prop ( @properties ) {
    hlosxom->$prop( {} );
    isa_ok( hlosxom->$prop, 'HASH' );
}
