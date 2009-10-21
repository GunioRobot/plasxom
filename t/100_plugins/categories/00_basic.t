#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

require_plasxom;
require_plugin('categories');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('plugin/categories/entries'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    readonly        => 1,
);

plasxom->entries( $entries );

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::categories->new( config => {}, state => $example->subdir('plugin/categories/state') );

isa_ok( $plugin, 'plasxom::plugin::categories' );

$plugin->update( $app, $entries );

my $vars = {
    children    => {
        ''          => [
            'foo',
        ],
        'foo'       => [
            'foo/bar',
            'foo/baz',
        ],
        'foo/bar'   => [
            'foo/bar/baz',
        ],
    },
    count       => {
        '' => 11,
        'foo'           => 10,
        'foo/baz'       => 2,
        'foo/bar'       => 5,
        'foo/bar/baz'   => 3,
    },
};

is_deeply(
    $plugin->{'vars'},
    $vars,
);

my $local = {};

$plugin->templatize( $app, \q{}, \q{}, $local );

is_deeply(
    $local->{'categories'},
    $vars,
);
