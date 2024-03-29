#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 4;

require_plasxom;

my $renderer = plasxom::template::renderer::microtemplate->new;

isa_ok(
    $renderer,
    'plasxom::template::renderer::microtemplate',
);

my $render = $renderer->compile('<?= $_[0] ?>');

isa_ok( $render, 'CODE' );
is( $render->('<foo>'), '&lt;foo&gt;' );

$render = $renderer->compile(q{<?= raw '<foo>' ?>});

is( $render->(), '<foo>' );