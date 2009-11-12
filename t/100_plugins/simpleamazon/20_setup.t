#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

require_plasxom;
require_plugin('simpleamazon');

plasxom->setup_cache;
my $plugin = plasxom::plugin::simpleamazon->new( config => { locale => 'jp', apikey => 'X', secret => 'X' }, state => $example->subdir('plugin/simpleamazon/state') );

ok( $plugin->setup( 'plasxom' ) );

is_deeply(
    plasxom->api->{'API'}->{'simpleamazon.asin'},
    {
        instance => $plugin,
        function => $plugin->can('asin'),
    },
);

is(
    $plugin->{'cache'},
    plasxom->cache,
);