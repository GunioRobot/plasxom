#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

my @properties = qw( request response );
my %alias = ( req => 'request', res => 'response' );

plan tests => 1 + scalar(@properties) + ( scalar(keys %alias) * 2 );

my $hlosxom = hlosxom->new;

can_ok( $hlosxom, @properties );

for my $prop ( @properties ) {
    $hlosxom->$prop('foo');
    is( $hlosxom->$prop, 'foo' );
}

for my $alias ( keys %alias ) {
    my $prop = $alias{$alias};

    $hlosxom->$alias('bar');
    is( $hlosxom->$prop, 'bar' );

    $hlosxom->$prop('baz');
    is( $hlosxom->$alias, 'baz' );
}
