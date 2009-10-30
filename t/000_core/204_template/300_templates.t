#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 6;

require_plasxom;

my $loader = plasxom::template::source::file->new(
    root_dir => $example->subdir('core/template/templates'),
);

my $renderer = plasxom::template::renderer::microtemplate->new;

my $tmpls = plasxom::templates->new(
    source      => $loader,
    renderer    => $renderer,
);

isa_ok( $tmpls, 'plasxom::templates' );

my $tmpl = $tmpls->load('foo.txt');

is_deeply(
    $tmpl,
    plasxom::template->new( path => 'foo.txt', source => $loader, renderer => $renderer ),
);

is(
    $tmpls->load('foo.txt'),
    $tmpl,
);

$tmpl = $tmpls->dispatch( '/foo/bar/baz', 'baz', 'txt' );
is( $tmpl->path, 'foo/baz.txt' );

$tmpl = $tmpls->dispatch('/foo/bar/baz/', 'foo', 'txt');
is( $tmpl->path, 'foo.txt' );

$tmpl = $tmpls->dispatch('AAA/BBB/CCC', 'bar', 'txt');
is( $tmpl->path, 'bar.txt' );
