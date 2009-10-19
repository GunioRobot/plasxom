#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 3;

require_plasxom;

plasxom->config->merge(
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

plasxom->setup_plugins;

isa_ok( plasxom->plugins, 'plasxom::plugins' );
is( plasxom->plugins->context, 'plasxom' );
is_deeply(
    plasxom->plugins->plugins,
    [
        {
            instance => plasxom::plugin::foo->new(
                config => { foo => 'bar' },
                state => $example->subdir('core/plugins/states/foo')->absolute->cleanup,
            ),
            enable => 1,
        },
        {
            instance => plasxom::plugin::bar->new(
                config => { bar => 'baz' },
                state => $example->subdir('core/plugins/states/bar')->absolute->cleanup,
            ),
            enable => -1,
        },
        {
            instance => plasxom::plugin::baz->new(
                config => { baz => 'foo' },
                state => $example->subdir('core/plugins/states/baz')->absolute->cleanup,
            ),
            enable => 1,
        }
    ]
);