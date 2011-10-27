#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $basedir );
use Test::More tests => 9;

BEGIN { require_plasxom };

{
    package TestEntries;

    use base qw( plasxom::entries::base );

    sub init {
        our ( $self, %args ) = @_;

        package main;

        is_deeply(
            \%TestEntries::args,
            {
                foo => 'bar',
                bar => [qw( foo bar )],
            },
        );
    }

}

isa_ok('TestEntries', 'plasxom::entries::base');

my $entries = TestEntries->new( foo => 'bar', bar => [qw( foo bar )] );

isa_ok( $entries, 'TestEntries' );
is_deeply( $entries->config, {} );

can_ok(
    $entries,
    qw( create update select remove exists index stat ),
);

our %entry = (
    foo => 'bar',
    bar => 'baz',
    baz => 'foo',
);
our $flag = 0;

{
    package TestEntries;

    for my $method (qw( create update )) {
        no strict 'refs';
        *{$method} = sub {
            our ( $self, %args ) = @_;

            package main;

            my $entry = { %main::entry };
               $entry->{'path'} = "/path/to/${method}.txt";

            is_deeply(
                \%TestEntries::args,
                $entry,
            );
        };
    }

    sub exists {
        our ( $self, %args ) = @_;

        package main;
        like( $TestEntries::args{'path'}, qr{^/path/to/(create|update).txt} );

        return $main::flag;
    }

}

$flag = 1;

$entries->create_or_update(
    path => '/path/to/update.txt',
    %entry,
);

$flag = 0;

$entries->create_or_update(
    path => '/path/to/create.txt',
    %entry,
);