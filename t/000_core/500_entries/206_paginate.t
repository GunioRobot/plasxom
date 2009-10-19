#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 3;

require_plasxom;

my $entries = plasxom::entries->new(
    schema          => 'plasxom::entries::blosxom',
    entries_dir     => $example->subdir('core/entries/filter'),
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
    meta_mapping    => {
        created => 'date',
    }
);

my $AAA = $entries->entry( path => 'AAA' );
my $BBB = $entries->entry( path => 'foo/BBB' );
my $CCC = $entries->entry( path => 'foo/CCC' );

$entries->num_entries( 2 );

is_deeply(
    [ $entries->pagiante( page => 1 ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) )[0,1] ],
);

is_deeply(
    [ $entries->pagiante( page => 2 ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) )[2] ],
);

is_deeply(
    [ $entries->pagiante( page => 3 ) ],
    [],
);