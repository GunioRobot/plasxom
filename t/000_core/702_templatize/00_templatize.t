#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 4;
use Plack::Request;
use Plack::Response;

require_plasxom;

our $templates = plasxom::templates->new(
    source      => plasxom::template::source::file->new( root_dir => $example->subdir('core/templatize/flavours') ),
    renderer    => plasxom::template::renderer::microtemplate->new,
);

{
    package plugins;

    sub new { bless {}, shift }

    sub run_plugins {
        our ( $self, $method, @args ) = @_;

        package main;

        if ( $plugins::method eq 'templatize' ) {
            is_deeply(
                [ @plugins::args ],
                [
                    $main::templates->load('content_type.atom'),
                    $main::templates->load('foo/bar/template.atom'),
                    {
                        entries => [qw( foo bar baz )],
                        flavour => plasxom::flavour->new( flavour => 'atom', path_info => '/foo/bar/baz.atom' ),
                    }
                ]
            );
        }
        elsif ( $plugins::method eq 'output' ) {
            is_deeply(
                [ @plugins::args ],
                [ \q{text/plain}, \q{bar}, ],
            );
        }

    }

    package entries;

    sub new { bless {}, shift }

    sub filtered { [qw( foo bar baz )] }
}

my $app = plasxom->new;
   $app->flavour( plasxom::flavour->new( flavour => 'atom', path_info => '/foo/bar/baz.atom' ) );
   $app->plugins( plugins->new );
   $app->entries( entries->new );
   $app->templates( $templates );

   $app->req( Plack::Request->new({ 'psgi.url_scheme' => 'http', HTTP_HOST => 'localhost', PATH_INFO => '/foo/bar/baz.atom', REQUEST_METHOD => 'GET', }) );
   $app->res( Plack::Response->new );
   $app->templatize;

   is( $app->res->headers->header('Content-Type'), 'text/plain' );
   is( $app->res->body, 'bar' );
