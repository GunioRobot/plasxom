#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More;

require_plasxom;
require_plugin('simpleamazon');

my $apikey = plasxom::util::env_value('apaapi_apikey');
if ( ! $apikey ) {
    plan skip_all => 'PLASXOM_APAAPI_APIKEY is not set.';
}

my $secret = plasxom::util::env_value('apaapi_secretkey');
if ( ! $secret ) {
    plan skip_all => 'PLASXOM_APAAPI_SECRETKEY is not set.';
}

plan tests => 3;

plasxom->setup_cache;
my $plugin = plasxom::plugin::simpleamazon->new( config => { locale => 'jp', apikey => $apikey, secret => $secret }, state => $example->subdir('plugin/simpleamazon/state') );
$plugin->setup('plasxom');

# load cache test
$plugin->{'cache'}->set('plasxom-simpleamazon-asin:XXXXXXXXXX' => { lastmod => time, cache => { foo => 'bar' } });
is_deeply( $plugin->asin('XXXXXXXXXX'), { foo => 'bar' } );

# request test
$plugin->{'cache'}->set('plasxom-simpleamazon-asin:4062836637' => { lastmod => 0, cache => {} });
my $ret = $plugin->asin('4062836637');

is( $ret->{'ASIN'}, '4062836637' );

# cache set test
is_deeply(
    $plugin->{'cache'}->get('plasxom-simpleamazon-asin:4062836637'),
    {
        lastmod => $plugin->{'cache'}->get('plasxom-simpleamazon-last-request'),
        cache   => $ret,
    },
);
