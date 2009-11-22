#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 5;
use File::stat;

require_plasxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    hide_from_index => [ qr{bar$} ],
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

is_deeply(
    $entries->entry( path => 'foo/bar' ),
    plasxom::entry->new(
        db => $entries->db,
        path => 'foo/bar',
        title   => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo/bar.txt') )->mtime,
    ),
);

my $new = $entries->entry( path => 'new' );

is( $new->fullpath, 'new' );
is( $new->{'db'}, $entries->db );

like( $new->created, qr{^\d+$} );
