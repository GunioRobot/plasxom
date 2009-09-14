#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 2 + 7 + 2;
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

my $foo = $entries->entry( path => 'foo' );
my $bar = $entries->entry( path => 'foo/bar' );

# filter category

is_deeply(
    [ $entries->archives( path => 'foo' ) ],
    [ $foo, $bar ],
);

is_deeply(
    [ $entries->archives( path => 'foo/' ) ],
    [ $bar ],
);

# filter datetime

is_deeply(
    [ $entries->archives( year => 2009 ) ],
    [ $foo, $bar ],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 02 ) ],
    [],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 01, day => 01 ) ],
    [ $foo, $bar ],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 01, day => 01, datesection => 2 ) ],
    [ $bar ],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 01, day => 01, hour => 00, ) ],
    [ $foo, $bar ],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 01, day => 01, hour => 00, minute => 20 ) ],
    [],
);

is_deeply(
    [ $entries->archives( year => 2009, month => 01, day => 01, hour => 00, minute => 00, second => 00 ) ],
    [ $foo, $bar ],
);

# sort
is_deeply(
    [ $entries->archives( sort => sub { $_[1]->lastmod <=> $_[0]->lastmod } ) ],
    [ ( sort { $b->lastmod <=> $a->lastmod } ( $foo, $bar ) ) ],
);

is_deeply(
    [ $entries->archives( sort => 'lastmod' ) ],
    [ ( sort { $b->lastmod <=> $a->lastmod } ( $foo, $bar ) ) ],
);