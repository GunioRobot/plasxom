#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

require_plasxom;
require_plugin('paginate');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    num_entries     => 1,
);
plasxom->entries( $entries );

my $app = plasxom->new;
   $app->flavour( plasxom::flavour->new( path => 'foo' ) );

my $plugin = plasxom::plugin::paginate->new( config => {}, state => $example->subdir('plugin/paginate') );

isa_ok( $plugin, 'plasxom::plugin::paginate' );

my $vars = {};

$plugin->templatize( $app, \q{}, \q{}, $vars );

is_deeply(
    $vars,
    {
        paginate => {
            total   => 2,
            current => 1,
            next    => 2,
        },
    },
);

$app->flavour->page(2);

$plugin->templatize( $app, \q{}, \q{}, $vars );

is_deeply(
    $vars,
    {
        paginate => {
            total       => 2,
            current     => 2,
            previous    => 1,
            paginated   => 1,
        },
    },
);
