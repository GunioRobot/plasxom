#!perl

use strict;
use warnings;

use File::Temp;

use t::Util qw( require_plasxom $example );
use Test::More tests => 5 + 2 + 1 + 1;

require_plasxom;

my $loader = plasxom::template::source::file->new(
    root_dir => $example->subdir('core/template/flavours'),
);

isa_ok( $loader, 'plasxom::template::source::file' );

ok( $loader->exists( path => 'foo.txt' ) );
ok( ! $loader->exists( path => 'notfound.html' ) );

is_deeply(
    $loader->stat( path => 'foo.txt' ),
    { lastmod => $loader->root_dir->file('foo.txt')->stat->mtime },
);

is_deeply(
    $loader->stat( path => 'notfound.html' ),
    { notfound => 1 },
);

{
    my $temp = File::Temp->newdir;

    $loader = plasxom::template::source::file->new(
        root_dir => $temp->dirname,
    );

    $loader->create( path => 'foo.html', source => q{foo} );

    ok( $loader->exists( path => 'foo.html' ) );
    is(
        $loader->root_dir->file('foo.html')->slurp(),
        q{foo},
    );

    $loader->update( path => 'foo.html', source => q{bar} );

    is(
        $loader->root_dir->file('foo.html')->slurp(),
        q{bar},
    );

    $loader->remove( path => 'foo.html' );

    ok( ! $loader->exists( path => 'foo.html' ) );

}
