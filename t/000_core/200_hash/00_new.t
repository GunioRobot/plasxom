#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

my $config = hlosxom::hash->new( foo => 'bar' );

isa_ok( $config, 'hlosxom::hash' );

is_deeply( $config, { foo => 'bar' } );
