#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 1 + 1 +  1 + 7 + 2 + 2 + 2 + 3;

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

$AAA->stash->{'foo'} = 'bar';
$BBB->stash->{'foo'} = 'barbaz';

# filter path
is_deeply(
    [ $entries->filter( path => 'foo/' ) ],
    [ ( sort { $b->created <=> $a->created } ( $BBB, $CCC ) ) ],
);

# filter filename
is_deeply(
    [ $entries->filter( filename => 'BBB' ) ],
    [ $BBB ],
);

# filter pagename
is_deeply(
    [ $entries->filter( pagename => 'AAA' ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $CCC ) ) ],
);

# filter date
is_deeply(
    [ $entries->filter( year => 2009 ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) ) ],
);

is_deeply(
    [ $entries->filter( month => 1 ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( day => 2 ) ],
    [ ( sort { $b->created <=> $a->created } ( $BBB, $CCC ) ) ],
);

is_deeply(
    [ $entries->filter( day => 1 ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( hour => 10 ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( minute => 30 ) ],
    [ $BBB ],
);

is_deeply(
    [ $entries->filter( second => 40 ) ],
    [ $BBB ],
);

# filter meta
is_deeply(
    [ $entries->filter( meta => { link => 'http://example.com/AAA.html' } ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( meta => { link => qr{^http:} } ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $CCC ) ) ],
);

# filter stash
is_deeply(
    [ $entries->filter( stash => { foo => 'bar' } ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( stash => { foo => qr{baz$} } ) ],
    [ $BBB ],
);

# filter tags
is_deeply(
    [ $entries->filter( tag => { words => [qw( bar baz )] } ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $CCC ) ) ],
);

is_deeply(
    [ $entries->filter( tag => { op => 'OR', words => [qw( foo bar )] } ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) ) ],
);

# filter text property

is_deeply(
    [ $entries->filter( title => { words => [qw( title AAA )] } ) ],
    [ $AAA ],
);

is_deeply(
    [ $entries->filter( summary => { words => [qw( bar baz )], op => 'OR' } ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) ) ],
);

is_deeply(
    [ $entries->filter( body => { words => [qw( FOOBAR )],  filter => sub { return 'FOOBAR' } } , ) ],
    [ ( sort { $b->created <=> $a->created } ( $AAA, $BBB, $CCC ) ) ],
);
