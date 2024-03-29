#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 2;
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

$entries->reindex_all;

is( $entries->indexed_all, 1 );

my $index = [
    plasxom::entry->new(
        db => $entries->db,
        path => 'foo',
        title => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo.txt') )->mtime,
    ),
    plasxom::entry->new(
        db => $entries->db,
        path => 'foo/bar',
        title => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo/bar.txt') )->mtime,
    ),
];

is_deeply(
    $entries->all,
    $index,
);
