#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

require_plasxom;
require_plugin('archives');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    readonly        => 1,
);

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::archives->new( config => {}, state => $example->subdir('plugin/archives') );

isa_ok( $plugin, 'plasxom::plugin::archives' );

$plugin->update( $app, $entries );

my $archives = {
    2009 => {
        count => 3,
        month => {
            '01' => 1,
            '02' => 2,
        }
    },
};

is_deeply(
    $plugin->{'archives'},
    $archives,
);

my $vars = {};
$plugin->templatize( $app, \q{}, \q{}, $vars );

is_deeply(
    $vars->{'archives'},
    $archives,
);
