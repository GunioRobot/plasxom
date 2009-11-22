#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 3;
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

my $index = [
    plasxom::entry->new(
        db => $entries->db,
        path => 'foo',
        title   => 'title',
        pagename    => 'foopage',
        tags        => [qw( foo bar baz )],
        meta        => { foo => 'bar', bar => 'baz' },
        created => 1230735600,
        lastmod => stat( $datadir->file('foo.txt') )->mtime,
    ),
];

is_deeply(
    $entries->index,
    $index,
);

is( $entries->indexed, 1 );

is_deeply(
    $entries->index,
    $index,
);
