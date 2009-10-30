#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 2 + 3 + 5 + 5;
use File::Temp;

require_plasxom;

my $loader      = plasxom::template::source::file->new(
    root_dir => $example->subdir('core/template/flavours'),
);
my $renderer    = plasxom::template::renderer::microtemplate->new;

my $tmpl = plasxom::template->new( source => $loader, renderer => $renderer, path => 'bar.txt' );

isa_ok( $tmpl, 'plasxom::template' );
is( $tmpl->path, 'bar.txt' );

# load
is( $tmpl->source, '<?= $_[0] ?>' );
is( $tmpl->lastmod, $loader->root_dir->file('bar.txt')->stat->mtime );
is( $tmpl->loaded, 1 );

# compiled
my $compiled = $tmpl->compiled;
isa_ok( $compiled, 'CODE' );
is( $tmpl->compiled, $compiled );

$tmpl->source('<?= $_[0] ?>');
ok( ! $tmpl->{'compiled'} );

# render
is( $tmpl->render('foo'), 'foo' );

# modified
ok( ! $tmpl->is_modified_source );

# io
{
    my $temp = File::Temp->newdir;

    $loader = plasxom::template::source::file->new( root_dir => $temp->dirname );
    $tmpl   = plasxom::template->new( source => $loader, renderer => $renderer, path => 'foo.txt' );

    $tmpl->source('<?= $_[0] ?>');
    $tmpl->commit;

    ok( $loader->exists( path => 'foo.txt' ) );
    is( $tmpl->lastmod, $loader->root_dir->file('foo.txt')->stat->mtime );

    $tmpl->source('bar');
    $tmpl->reload;

    is( $tmpl->source, '<?= $_[0] ?>' );

    $tmpl->remove;

    ok( ! $loader->exists( path => 'foo.txt' ) );
    ok( $tmpl->is_modified_source );
}