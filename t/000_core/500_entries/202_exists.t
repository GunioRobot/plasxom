#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 2;
use File::stat;

require_plasxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

ok( $entries->exists( path => 'foo' ) );

ok( ! $entries->exists( path => 'notfound' ) );

