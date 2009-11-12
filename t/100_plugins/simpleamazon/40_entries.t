#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 2 + 2 + 2;

BEGIN {
    require_plasxom;
    require_plugin('simpleamazon');
}

{
    package plasxom::plugin::simpleamazon;
    
    no strict 'refs';
    no warnings 'redefine';
    
    *{'asin'} = sub {
        my ( $self, $asin ) = @_;
        return { ASIN => $asin };
    };
}

my $plasxom = plasxom->new;
my $plugin  = plasxom::plugin::simpleamazon->new(
    config => {
        locale => 'jp', apikey => 'X', secret => 'X',
    },
    state => $example->subdir('plugin/simpleamazon/state'),
);

my $entries = 'plasxom::entries'->new(
    schema => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('plugin/simpleamazon/entries'),
    file_extension  => 'txt',
    meta_prefix     => '@',
);
$plasxom->entries( $entries );

$plasxom->config->merge(
    template    => {
        renderer    => {},
        source      => { root_dir => $example->subdir('plugin/simpleamazon/template') },
    },
);
$plasxom->setup_templates;
$plasxom->flavour( 'plasxom::flavour'->new( path_info => '/', flavour => 'html' ) );
my $entry = $plasxom->entries->entry( path => 'foo' );

$plugin->config->{'replace_asin'}   = 0;

$plugin->entries( $plasxom, [ $entry ] );

is(
    $entry->body_source,
    'ASIN:4062836637'
);

is(
    $entry->summary_source,
    'ASIN:4062836637:inline:',
);

$plugin->config->{'replace_asin'}   = 1;
$plugin->config->{'use_meta'}       = 1;
$plugin->config->{'meta_key'}       = 'replace';

$plugin->entries( $plasxom, [ $entry ] );

is(
    $entry->body_source,
    '4062836637',
);

is(
    $entry->summary_source,
    'foo',
);

$plugin->config->{'use_meta'} = 0;
$entry->reload;

$plugin->entries( $plasxom, [ $entry ] );

is(
    $entry->body_source,
    '4062836637',
);

is(
    $entry->summary_source,
    'foo',
);
