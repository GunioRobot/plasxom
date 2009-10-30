#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 3;

require_plasxom;

my $renderer = plasxom::template::renderer::microtemplate->new;

isa_ok(
    $renderer,
    'plasxom::template::renderer::microtemplate',
);

my $render = $renderer->compile('<?= $_[0] ?>');

isa_ok( $render, 'CODE' );
is( $render->('foo'), 'foo' );
