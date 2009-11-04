#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 2 + 2 + 3 + 3 + 3;

use Plack::Request;
use Plack::Response;

require_plasxom;
require_plugin('lastmodified');

my $app     = plasxom->new;
my $plugin  = plasxom::plugin::lastmodified->new( config => {}, state => $example->subdir('plugin/lastmodified/state') );

my $lastmod = time;

# modified
$app->req( Plack::Request->new({ REQUEST_METHOD => 'GET' }) );
$app->res( Plack::Response->new(200) );

$plugin->{'mtime'} = $lastmod;

ok( ! $plugin->skip( $app ) );
is( $app->res->headers->last_modified, $lastmod );

# not modified
$app->req->headers->if_modified_since(time);

ok( $plugin->skip($app) );
is( $app->res->status, '304' );

# use_cache => 1, no cache
$app->setup_cache;
$plugin->config->{'use_cache'} = 1;
$app->req( Plack::Request->new({ REQUEST_METHOD => 'GET', PATH_INFO => '/foo/bar.html' }) );
$app->flavour( plasxom::flavour->new( path_info => '/foo/bar.html' ) );

ok( ! $plugin->skip( $app ) );
ok( ! $app->res->content_type );
ok( ! $app->res->body );

# use_cache => 1, find cache, modified
my $cache = {
    mtime           => $lastmod - 10,
    body            => 'body',
    content_type    => 'text/plain',
};
$app->cache->set('plasxom-output-cache:/foo/bar.html' => $cache );

ok( ! $plugin->skip( $app ) );
ok( ! $app->res->content_type );
ok( ! $app->res->body );

# use_cache => 1, find cache, not modified
$cache->{'mtime'} = time;
$app->cache->set('plasxom-output-cache:/foo/bar.html' => $cache );

ok( $plugin->skip( $app ) );
is( $app->res->content_type, 'text/plain' );
is( $app->res->body, 'body' );
