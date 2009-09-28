#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

my @props = qw( year month day flavour url path filename tags meta );

plan tests => 1 + 1 + scalar(@props);

my $flavour = hlosxom::flavour->new();

isa_ok( $flavour, 'hlosxom::flavour' );

can_ok( $flavour, @props );

for my $prop ( @props ) {
    $flavour->$prop('foo');
    is( $flavour->$prop, 'foo' );
}
