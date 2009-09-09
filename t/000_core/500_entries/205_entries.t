#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 5;

require_hlosxom;

my $datadir = $example->subdir('core/entries/blosxom');

my $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

my $foo = $entries->entry( path => 'foo' );
my $bar = $entries->entry( path => 'foo/bar' );

# filter test
is_deeply(
    [ $entries->entries( path => 'foo/' ) ],
    [ $bar ],
);

# sort test
is_deeply(
    [ $entries->entries( path => 'foo', sort => 'lastmod' ) ],
    [ (sort { $b->lastmod <=> $a->lastmod } ( $foo, $bar )) ],
);

is_deeply(
    [ $entries->entries( sort => sub { $_[0]->lastmod <=> $_[1]->lastmod }) ],
    [ (sort { $a->lastmod <=> $b->lastmod } ( $foo, $bar )) ],
);

# pagiante test

$entries->num_entries(1);

is_deeply(
    [ $entries->entries( page => 1 ) ],
    [ ( sort { $b->created <=> $a->created } ( $foo, $bar ) )[0] ],
);

is_deeply(
    [ $entries->entries( page => 2 ) ],
    [ ( sort { $b->created <=> $a->created } ( $foo, $bar ) )[1] ],
);