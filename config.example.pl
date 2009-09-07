#!perl

use strict;
use warnings;

my $basedir = '/path/to/script/dir';

return {

    plugin => {
        plugin_dir          => [ "${basedir}/plugins" ],
        plugin_state_dir    => "${basedir}/states",
    },

    plugins => {
        # { plugin => 'PluginName', config => \%config },
    }

};