#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 8;

require_plasxom;

{
    package plugins;

    sub new { bless {}, shift }

    sub run_plugins {
        our ( $self, $method, $arg ) = @_;
        package main;

        is( $plugins::method, 'filter' );
        isa_ok( $plugins::arg, 'plasxom::entries' );
    }
}

my $datadir = $example->subdir('core/entries/blosxom');

plasxom->config->merge(
    entries => {
        entries_dir     => $datadir,
        file_extension  => 'txt',
        depth           => 0,
        meta_prefix     => '@',
    },
);

plasxom->setup_cache;
plasxom->plugins( plugins->new );
plasxom->setup_entries;

isa_ok( plasxom->entries, 'plasxom::entries' );
isa_ok( plasxom->entries->db, 'plasxom::entries::blosxom' );

ok( ! exists plasxom->entries->db->{'cache'} );

plasxom->config->merge(
    entries => {
        use_cache => 1,
    },
);

plasxom->setup_entries;

isa_ok( plasxom->entries->db->{'cache'}, 'plasxom::cache' );
