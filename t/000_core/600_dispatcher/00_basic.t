#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

my $dispatcher = hlosxom::dispatcher->new(
    regexp => {
        'meta.datesection' => qr{(\d+)},
    },
    rule    => [
        {
            path => '/{year}/{month}/{day}/{meta.datesection}(?:[.]{flavour})?',
        },
    ],
);

my $regexp  = $dispatcher->rules->[0]->{'path'};
my $capture = $dispatcher->rules->[0]->{'capture'};

is(
    "${regexp}",
    '(?-xism:/(?-xism:(\\d{4}))/(?-xism:(\\d{2}))/(?-xism:(\\d{1,2}))/(?-xism:(\\d+))(?:[.](?-xism:([a-zA-Z0-9_\\-]+)))?)',
);

is_deeply(
    $capture,
    [qw( year month day meta.datesection flavour )],
);

