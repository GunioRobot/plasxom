#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => ( 1 + 2 ) + 2 + 2 + 1 + 3;

require_plasxom;

{
    package TestCacheClassA;

    sub new {
        our ( $class, $args ) = @_;
        our $self = bless {  }, $class;
        package main;

        is_deeply(
            $TestCacheClassA::args,
            {
                foo => 'bar',
            },
        );
        return $TestCacheClassA::self;
    }

    sub set {
        our ( $self, $key, $value ) = @_;
        $self->{$key} = $value;
        package main;
        is( $TestCacheClassA::key, 'foo' );
        is( $TestCacheClassA::value, 'bar' );
    }

    sub get {
        our ( $self, $key ) = @_;
        package main;
        is( $TestCacheClassA::key, 'foo' );
        package TestCacheClassA;
        return $self->{$key};
    }

    1;
    package TestCacheClassB;

    sub new {
        our ( $class, %args ) = @_;
        package main;

        is_deeply(
            \%TestCacheClassB::args,
            {
                foo => 'bar',
            },
        );
        package TestCacheClassB;
        return bless {}, $class;
    }

    1;
}

local $INC{'TestCacheClassA.pm'} = $0;
local $INC{'TestCacheClassB.pm'} = $0;

# new
my $cache = plasxom::cache->new(
    class   => 'TestCacheClassA',
    args    => {
        foo => 'bar',
    },
);

isa_ok( $cache, 'plasxom::cache' );
isa_ok( $cache->{'cache'}, 'TestCacheClassA' );

# set
$cache->set( foo => 'bar' );

# get
is( $cache->get('foo'), 'bar' );

# new 2

$cache = plasxom::cache->new(
    class => 'TestCacheClassB',
    args => {
        foo => 'bar',
    },
    deref => 1,
);

# new 3

$cache = plasxom::cache->new;

isa_ok( $cache->{'cache'}, 'plasxom::cache::memory' );

$cache->set( foo => 'bar' );

is( $cache->get('foo'), 'bar' );

$cache->remove('foo');

ok( ! exists $cache->{'cache'}->{'foo'} );
