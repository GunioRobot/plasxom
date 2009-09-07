#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 3;

require_hlosxom;

hlosxom->config->merge_config(
    plugin  => {
        plugin_dir          => $example->subdir('core/plugins/plugins'),
        plugin_state_dir    => $example->subdir('core/plugins/states'),
    },
    plugins => [
        { plugin => 'foo', config => { foo => 'bar' } },
        { plugin => 'bar', config => { bar => 'baz' } },
        { plugin => 'baz', config => { baz => 'foo' } },
    ],
);

hlosxom->setup_plugins;

isa_ok( hlosxom->plugins, 'hlosxom::plugins' );
is( hlosxom->plugins->context, 'hlosxom' );
is_deeply(
    hlosxom->plugins->plugins,
    [
        {
            instance => hlosxom::plugin::foo->new(
                config => { foo => 'bar' },
                state => $example->subdir('core/plugins/states/foo')->absolute->cleanup,
            ),
            enable => 1,
        },
        {
            instance => hlosxom::plugin::bar->new(
                config => { bar => 'baz' },
                state => $example->subdir('core/plugins/states/bar')->absolute->cleanup,
            ),
            enable => -1,
        },
        {
            instance => hlosxom::plugin::baz->new(
                config => { baz => 'foo' },
                state => $example->subdir('core/plugins/states/baz')->absolute->cleanup,
            ),
            enable => 1,
        }
    ]
);