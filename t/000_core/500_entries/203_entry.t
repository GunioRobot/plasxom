#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 4;
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

is_deeply(
    $entries->entry( path => 'foo' ),
    hlosxom::entry->new(
        path    => 'foo',
        db      => $entries->db,
        created => 1230735600,
        lastmod => stat( $datadir->file('foo.txt') )->mtime,
    ),
);

my $new = $entries->entry( path => 'new' );

is( $new->fullpath, 'new' );
is( $new->{'db'}, $entries->db );

like( $new->created, qr{^\d+$} );
