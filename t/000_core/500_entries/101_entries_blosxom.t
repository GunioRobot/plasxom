#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom $example );
use File::stat;
use File::Temp;
use Test::Warn;
use Test::More
    tests => 1 + 3 + 2 + 2 + 1 + 1 + 1 
           + 2 + 3 + 7
           + 1 + 2 + 1 + 2
           + 1;


BEGIN { require_hlosxom }

my $datadir = $example->subdir('core/entries/blosxom')->absolute->cleanup;

my %args = (
    entries_dir     => $datadir->stringify,
    file_extension  => 'txt',
    depth           => 0,
    meta_prefix     => '@',
);

# new test
my $db = hlosxom::entries::blosxom->new( %args );

isa_ok( $db, 'hlosxom::entries::blosxom' );

isa_ok( $db->entries_dir, 'Path::Class::Dir' );
is( $db->file_extension, 'txt' );
is( $db->depth, 0 );

is( $db->use_cache, 0 );
ok( ! $db->{'cache'} );

is( $db->use_index, 0 );
ok( ! $db->{'index'} );

is_deeply(
    $db->{'meta'},
    {
        prefix  => '@',
        mapping => {
            created         => 'date',
            pagename        => 'pagename',
            summary_source  => 'summary',
            tags            => 'tags',
        },
    }
);

is_deeply(
    $db->{'parser'},
    {
        date    => hlosxom::util->can('parse_date'),
        tag     => hlosxom::util->can('parse_tags'),
    },
);

is_deeply(
    $db->{'formatter'},
    {
        date    => hlosxom::util->can('format_date'),
        tag     => hlosxom::util->can('format_tags'),
    },
);

my $sub = sub{};
$db = hlosxom::entries::blosxom->new(
    %args,
    meta_date_parser    => $sub,
    meta_date_formatter => $sub,
    meta_tag_parser     => $sub,
    meta_tag_formatter  => $sub,
);

is_deeply(
    $db->{'parser'},
    {
        date => $sub,
        tag  => $sub,
    },
);

is_deeply(
    $db->{'formatter'},
    {
        date => $sub,
        tag  => $sub,
    },
);

# select, exists and index tests
$db = hlosxom::entries::blosxom->new( %args, depth => 1 );

# exists
ok( $db->exists( path => 'foo' ) );
ok( ! $db->exists( path => 'notfound' ) );
ok( ! $db->exists( path => 'foo/bar' ) );

# select
is_deeply(
    { $db->select( path => 'foo' ) },
    {
        title           => 'title',
        body_source     => 'body',
        summary_source  => 'description',
        pagename        => 'foopage',
        tags            => [qw( foo bar baz )],
        created         => 1230735600,
        lastmod         => stat($datadir->file('foo.txt'))->mtime,
        meta            => { foo => 'bar', bar => 'baz' },
    }
);

# index
is_deeply(
    { $db->index },
    {
        'foo'       => {
            title       => 'title',
            pagename    => 'foopage',
            tags        => [qw( foo bar baz )],
            meta        => { foo => 'bar', bar => 'baz' },
            created => 1230735600,
            lastmod => stat( $datadir->file('foo.txt') )->mtime,
        },
    },
);

# cache, index file test

{
    my $temp = File::Temp->new();

    $db = hlosxom::entries::blosxom->new(
        use_cache   => 1,
        cache       => 'hlosxom::cache'->new,
        use_index   => 1,
        index_file  => $temp->filename,
        %args,
    );

    # cache
    $db->select( path => 'foo' );

    is_deeply(
        $db->{'cache'}->{'cache'}->{'hlosxom-entries-blosxom:foo'},
        {
            title           => 'title',
            body_source     => 'body',
            summary_source  => 'description',
            pagename        => 'foopage',
            tags            => [qw( foo bar baz )],
            created         => 1230735600,
            lastmod         => stat($datadir->file('foo.txt'))->mtime,
            meta            => { foo => 'bar', bar => 'baz' },
        },
    );

    $db->select( path => 'foo/bar' );
    is_deeply(
        $db->{'cache'}->{'cache'}->{'hlosxom-entries-blosxom:foo/bar'},
        {
            title           => 'title',
            body_source     => 'body',
            summary_source  => 'description',
            pagename        => 'foopage',
            tags            => [qw( foo bar baz )],
            created         => 1230735600,
            lastmod         => stat($datadir->file('foo/bar.txt'))->mtime,
            meta            => { foo => 'bar', bar => 'baz' },
        },
    );

    # index
    is_deeply(
        { $db->index() },
        {
            'foo'       => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo.txt') )->mtime,
            },
            'foo/bar'   => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo/bar.txt') )->mtime,
            },
        },
    );

    my $data = do $db->{'index'}->stringify;
    is_deeply(
        $data,
        {
            'foo'       => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo.txt') )->mtime,
            },
            'foo/bar'   => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo/bar.txt') )->mtime,
            },
        },

    );

    is_deeply(
        { $db->index() },
        {
            'foo'       => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo.txt') )->mtime,
            },
            'foo/bar'   => {
                title       => 'title',
                pagename    => 'foopage',
                tags        => [qw( foo bar baz )],
                meta        => { foo => 'bar', bar => 'baz' },
                created     => 1230735600,
                lastmod     => stat( $datadir->file('foo/bar.txt') )->mtime,
            },
        },
    );
}

# update, create, update in select, remove test
{
    my $temp = File::Temp->newdir;

    my $db = hlosxom::entries::blosxom->new(
        %args,
        entries_dir => $temp->dirname,
        auto_update => 1,
    );

    # update
    my %entry = (
        title           => 'title',
        body_source     => 'body',
        summary_source  => 'description',
        pagename        => 'foobarbaz',
        tags            => [qw( foo bar baz )],
        meta            => { foo => 'bar', bar => 'baz' },
    );
    $db->update( path => 'foo', %entry );

    is(
        $db->entries_dir->file('foo.txt')->slurp(),
          qq{title\n}
        . qq{\@bar: baz\n}
        . qq{\@foo: bar\n}
        . qq{\@pagename: foobarbaz\n}
        . qq{\@summary: description\n}
        . qq{\@tags: ['foo','bar','baz']\n}
        . qq{body}
    );

    # select and update
    is_deeply(
        { $db->select( path => 'foo' ) },
        {
            title           => 'title',
            body_source     => 'body',
            summary_source  => 'description',
            pagename        => 'foobarbaz',
            tags            => [qw( foo bar baz )],
            meta            => { foo => 'bar', bar => 'baz' },
            created         => stat($db->entries_dir->file('foo.txt'))->mtime,
            lastmod         => stat($db->entries_dir->file('foo.txt'))->mtime,
        }
    );

    is(
        $db->entries_dir->file('foo.txt')->slurp(),
          qq{title\n}
        . qq{\@bar: baz\n}
        . qq{\@date: } . hlosxom::util::format_date( stat($db->entries_dir->file('foo.txt'))->mtime ) . "\n"
        . qq{\@foo: bar\n}
        . qq{\@pagename: foobarbaz\n}
        . qq{\@summary: description\n}
        . qq{\@tags: ['foo','bar','baz']\n}
        . qq{body}
    );

    # create
    $db->create( path => 'bar/baz', %entry );

    is_deeply(
        { $db->select( path => 'bar/baz' ) },
        {
            title           => 'title',
            body_source     => 'body',
            summary_source  => 'description',
            pagename        => 'foobarbaz',
            tags            => [qw( foo bar baz )],
            meta            => { foo => 'bar', bar => 'baz' },
            created         => stat($db->entries_dir->file('bar/baz.txt'))->mtime,
            lastmod         => stat($db->entries_dir->file('bar/baz.txt'))->mtime,
        }
    );

    # remove
    ok( $db->remove( path => 'foo' ) );
    ok( ! $db->exists( path => 'foo' ) );
}

$db = hlosxom::entries::blosxom->new( %args, readonly => 1 );

warning_is { $db->update( path => 'foo', title => 'updated' ) } 'Entries are readonly.';
