#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom require_plugin $example );
use Test::More tests => 3;

require_hlosxom;
require_plugin('datesection');

my $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

hlosxom->entries( $entries );

my $app     = hlosxom->new;
my $plugin  = hlosxom::plugin::datesection->new( config => {}, state => $example->subdir('plugin/datesection') );

isa_ok( $plugin, 'hlosxom::plugin::datesection' );

$plugin->entries( $app, [] );

is( $entries->entry( path => 'foo/BBB' )->stash->{'datesection'}, 1 );
is( $entries->entry( path => 'foo/CCC' )->stash->{'datesection'}, 2 );
