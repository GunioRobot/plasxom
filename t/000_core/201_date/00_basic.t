#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 10;

require_hlosxom;

my $date = hlosxom::date->new( epoch => 1247016000 );

isa_ok( $date, 'hlosxom::date' );

is( $date->year, 2009 );

is( $date->month, '07' );
is( $date->shortmonth, 'Jul' );
is( $date->fullmonth, 'July' );

is( $date->day, '08' );

is( $date->hour, 10 );

is( $date->minute, 20 );

is( $date->second, '00' );

is( $date->dayweek, 'Wed' );
