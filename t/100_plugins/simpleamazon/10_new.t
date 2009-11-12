#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 4;

require_plasxom;
require_plugin('simpleamazon');

my $plugin = plasxom::plugin::simpleamazon->new(
    config => {
        locale => 'jp',
        apikey => 'XXXXXXXXXXXXXXXXXXXX',
        secret => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    },
    state => $example->subdir('plugin/simpleamazon/state'),
);

isa_ok( $plugin, 'plasxom::plugin::simpleamazon' );

is( $plugin->{'locale'}, 'jp' );
is( $plugin->{'apikey'}, 'XXXXXXXXXXXXXXXXXXXX' );
is( $plugin->{'secret'}, 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' );
