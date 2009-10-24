#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3;

use Plack::Response;

require_plasxom;
require_plugin('notfound');

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::notfound->new( config => {}, state => $example->subdir('plugin/notfound/state') );

$app->res( Plack::Response->new(200) );
$app->flavour( plasxom::flavour->new( no_matched => 0 ) );

isa_ok( $plugin, 'plasxom::plugin::notfound' );

$plugin->entries( $app, [] );

is( $app->res->status, 404 );

$app->res->status(200);
$app->flavour->no_matched(1);

$plugin->entries( $app, [qw( foo bar )] );

is( $app->res->status, 404 );
