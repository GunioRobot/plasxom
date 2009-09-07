#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More;

require_hlosxom;

our %entry = (
    title           => 'title',
    body_source     => 'body',
    summary_source  => 'summary',
    pagename        => 'foo',
    permalink       => 'http://localhost/foo/bar',
    created         => 0,
    lastmod         => 1,
    tags            => [qw( foo bar baz )],
    meta            => {},
);

my @props = keys %entry;

plan tests =>
    3                                           # path test
    + 1                                         # default property
    + 1                                         # default flag
    + 1                                         # database
    + 2 + 1 + (scalar(@props) * 5) + ( 2 * 6 )  # property test
    + 5 + ( (scalar(@props) + 2) * 2)           # clear test
    + 2 + 1                                     # commit test
    + 2 + 2 + ( scalar(@props) * 2 )            # reload test
    ;

{
    package TestLoader;
    
    sub select {
        our ( $class, %args ) = @_;

        package main;
        is( $TestLoader::args{'path'}, '/path/to/entry' );
        return %entry;
    }
    
    sub exists {
        our ( $class, %args ) = @_;

        package main;
        is( $TestLoader::args{'path'}, '/path/to/entry' );
        return 1;
    }
    
    sub create_or_update {
        our ( $class, %args ) = @_;

        package main;

        my %entry = %main::entry;
           $entry{'path'} = '/path/to/entry';

        is_deeply( \%entry, \%TestLoader::args );

    }

    1;

    package TestFormatter;
    
    sub format {
        our ( $class, $entry ) = @_;
        package main;
        
        isa_ok( $TestFormatter::entry, 'hlosxom::entry' );
        return 'foobarbaz';
    }
};

my $entry = hlosxom::entry->new(
    path => '/path/to/entry',
    db   => 'TestLoader',
);

# path
is( $entry->path,           '/path/to'              );
is( $entry->filename,       'entry'                 );
is( $entry->fullpath,       '/path/to/entry'        );

# default property
is_deeply( $entry->{'property'}, {} );

# default flag
is( $entry->loaded, 0 );

# database
is( $entry->db, 'TestLoader' );

# property tests
$entry->load;

is( $entry->loaded, 1 );

for my $prop ( @props ) {
    is_deeply( $entry->$prop, $entry{$prop} );
    $entry->$prop('foo');
    is( $entry->$prop, 'foo' );
    $entry->clear_all;
    is_deeply( $entry->$prop, $entry{$prop} );
}

for my $prop (qw( body summary )) {
    # load test
    $entry->clear_all;
    is( $entry->$prop, $entry{"${prop}_source"} );

    # set test
    $entry->$prop( 'bar' );
    is( $entry->$prop, 'bar' );

    # formatter test
    delete $entry->{'property'}->{$prop};
    $entry->register_formatter('TestFormatter' => 'format');

    is( $entry->$prop, 'foobarbaz' );

    $entry->clear_formatter;
};


# clear test
$entry->clear_all;

is_deeply( $entry->{'property'},    {} );
is_deeply( $entry->{'flag'},        { loaded => 0 } );
is_deeply( $entry->{'formatter'},   {} );

$entry->load;

for my $prop ( @props, qw( body summary ) ) {
    my $method = "clear_${prop}";
    is( $entry->$method(), $entry{$prop} );
    ok( ! $entry->$method );
}

# commit test
$entry->clear_all;
$entry->load;

$entry->commit;

# reload test
$entry = hlosxom::entry->new( path => '/path/to/entry', db => 'TestLoader' );
$entry->load;
for my $prop ( @props) {
    $entry->$prop('foo');
    is( $entry->$prop, 'foo' );
}

$entry->reload;
for my $prop ( @props ) {
    is_deeply( $entry->$prop, $entry{$prop} );
}