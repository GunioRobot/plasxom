#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 3 + 1 + 3 + 2 ;

require_plasxom;

# default config

isa_ok( plasxom->config, 'plasxom::hash' );

# default vars

isa_ok( plasxom->vars, 'plasxom::hash' );

# default api

isa_ok( plasxom->api, 'plasxom::api' );

# default entries schema class;

is( plasxom->entries_schema_class, 'plasxom::entries::blosxom' );

# default method 'template';

my $dir = $example->subdir('core/basic/template')->absolute->cleanup;

plasxom->config->merge(
    flavour => {
        dir => $dir,
    },
);

my $tmpl = plasxom->template('bar/baz', 'foo', 'html');

is( $tmpl, 'foo' );

$tmpl = plasxom->template('bar/baz/foo/bar/', 'bar', 'html');

is( $tmpl, 'bar' );

$tmpl = plasxom->template( '', 'baz', 'html' );

is( $tmpl, 'baz' );

# default method 'interpolate';

is(
    plasxom->interpolate(q{<?= $_[0] ?>-<?= $_[1]->{'foo'} ?>}, { foo => 'bar' }),
    'plasxom-bar'
);

like( plasxom->interpolate(q{<?= }), qr{Interpolate error:} );
