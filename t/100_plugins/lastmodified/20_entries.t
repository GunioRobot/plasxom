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

my $app = plasxom->new;
   $app->config->merge(
        template => {
            renderer    => {},
            source      => { root_dir => $example->subdir('plugin/lastmodified/template') },
        },
   );
   $app->setup_templates;
   $app->flavour( 'plasxom::flavour'->new( path_info => '/foo/bar', flavour => 'html' ) );

my @mtimes = (
    $dir->subdir('foo')->file('foo.txt')->stat->mtime,
    $dir->file('foo.txt')->stat->mtime,
    $app->templates->dispatch('/foo/bar', 'content_type', 'html')->lastmod,
    $app->templates->dispatch('/foo/bar', 'template', 'html')->lastmod,
    $app->templates->dispatch('/foo/bar', 'AAA', 'html')->lastmod,
    $time,
);

my $mtime = ( sort { $b <=> $a } @mtimes )[0];

$plugin->entries( $app, [ entry->new, entry->new ] );
is(
    $plugin->{'mtime'},
    $mtime,
)