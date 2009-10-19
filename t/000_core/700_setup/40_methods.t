#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 2;

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

my $template    = plasxom->plugins->run_plugin_first('template');
my $interpolate = plasxom->plugins->run_plugin_first('interpolate');

plasxom->setup_methods;

is( plasxom->methods->{'template'}, $template );
is( plasxom->methods->{'interpolate'}, $interpolate );
