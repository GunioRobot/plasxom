#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

{
    package Plugins;
    
    sub new { bless {}, shift };
    sub prepare {
        package main;
        ok(1);
    }
}

plasxom->plugins( Plugins->new );

my $app = plasxom->new;
   $app->prepare_plugins;
