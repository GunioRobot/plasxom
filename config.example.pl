#!perl

use strict;
use warnings;

my $basedir = '/path/to/script/dir';

return {

    flavour     => {
        dir     => "${basedir}/flavours",
        default => 'html',
    },

    # cache       => {
    #     class   => 'Ccahe::FileCache',
    #     args    => {
    #         cache_root => "${basedir}/cache",
    #     },
    #     deref   => 0,
    # },

    plugin      => {
        plugin_dir          => [ "${basedir}/plugins" ],
        plugin_state_dir    => "${basedir}/states",
    },

    plugins     => {
        # { plugin => 'PluginName', config => \%config },
    }

    vars        => {
    # foo => 'bar',
    },

    dispatch    => {
        regexp => {
            # foo => qr{regexp},
        },
        rule    => [
            # {
            #     path        => '/{year}/{month}/{day}',
            #     flavour     => {
            #         'hlosxom::flavour property' => 'static value',
            #     },
            #     condition   => {
            #         method      => 'GET' || 'POST' || '...etc',
            #         function    => sub { return 1 || 0 };
            #     },
            #     after_hook  => sub { my ( $res, $flavour ) = @_; }
            # },
        ],
    },

};
