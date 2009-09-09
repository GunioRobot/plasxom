#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 2;
use File::stat;

require_hlosxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

ok( $entries->exists( path => 'foo' ) );

ok( ! $entries->exists( path => 'notfound' ) );

