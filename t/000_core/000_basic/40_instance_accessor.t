#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More;

require_plasxom;

my @properties = qw( request response flavour );
my %alias = ( req => 'request', res => 'response' );

plan tests => 1 + scalar(@properties) + ( scalar(keys %alias) * 2 );

my $plasxom = plasxom->new;

can_ok( $plasxom, @properties );

for my $prop ( @properties ) {
    $plasxom->$prop('foo');
    is( $plasxom->$prop, 'foo' );
}

for my $alias ( keys %alias ) {
    my $prop = $alias{$alias};

    $plasxom->$alias('bar');
    is( $plasxom->$prop, 'bar' );

    $plasxom->$prop('baz');
    is( $plasxom->$alias, 'baz' );
}
