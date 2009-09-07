#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 1;

require_hlosxom;

my $plugins = hlosxom::plugins->new(
    search_dirs => $example->subdir('core/plugins/plugins')->absolute->cleanup,
    state_dir   => $example->subdir('core/plugins/states')->absolute->cleanup,
    order       => [
        { plugin => 'foo', config => { foo => 'bar' } },
        { plugin => 'bar', config => { bar => 'baz' } },
        { plugin => 'baz', config => { baz => 'foo' } },
    ],
);

$plugins->setup;
$plugins->prepare;

is_deeply(
    $plugins->plugins,
    [
        {
            instance => hlosxom::plugin::foo->new(
                config => { foo => 'bar' },
                state => $example->subdir('core/plugins/states/foo')->absolute->cleanup,
            ),
            enable => 1,
            on_off  => 1,
        },
        {
            instance => hlosxom::plugin::bar->new(
                config => { bar => 'baz' },
                state => $example->subdir('core/plugins/states/bar')->absolute->cleanup,
            ),
            enable => -1,
            on_off => -1,
        },
        {
            instance => hlosxom::plugin::baz->new(
                config => { baz => 'foo' },
                state => $example->subdir('core/plugins/states/baz')->absolute->cleanup,
            ),
            enable => 1,
            on_off => -1,
        }
    ]
)