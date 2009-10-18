#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 6;

BEGIN { require_hlosxom };

{
    package hlosxom::plugin;
    
    no strict 'refs';
    no warnings 'redefine';
    
    *{'init'} = sub { package main; ok(1) };
}

my $plugin = hlosxom::plugin->new( config => { foo => 'bar' }, state => $example->subdir('core/plugin') );

isa_ok( $plugin, 'hlosxom::plugin' );

is_deeply( $plugin->config, { foo => 'bar' } );
is_deeply( $plugin->state, $example->subdir('core/plugin') );

ok( $plugin->setup );
ok( $plugin->start );
