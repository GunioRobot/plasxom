#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 3;
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

my $index = {
    'foo' => hlosxom::entry->new(
        db => $entries->db,
        path => 'foo',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo.txt') )->mtime,
    ),
    'foo/bar' => hlosxom::entry->new(
        db => $entries->db,
        path => 'foo/bar',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo/bar.txt') )->mtime,
    ),

};

is_deeply(
    $entries->index,
    $index,
);

is( $entries->indexed, 1 );

is_deeply(
    $entries->index,
    $index,
);
