#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 3 + 2 + 1;

require_plasxom;
require_plugin('chatlog');

my $plasxom = plasxom->new;
my $plugin  = plasxom::plugin::chatlog->new(
    config => {
        meta_key    => 'type',
        meta_value  => 'log',
    },
    state   => $example->subdir('plugin/chatlog/state'),
);

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('plugin/chatlog/entries'),
    file_extension  => 'txt',
    meta_prefix     => '@',
);

$plasxom->entries( $entries );
$plasxom->config->merge(
    template    => {
        renderer    => {},
        source      => { root_dir => $example->subdir('plugin/chatlog/template') },
    },
);
$plasxom->setup_templates;
$plasxom->flavour( plasxom::flavour->new( flavour => 'html' ) );

# handle test
ok( $plugin->handle( $entries->entry( path => 'foo/foo' ), 'body' ) );
ok( ! $plugin->handle( $entries->entry( path => 'foo/foo' ), 'summary' ) );
ok( ! $plugin->handle( $entries->entry( path => 'foo/bar' ), 'body' ) );

# register_format test
$plugin->update( $plasxom, $entries );
for my $entry ( @{ $entries->index } ) {
    is_deeply(
        $entry->{'formatter'},
        [
            { formatter => $plugin, method => 'format', handle => 'handle' },
        ],
    );
}

# format test
my $data = <<'__LINE__';
foo:1:1:odd:AAA
bar:2:2:even:BBB
baz:3:3:odd:CCC
::4:even:---
foo:1:5:odd:AAA
bar:2:6:even:BBB
baz:3:7:odd:CCC
__LINE__

is(
    $entries->entry( path => 'foo/foo' )->body,
    $data,
);