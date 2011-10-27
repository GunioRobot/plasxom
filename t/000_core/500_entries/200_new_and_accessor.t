#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 10;

require_plasxom;

{
    package TestEntries;

    sub new {
        my ( $class, %args ) = @_;
        return bless { %args }, $class;
    }
}

my $entries = plasxom::entries->new(
    schema      => 'TestEntries',
    foo         => 'bar',
);

isa_ok( $entries, 'plasxom::entries' );
isa_ok( $entries->db, 'TestEntries' );

is_deeply(
    $entries->db,
    TestEntries->new( foo => 'bar' ),
);

ok( ! $entries->indexed_all );

$entries->indexed_all(1);

ok( $entries->indexed_all );

is( $entries->num_entries, 5 );

$entries = plasxom::entries->new(
    schema => 'TestEntries',
    foo    => 'bar',
    num_entries => 10,
);

is( $entries->num_entries, 10 );

$entries->num_entries(20);

is( $entries->num_entries, 20 );

isa_ok( $entries->filtered, 'ARRAY' );
$entries->filtered( [ qw( foo bar baz ) ]);

is_deeply(
    $entries->filtered,
    [qw( foo bar baz )],
);