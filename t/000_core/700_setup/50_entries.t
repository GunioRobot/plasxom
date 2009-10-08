#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 8;

require_hlosxom;

{
    package plugins;
    
    sub new { bless {}, shift }
    
    sub run_plugins {
        our ( $self, $method, $arg ) = @_;
        package main;
        
        is( $plugins::method, 'filter' );
        isa_ok( $plugins::arg, 'hlosxom::entries' );
    }
}

my $datadir = $example->subdir('core/entries/blosxom');

hlosxom->config->merge(
    entries => {
        entries_dir     => $datadir,
        file_extension  => 'txt',
        depth           => 0,
        meta_prefix     => '@',
    },
);

hlosxom->setup_cache;
hlosxom->plugins( plugins->new );
hlosxom->setup_entries;

isa_ok( hlosxom->entries, 'hlosxom::entries' );
isa_ok( hlosxom->entries->db, 'hlosxom::entries::blosxom' );

ok( ! exists hlosxom->entries->db->{'cache'} );

hlosxom->config->merge(
    entries => {
        use_cache => 1,
    },
);

hlosxom->setup_entries;

isa_ok( hlosxom->entries->db->{'cache'}, 'hlosxom::cache' );
