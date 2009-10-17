#!perl

use strict;
use warnings;

my $basedir = '/path/to/script/dir';

return {

    server      => {
        interface   => 'CGI',
        middleware  => [
            [ 'Plack::Middleware::StackTrace' ],
        ],
    },

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

    entries     => {
        entries_dir     => "${basedir}/entries",
        file_extension  => 'txt',

        meta_prefix     => 'meta-',
        # meta_mapping    => { $hlosxom::entry property => 'meta key' },

        use_cache       => 1,
        use_index       => 1,
        index_file      => "${statedir}/entries.index",

        auto_update     => 0,
        readonly        => 1,

        num_entries => 5,
    },

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
