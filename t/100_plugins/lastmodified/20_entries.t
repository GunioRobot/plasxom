#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 1;

BEGIN {
    require_plasxom;
    require_plugin('lastmodified');
}

our $time = time;

{
    package entry;
    sub new { bless {}, shift }
    sub lastmod { return $main::time }
}

my $dir = $example->subdir('plugin/lastmodified/check/');

my $plugin = plasxom::plugin::lastmodified->new(
    config => {
        check_dirs  => [
            $dir->subdir('foo')->stringify,
            { path => $dir->subdir('bar')->stringify, ignore => qr{.*} },
        ],
        check_files => [
            $dir->file('foo.txt')->stringify,
        ],
        check_flavours => [
            'AAA',
        ],
    },
    state  => $example->subdir('plugin/lastmodified/state'),
);

local $ENV{'PLASXOM_CONFIG'} = $example->file('plugin/lastmodified/config.pl')->absolute->cleanup->stringify;

plasxom->setup_config;
plasxom->config->merge(
    template => {
        renderer    => {},
        source      => { root_dir => $example->subdir('plugin/lastmodified/template') },
    },
    plugin  => {
        plugin_dir          => $example->subdir('plugin/lastmodified/plugins'),
        plugin_state_dir    => $example->subdir('plugin/lastmodified/state'),
    },
    plugins => [
        { plugin => 'foo' },
    ],
);
plasxom->setup_plugins;
plasxom->setup_templates;

my $app = plasxom->new;
   $app->flavour( 'plasxom::flavour'->new( path_info => '/foo/bar', flavour => 'html' ) );

my @mtimes = (
    $dir->subdir('foo')->file('foo.txt')->stat->mtime,
    $dir->file('foo.txt')->stat->mtime,
    $app->templates->dispatch('/foo/bar', 'content_type', 'html')->lastmod,
    $app->templates->dispatch('/foo/bar', 'template', 'html')->lastmod,
    $app->templates->dispatch('/foo/bar', 'AAA', 'html')->lastmod,
    $example->subdir('plugin/lastmodified/plugins')->file('foo')->stat->mtime,
    $example->file('plugin/lastmodified/config.pl')->stat->mtime,
    $time,
);

my $mtime = ( sort { $b <=> $a } @mtimes )[0];

$plugin->entries( $app, [ entry->new, entry->new ] );
is(
    $plugin->{'mtime'},
    $mtime,
)