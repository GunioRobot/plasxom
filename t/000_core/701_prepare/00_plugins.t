#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 1;

require_hlosxom;

{
    package Plugins;
    
    sub new { bless {}, shift };
    sub prepare {
        package main;
        ok(1);
    }
}

hlosxom->plugins( Plugins->new );

my $app = hlosxom->new;
   $app->prepare_plugins;
