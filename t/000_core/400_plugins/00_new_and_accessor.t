#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 7;

require_plasxom;

my $plugins = plasxom::plugins->new(
    search_dirs => $example->subdir('core/plugins/plugins')->absolute->cleanup,
    state_dir   => $example->subdir('core/plugins/state')->absolute->cleanup,
    order       => [],
);

isa_ok(
    $plugins,
    'plasxom::plugins',
);

can_ok(
    $plugins,
    qw( search_dirs state_dir order plugins ),
);

is_deeply(
    $plugins->search_dirs,
    [ $example->subdir('core/plugins/plugins')->absolute->cleanup ],
);

is_deeply(
    $plugins->state_dir,
    $example->subdir('core/plugins/state')->absolute->cleanup,
);

is_deeply(
    $plugins->order,
    [],
);

is_deeply(
    $plugins->plugins,
    [],
);

$plugins->context('plasxom');

is( $plugins->context, 'plasxom' );
