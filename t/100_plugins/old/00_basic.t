#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More;

require_plasxom;
require_plugin('old');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('plugin/old/entries'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    readonly        => 1,
);

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::old->new( config => {}, state => $example->subdir('plugin/old/state') );

$plugin->update( $app, $entries );

my @props = qw( year month day hour minute second );

plan tests => scalar(@props) * scalar(@{ $entries->index });

for my $entry ( @{ $entries->index } ) {
    for my $prop ( @props ) {
        like( $entry->stash->{"old.${prop}"}, qr{^\d+$} );
    }
}
