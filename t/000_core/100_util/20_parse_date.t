#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

use Time::Local

require_hlosxom;

my %date   = (
    '2009'                    => 1230768000 - timegm(localtime 0),
    '2009-01'                 => 1230768000 - timegm(localtime 0),
    '2009-02-03'              => 1233619200 - timegm(localtime 0),
    '2009-03-04T10:20'        => 1236162000 - timegm(localtime 0),
    '2009-04-05T10:20:30'     => 1238926830 - timegm(localtime 0),
    '2009-07-08T10:20+09:00'  => 1247016000,
    '2009-07-08T10:20Z'       => 1247048400,
);

plan tests => 1 + scalar(keys %date);

can_ok( 'hlosxom::util', 'parse_date' );

my $method = hlosxom::util->can('parse_date');

for my $source ( keys %date ) {
    is( $method->($source), $date{$source} );
}