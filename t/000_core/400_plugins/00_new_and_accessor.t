#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 7;

require_hlosxom;

my $plugins = hlosxom::plugins->new(
    search_dirs => $example->subdir('core/plugins/plugins')->absolute->cleanup,
    state_dir   => $example->subdir('core/plugins/state')->absolute->cleanup,
    order       => [],
);

isa_ok(
    $plugins,
    'hlosxom::plugins',
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

$plugins->context('hlosxom');

is( $plugins->context, 'hlosxom' );
