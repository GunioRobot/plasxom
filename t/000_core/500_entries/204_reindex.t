#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 2;
use File::stat;

require_hlosxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

$entries->reindex;

is( $entries->indexed, 1 );

my $index = {
    'foo' => hlosxom::entry->new(
        db => $entries->db,
        path => 'foo',
        title => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        datesection => 1,
        created => 1230735600,
        lastmod => stat( $datadir->file('foo.txt') )->mtime,
    ),
    'foo/bar' => hlosxom::entry->new(
        db => $entries->db,
        path => 'foo/bar',
        title => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        datesection => 2,
        created => 1230735600,
        lastmod => stat( $datadir->file('foo/bar.txt') )->mtime,
    ),

};

is_deeply(
    $entries->index,
    $index,
);
