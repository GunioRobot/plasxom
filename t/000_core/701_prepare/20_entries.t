#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use Test::More tests => 9;

require_hlosxom;

my $datadir = $example->subdir('core/entries/blosxom');

our $entries = hlosxom::entries->new(
    schema          => 'hlosxom::entries::blosxom',
    entries_dir     => $datadir,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

{
    package hlosxom::entries;
    
    no strict 'refs';
    no warnings 'redefine';

    *{"filter"} = sub {
        our ( $self, %args ) = @_;
        package main;
        is_deeply(
            { %hlosxom::entries::args },
            {
                year => 2009,
                month => 10,
                day => 20,
                flavour => 'html',
                pagename => 'foo',
                path => 'foo/bar',
                meta => {
                    key => "(?-xism:value)",
                },
                stash   => {
                    key => 'value',
                },
                tag => {
                    op => 'OR',
                    words => [qw( foo bar baz )],
                }
            }
        );

        return ( $main::entries->entry( path => 'foo' ) );
    };

    *{'paginate'} = sub {
        our ( $self, %args ) = @_;
        package main;

        is( $hlosxom::entries::args{'page'}, 1 );

        package hlosxom::entries;
        
        return $self->filter( %args );
    };

    package plugins;

    sub new { bless {}, shift }

    sub run_plugins {
        our ( $self, $method, $arg ) = @_;
        package main;
        if ( $plugins::method eq 'update' ) {
            isa_ok( $arg, 'hlosxom::entry' );
        }
        elsif ( $plugins::method eq 'entries' ) {
            is_deeply(
                $arg,
                [ $main::entries->entry( path => 'foo' ) ],
            );
        }
    }

}

hlosxom->entries( $entries );
hlosxom->plugins( plugins->new );

my $app = hlosxom->new;
   $app->flavour( hlosxom::flavour->new(
        year => 2009,
        month => 10,
        day => 20,
        flavour => 'html',
        pagename => 'foo',
        path => 'foo',
        filename => 'bar',
        meta => {
            key => qr{value},
        },
        stash   => {
            key => 'value',
        },
        tags => [qw( foo bar baz )],
        tag_op => 'OR',
   ) );
   $app->prepare_entries;
   
   $app->flavour->page('all');
   $app->prepare_entries;

is_deeply(
    $app->entries->filtered,
    [
        $entries->entry( path => 'foo' ),
    ]
);