#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

my $config = plasxom::hash->new( foo => 'bar' );

isa_ok( $config, 'plasxom::hash' );

is_deeply( $config, { foo => 'bar' } );
