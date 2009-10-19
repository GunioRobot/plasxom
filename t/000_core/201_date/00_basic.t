#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 12;

require_plasxom;

my $date = plasxom::date->new( epoch => 1247016000 );

isa_ok( $date, 'plasxom::date' );

is( $date->year, 2009 );

is( $date->month, '07' );
is( $date->shortmonth, 'Jul' );
is( $date->fullmonth, 'July' );

is( $date->day, '08' );

is( $date->ymd, '2009-07-08' );

is( $date->hour, 10 );

is( $date->minute, 20 );

is( $date->second, '00' );

is( $date->time, '10:20:00' );

is( $date->dayweek, 'Wed' );
