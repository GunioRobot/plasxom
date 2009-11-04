#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;
use Test::Requires qw( IO::String Plack::Request );

require_plasxom;
require_plugin('lastmodified');

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::lastmodified->new( config => {}, state => $example->subdir('plugin/lastmodified/state') );

$app->req( Plack::Request->new({ 'psgi.input' => IO::String->new,   QUERY_STRING => 'foo=bar', REQUEST_METHOD => 'GET' }) );

ok( ! $plugin->start( $app ) );

$app->req( Plack::Request->new({ 'psgi.input' => IO::String->new, REQUEST_METHOD => 'POST' }) );

ok( ! $plugin->start( $app ) );

$app->req( Plack::Request->new({ 'psgi.input' => IO::String->new, REQUEST_METHOD => 'GET' }) );

ok( $plugin->start( $app ) );
