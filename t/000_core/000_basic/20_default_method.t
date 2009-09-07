#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 1 + 3 + 2 ;

require_hlosxom;

# default config

isa_ok( hlosxom->config, 'hlosxom::hash' );

# default method 'template';

my $dir = $example->subdir('core/basic/template')->absolute->cleanup;

hlosxom->config->merge(
    flavour => {
        dir => $dir,
    },
);

my $tmpl = hlosxom->template('bar/baz', 'foo', 'html');

is( $tmpl, 'foo' );

$tmpl = hlosxom->template('bar/baz/foo/bar', 'bar', 'html');

is( $tmpl, 'bar' );

$tmpl = hlosxom->template( '', 'baz', 'html' );

is( $tmpl, 'baz' );

# default method 'interpolate';

is(
    hlosxom->interpolate(q{<?= $_[0] ?>-<?= $_[1]->{'foo'} ?>}, { foo => 'bar' }),
    'hlosxom-bar'
);

like( hlosxom->interpolate(q{<?= }), qr{Interpolate error:} );
