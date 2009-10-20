#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

require_plasxom;
require_plugin('datesection');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

plasxom->entries( $entries );

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::datesection->new( config => {}, state => $example->subdir('plugin/datesection') );

isa_ok( $plugin, 'plasxom::plugin::datesection' );

$plugin->update( $app, [] );

is( $entries->entry( path => 'foo/BBB' )->stash->{'datesection'}, 1 );
is( $entries->entry( path => 'foo/CCC' )->stash->{'datesection'}, 2 );
