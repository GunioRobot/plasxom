#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 5;

require_hlosxom;

my $api = hlosxom::api->new();

isa_ok( $api, 'hlosxom::api' );

can_ok( $api, qw( register call ) );

my $sub = sub {
    my ( $instance, @args ) = @_;

    is( $instance, 'foo' );
    is_deeply(
        [ @args ],
        [qw( foo bar )],
    );

};

$api->register(
    'foo',
    'test' => $sub,
);

is_deeply(
    $api->{'API'},
    {
        test => {
            instance => 'foo',
            function => $sub,
        },
    },
);

$api->call('test' => qw( foo bar ));
