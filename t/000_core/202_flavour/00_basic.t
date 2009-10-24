#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More;

require_plasxom;

my @props = qw( year month day flavour tags meta no_matched pagename tag_op page flavour path_info );

plan tests => 2 + scalar(@props) + 1 + 2 + 2;

my $flavour = plasxom::flavour->new();

isa_ok( $flavour, 'plasxom::flavour' );
can_ok( $flavour, @props );

for my $prop ( @props ) {
    $flavour->$prop('foo');
    is( $flavour->$prop, 'foo' );
}

$flavour->$_( undef ) for @props;

is( $flavour->fullpath, '' );

$flavour->path('/foo/bar/');
$flavour->flavour('html');

is( $flavour->path, 'foo/bar' );
is( $flavour->fullpath, 'foo/bar' );

$flavour->filename('/filename');

is( $flavour->filename, 'filename' );
is( $flavour->fullpath, 'foo/bar/filename.html' );
