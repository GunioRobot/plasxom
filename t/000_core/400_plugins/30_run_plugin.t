#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 4;

require_plasxom;

my $plugins = plasxom::plugins->new(
    search_dirs => $example->subdir('core/plugins/plugins')->absolute->cleanup,
    state_dir   => $example->subdir('core/plugins/states')->absolute->cleanup,
    order       => [
        { plugin => 'foo', config => { foo => 'bar' } },
        { plugin => 'bar', config => { bar => 'baz' } },
        { plugin => 'baz', config => { baz => 'foo' } },
    ],
);

$plugins->setup;

$plugins->context('plasxom');

is_deeply(
    [ $plugins->run_plugins( foo => qw( bar baz ) ) ],
    [
        [ 'plasxom', qw( bar baz ) ],
        [qw( bar baz )],
    ],
);

is_deeply(
    $plugins->run_plugin_first( foo => qw( bar baz ) ),
    [ 'plasxom', qw( bar baz ) ],
);

$plugins->prepare;

is_deeply(
    [ $plugins->run_plugins( foo => qw( bar baz ) ) ],
    [
        [ 'plasxom', qw( bar baz ) ],
    ],
);

is_deeply(
    $plugins->run_plugin_first( foo => qw( bar baz ) ),
    [ 'plasxom', qw( bar baz ) ],
);
