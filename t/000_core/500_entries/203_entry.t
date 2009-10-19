#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 4;
use File::stat;

require_plasxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

is_deeply(
    $entries->entry( path => 'foo' ),
    plasxom::entry->new(
        path        => 'foo',
        db          => $entries->db,
        title       => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created     => 1230735600,
        lastmod     => stat( $datadir->file('foo.txt') )->mtime,
    ),
);

my $new = $entries->entry( path => 'new' );

is( $new->fullpath, 'new' );
is( $new->{'db'}, $entries->db );

like( $new->created, qr{^\d+$} );
