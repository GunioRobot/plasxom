#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

use Time::Local;

my $tz;
my $z = timegm(localtime(0));
my $zh = $z / 3600;
my $zm = (abs($z) % 3600) / 60;
if ( $zh == 0 && $zm == 0 ) {
    $tz = 'Z';
}
else {
    $tz = sprintf("%+03d:%02d", $zh, $zm);
}

require_plasxom;

can_ok('plasxom::util', 'format_date');

my $method = plasxom::util->can('format_date');

is( $method->( 1230735600 ),  "2009-01-01T00:00:00${tz}" );
