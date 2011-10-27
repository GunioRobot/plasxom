#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 7;

BEGIN { require_plasxom };

our $flag;

{
    package plasxom;

    no warnings 'redefine';

    sub prepare     { package main; ok(1) }
    sub templatize  { package main; ok(1) }
    sub finalize    { package main; ok(1) }

    package plugins;

    sub new { bless {}, shift }

    sub run_plugin_first {
        our ( $self, $method ) = @_;
        package main;

        is( $method, 'skip' );

        return $flag;
    }
}

my $app = plasxom->new;
   $app->plugins( plugins->new );
   $app->run;

$flag++;

$app->run;
