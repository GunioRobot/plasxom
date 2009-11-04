#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 5;

require_plasxom;
require_plugin('lastmodified');

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::lastmodified->new( config => {}, state => $example->subdir('plugin/lastmodified/state') );

ok( ! $plugin->output( $app, \q{}, \q{} ) );

$plugin->config->{'use_cache'} = 1;

$app->setup_cache;
$app->flavour( plasxom::flavour->new( path_info => '/foo/bar.html' ) );

ok( $plugin->output( $app, \q{text/plain}, \q{body} ) );

my $cache = $app->cache->get('plasxom-output-cache:/foo/bar.html');

is( $cache->{'content_type'},   'text/plain'    );
is( $cache->{'body'},           'body'          );
like( $cache->{'mtime'},    qr{^\d+$} );
