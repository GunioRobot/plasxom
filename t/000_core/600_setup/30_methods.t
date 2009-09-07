#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 2;

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

my $template    = hlosxom->plugins->run_plugin_first('template');
my $interpolate = hlosxom->plugins->run_plugin_first('interpolate');

hlosxom->setup_methods;

is( hlosxom->methods->{'template'}, $template );
is( hlosxom->methods->{'interpolate'}, $interpolate );
