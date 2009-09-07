#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

my $config = hlosxom::config->new( foo => 'bar' );

isa_ok( $config, 'hlosxom::config' );

is_deeply( $config, { foo => 'bar' } );
