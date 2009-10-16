#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

my @props = qw( year month day flavour tags meta no_matched pagename tag_op );

plan tests => 1 + 1 + scalar(@props) + 3;

my $flavour = hlosxom::flavour->new();

isa_ok( $flavour, 'hlosxom::flavour' );

can_ok( $flavour, @props );

for my $prop ( @props ) {
    $flavour->$prop('foo');
    is( $flavour->$prop, 'foo' );
}

$flavour->path('/foo/bar/');

is( $flavour->path, 'foo/bar' );

$flavour->filename('/filename');

is( $flavour->filename, 'filename' );

$flavour->flavour('html');

is( $flavour->fullpath, 'foo/bar/filename.html' );
