#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 6;

require_hlosxom;

my $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    meta_mapping    => {
        created => 'date',
    }
);

$entries->num_entries(1);

is( $entries->total_page, 3 );

is( $entries->total_page( path => 'foo/' ), 2 );

$entries->num_entries(2);

is( $entries->total_page, 2 );

is( $entries->total_page( path => 'foo/' ), 1 );

$entries->num_entries(3);

is( $entries->total_page, 1 );

is( $entries->total_page( path => 'foo/' ), 1 );
