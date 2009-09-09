#!/usr/bin/perl

use strict;
use warnings;

package hlosxom;

use Text::MicroTemplate ();
use Path::Class ();
use Carp ();

our $VERSION = '0.01';

my %stash = ();
for my $property ( qw( config plugins methods vars cache entries entries_schema_class ) ) {
    no strict 'refs';
    *{$property} = sub {
        my $class = shift;
        if ( @_ ) { 
            $stash{$property} = shift @_;
        }
        else {
            return $stash{$property};
        }
    };
}

for my $method ( qw( template interpolate ) ) {
    no strict 'refs';
    *{$method} = sub {
        my ( $app, @args ) = @_;
        return $app->methods->{$method}->( $app, @args );
    };
}

__PACKAGE__->config( hlosxom::hash->new() );

__PACKAGE__->vars( hlosxom::hash->new() );

__PACKAGE__->methods({
    template    => sub {
        my ( $app, $path, $chunk, $flavour ) = @_;

        my $dir    = eval { $app->config->{'flavour'}->{'dir'} };
        Carp::croak "hlosxom->config->{'flaovur'}->{'dir'} is not specified." if ( $@ );
           $dir    = Path::Class::dir($dir);

           $path ||= q{};

            do {
                my $file = $dir->file($path, "${chunk}.${flavour}");
                if ( -e $file && -r _ ) {
                    my $fh = $file->openr;
                    my $data = do { local $/; <$fh> };
                    return $data;
                }
            }
            while ( $path =~ s{/*([^/]*)$}{} && $1 );

        return;
    },
    interpolate => sub {
        my ( $app, $template, $vars ) = @_;

        $vars ||= {};

        my $ret = eval { Text::MicroTemplate::render_mt( $template, $app, $vars )->as_string };
           $ret = "Interpolate error: $@" if ( $@ );

        return $ret;
    },
});

__PACKAGE__->entries_schema_class('hlosxom::entries::blosxom');

sub setup {
    my ( $class ) = @_;

    $class->setup_config;
    $class->setyp_vars;
    $class->setup_cache;
    $class->setup_plugins;
    $class->setup_methods;
    $class->setup_entries;

}

sub setup_config {
    my ( $class ) =  @_;

    my $file = hlosxom::util::env_value('config');
    my $conf = eval { require $file };

    die "Failed to load configuration file: $file: $@"      if ( $@ );
    die "Configuration value is not HASH reference: $conf"  if ( ref $conf ne 'HASH' );

    $class->config->merge( %{ $conf } );
}

sub setup_vars {
    my ( $class ) = @_;

    my $vars = $class->config->{'vars'} || {};

    $class->vars->merge( %{ $vars } );
}

sub setup_cache {
    my ( $class ) = @_;

    my $config = $class->config->{'cache'} || {};

    $class->cache( hlosxom::cache->new( %{ $config } ) );
}

sub setup_plugins {
    my ( $class ) = @_;

    my $config = $class->config->{'plugin'};

    my $dirs    = $config->{'plugin_dir'};
       $dirs    = [ $dirs ] if ( ref $dirs ne 'ARRAY' );
    my $state   = $config->{'plugin_state_dir'};
    my $order   = $class->config->{'plugins'};

    my $plugins = hlosxom::plugins->new(
        search_dirs => $dirs,
        state_dir   => $state,
        order       => $order,
    );

    $class->plugins( $plugins );

    $plugins->context( $class );

    $plugins->setup;
}

sub setup_methods {
    my ( $class ) = @_;

    for my $method ( keys %{ $class->methods } ) {
        if ( ref( my $sub = $class->plugins->run_plugin_first( $method ) ) ) {
            $class->methods->{$method} = $sub;
        }
    }

}

sub setup_entries {
    my ( $class ) = @_;

    my $schema = $class->entries_schema_class || 'hlosxom::entries::blosxom';
    my $config = $class->config->{'entries'} || {};

    if ( exists $config->{'use_cache'} && !! $config->{'use_cache'} ) {
        $config->{'cache'} = $class->cache;
    }

    my $entries = hlosxom::entries->new(
        schema => $schema,
        %{ $config },
    );

    $class->entries( $entries );
}

1;

package hlosxom::hash;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub merge {
    my ( $self, %new ) = @_;
    my %base = %{ $self };
    my $new = hlosxom::util::merge_hash( \%base, \%new );
    %{ $self } = %{ $new };
}

1;

package hlosxom::cache;

use Carp ();

sub new {
    my ( $class, %args ) = @_;

    my $cache_class = delete $args{'class'} || 'hlosxom::cache::memory';
    my $args  = delete $args{'args'};
    my $deref = ( !! $args{'deref'} ) ? 1 : 0 ;

    eval { require $cache_class } if ( $cache_class ne 'hlosxom::cache::memory' );
    Carp::croak "Failed to load cache class: ${cache_class}: $@" if ( $@ );

    my $cache;
    if ( $deref ) {
        $cache = $cache_class->new( %{ $args } );
    }
    else {
        $cache = $cache_class->new( $args );
    }

    my $self = bless {
        cache => $cache,
    }, $class;

    return $self;
}

sub set {
    my ( $self, $key, $value ) = @_;
    return $self->{'cache'}->set( $key, $value );
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{'cache'}->get( $key );
}

1;

package hlosxom::cache::memory;

sub new {
    my ( $class ) = @_;
    return bless {}, $class;
}

sub set {
    my ( $self, $key, $value ) = @_;
    $self->{$key} = $value;
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

package hlosxom::plugins;

use Path::Class::Dir;
use Carp ();

sub new {
    my ( $class, %args ) = @_;

    my $dirs = delete $args{'search_dirs'} or die "Argument 'search_dirs' is not specified.";
    my $state = delete $args{'state_dir'} or die "Argument 'state_dir' is not specified";
    my $order = delete $args{'order'};

    Carp::croak "Plugin order is not ARRAY reference." if ( ref $order ne 'ARRAY' );

    $dirs = [ $dirs ] if ( ref $dirs ne 'ARRAY' );

    my $plugin_dirs = [ map { Path::Class::Dir->new($_) } @{ $dirs } ];
    my $state_dir   = Path::Class::Dir->new($state);

    my $self = bless {
        search_dirs => $plugin_dirs,
        state_dir   => $state_dir,
        order       => $order,
        plugins     => [],
    }, $class;

    return $self;
}

sub search_dirs { $_[0]->{'search_dirs'}    }
sub state_dir   { $_[0]->{'state_dir'}      }
sub order       { $_[0]->{'order'}          }
sub plugins     { $_[0]->{'plugins'}        }

sub context     {
    my $self = shift;
    if ( @_ ) {
        $self->{'context'} = shift @_;
    }
    else {
        return $self->{'context'};
    }
}

sub setup {
    my ( $self ) = @_;

    my $state   = $self->state_dir;
    my $context = $self->context;
    my $plugins = $self->plugins;

    PLUGIN: for my $order ( @{ $self->order } ) {
        my $module = $order->{'plugin'};
        my $config = $order->{'config'};

        my $package = $module;
           $package =~ s{^hlosxom::plugin}{};
           $package = "hlosxom::plugin::${package}";

        for my $dir ( @{ $self->search_dirs } ) {
            my $path = $dir->file($module);

            if ( -e $path && -r _ ) {
                eval { require $path };

                Carp::croak "Failed to load plugin: $package: $path: $@" if ( $@ );
                for my $method ( qw( new setup start ) ) {
                    Carp::croak "${package}->${method} is not implemented."
                        if ( ! $package->can($method) );
                }

                my $instance = $package->new(
                    config => $config,
                    state  => $state->subdir($module),
                );

                my $on_off = ( !! $instance->setup( $context ) ) ? 1 : -1 ;

                push @{ $plugins }, +{
                    instance    => $instance,
                    enable      => $on_off,
                };

                next PLUGIN;
            }
        }

        Carp::croak "Plugin ${module} is not found.";
    }

}

sub prepare {
    my ( $self ) = @_;

    my $context = $self->context;
    for my $stash ( @{ $self->plugins } ) {
        my ( $plugin, $enable ) = @{ $stash }{qw( instance enable )};

        my $on_off = ( $enable > 0 && !! $plugin->start( $context ) ) ? 1 : -1 ;

        $stash->{'on_off'} = $on_off;
    }

}

sub run_plugins {
    my ( $self, $method, @args ) = @_;

    my @ret;
    my $context = $self->context;
    for my $stash ( @{ $self->plugins } ) {
        my ( $plugin, $enable, $on_off ) = @{ $stash }{qw( instance enable on_off )};

        my $switch = ( defined $on_off ) ? $on_off : $enable ;

        if ( $switch > 0 && $plugin->can($method) ) {
            push @ret, $plugin->$method( $context, @args );
        }
    }
    return @ret;
}

sub run_plugin_first {
    my ( $self, $method, @args ) = @_;

    my $context = $self->context;
    for my $stash ( @{ $self->plugins } ) {
        my ( $plugin, $enable, $on_off ) = @{ $stash }{qw( instance enable on_off )};

        my $switch = ( defined $on_off ) ? $on_off : $enable ;

        if ( $switch > 0 && $plugin->can($method) && defined( my $ret = $plugin->$method( $context, @args ) ) ) {
            return $ret;
        }
    }

    return;
}

1;

package hlosxom::entries;

use Carp ();

sub new {
    my ( $class, %args ) = @_;

    my $schema = delete $args{'schema'} or Carp::croak "Argument 'schema' is not specified.";
    my %config = %args;

    my $db = $schema->new( %config );

    my $self = bless {
        db      => $db,
        index   => {},
        flag    => {
            indexed => 0,
        },
    }, $class;
    return $self;
}

sub db { $_[0]->{'db'} }

sub indexed {
    my $self = shift;

    if ( @_ ) {
        $self->{'flag'}->{'indexed'} = shift @_;
    }
    else {
        return $self->{'flag'}->{'indexed'};
    }
}

sub index {
    my ( $self ) = @_;
    return $self->{'index'} if ( $self->indexed );

    my %index = ();
    my %entries = $self->db->index();

    for my $path ( keys %entries ) {
        my $entry = hlosxom::entry->new(
            db      => $self->db,
            path    => $path,
            %{ $entries{$path} },
        );
        $index{$path} = $entry;
    }

    $self->{'index'} = \%index;
    $self->indexed(1);

    return $self->{'index'};
}

sub exists {
    my ( $self, %args ) = @_;
    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    return $self->db->exists( path => $path );
}

1;

package hlosxom::entries::base;

use Carp ();

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { config => {} }, $class;

    $self->init( %args );

    return $self;
}

sub config { $_[0]->{'config'} }
sub init   { Carp::croak __PACKAGE__ . "::init is not implemented." }

for my $method (qw( create update select remove exists index )) {
    no strict 'refs';
    *{$method} = sub { Carp::croak __PACKAGE__ . "::${method} is not implemented." };
}

sub create_or_update {
    my ( $self, %args ) = @_;

    my $path = $args{'path'};
    Carp::croak "Argument 'path' is not specified." if ( ! defined $path );

    if ( $self->exists( path => $path ) ) {
        return $self->update( %args );
    }
    else {
        return $self->create( %args );
    }
}


1;

package hlosxom::entries::blosxom;

use Carp ();
use Path::Class ();
use File::Find ();
use File::stat ();
use base qw( hlosxom::entries::base );

sub init {
    my ( $self, %args ) = @_;

    my $entries_dir     = delete $args{'entries_dir'} or Carp::croak "Argument 'entries_dir' is not specified.";
    my $file_extension  = delete $args{'file_extension'} || 'txt';
    my $depth           = delete $args{'depth'} || 0;

    my $dir             = Path::Class::dir($entries_dir);
       $dir->absolute->cleanup;

    $self->{'config'} = {
        entries_dir     => $dir,
        file_extension  => $file_extension,
        depth           => $depth,
    };

    my $prefix          = delete $args{'meta_prefix'}   || 'meta-';
    my $mapping         = delete $args{'meta_mapping'}  || {};

    $mapping->{'summary_source'}    ||= 'summary';
    $mapping->{'pagename'}          ||= 'pagename';
    $mapping->{'created'}           ||= 'date';
    $mapping->{'tags'}              ||= 'tags';

    $self->{'meta'} = {
        prefix  => $prefix,
        mapping => $mapping,
    };

    my $dateparser      = delete $args{'meta_date_parser'}      || hlosxom::util->can('parse_date');
    my $dateformatter   = delete $args{'meta_date_formatter'}   || hlosxom::util->can('format_date');

    my $tagparser       = delete $args{'meta_tag_parser'}       || hlosxom::util->can('parse_tags');
    my $tagformatter    = delete $args{'meta_tag_formatter'}    || hlosxom::util->can('format_tags');

    Carp::croak "Argument 'meta_date_parser' is not CODE reference."    if ( ref $dateparser ne 'CODE' );
    Carp::croak "Argument 'meta_date_formatter' is not CODE reference." if ( ref $dateformatter ne 'CODE' );
    Carp::croak "Argument 'meta_tag_parser' is not CODE reference."     if ( ref $tagparser ne 'CODE' );
    Carp::croak "Argument 'meta_tag_formatter' is not CODE reference."  if ( ref $tagformatter ne 'CODE' );

    $self->{'parser'} = {
        date => $dateparser,
        tag  => $tagparser,
    };

    $self->{'formatter'} = {
        date => $dateformatter,
        tag  => $tagformatter,
    };

    my $use_cache       = ( !! $args{'use_cache'} ) ? 1 : 0 ;
    $self->{'config'}->{'use_cache'} = $use_cache;
    if ( $use_cache ) {
        my $cache = delete $args{'cache'} or Carp::croak "Argument 'cache' is not specified.";
        Carp::croak "Cache object is not hlosxom::cache instance." if ( ref $cache ne 'hlosxom::cache' );

        $self->{'cache'} = $cache;
    }

    my $use_index       = ( !! $args{'use_index'} ) ? 1 : 0;
    $self->{'config'}->{'use_index'} = $use_index;
    if ( $use_index ) {
        my $index_path = delete $args{'index_file'} or Carp::croak "Argument 'index_file' is not specified.";
        my $index_file = Path::Class::file($index_path);
           $index_file->absolute->cleanup;

        $self->{'index'} = $index_file;
    }
}

for my $prop (qw( entries_dir file_extension depth use_cache use_index ))  {
    no strict 'refs';
    *{$prop} = sub {
        my ( $self ) = @_;
        return $self->{'config'}->{$prop};
    };
}

sub entry_path {
    my ( $self, $path ) = @_;

    $path =~ s{/+}{/}g;
    $path =~ s{^/*}{};
    $path =~ s{/*$}{};

    return $path;
}

sub create {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
    Carp::croak "${path} is already exists: $path" if ( $self->exists( path => $path ) );

    return $self->update( path => $path, %args );
}

sub update {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);
       $path = "${path}." . $self->file_extension;
    my $file = $self->entries_dir->file( $path );
    my $source = $self->build( %args );

    if ( ! -d $file->dir ) {
        $file->dir->mkpath;
    }

    my $fh = $file->openw or Carp::croak "Failed to open file: $file: $!";
    print $fh $source;
    $fh->close;

    return 1;
}

sub select {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);

    my $file = $self->entries_dir->file( "${path}." . $self->file_extension );

    my $use_cache   = $self->use_cache;
    my $cache       = $self->{'cache'};

    if ( $self->exists( path => $path ) ) {
        if ( $use_cache ) {
            my $data = $cache->get($path);
            if ( defined $data && $data->{'lastmod'} == File::stat::stat( $file )->mtime ) {
                return %{ $data };
            }
        }

        my $fh = $file->openr or Carp::croak "Failed to open file: $file: $!";
        my $source = do { local $/; <$fh> };
        $fh->close;

        my %data = $self->parse( $source );
           $data{'lastmod'} = File::stat::stat($file)->mtime;

        if ( ! exists $data{'created'} ) {
            $data{'created'} = $data{'lastmod'};
            $self->update( path => $path, %data );
        }

        $cache->set( $path => \%data ) if ( $use_cache );

        return %data;
    }

    return ();
}

sub remove {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);

    if ( $self->exists( path => $path ) ) {
        my $file = $self->entries_dir->file( "${path}." . $self->file_extension );
        return $file->remove();
    }
    else {
        Carp::carp "${path} does not exists.";
        return;
    }

}

sub exists {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);
       $path = "${path}." . $self->file_extension;

    my $depth       = $self->depth;
    my $file_depth  = ( $path =~ tr{/}{} ) + 1;

    if ( ( ! $depth || $depth && $file_depth <= $depth ) && -e $self->entries_dir->file($path) && -r _ ) {
        return 1;
    }

    return 0;
}

sub index  {
    my ( $self ) = @_;

    my $use_index   = $self->use_index;
    my $index_file  = $self->{'index'};

    my $root        = $self->entries_dir->as_foreign('Unix')->stringify;

    my %index       = ();

    if ( $use_index && -e $index_file && -r _ ) {
        my $fh = $index_file->openr or Carp::croak "Failed to open index file: $index_file: $!";
        while ( my $line = <$fh> ) {
            chomp($line);
            if ( $line =~ m{^(\d+):(\d+)=>([^\s]+?)$} ) {
                $index{$3} = {
                    created => $1,
                    lastmod => $2,
                };
            }
        }
        $fh->close;
    }

    my $depth = $self->depth;
    my $fe    = $self->file_extension;

    File::Find::find(
        sub {
            my $file = $File::Find::name;

            return if ( -d $file );
            return if ( ! -r $file );
            return if ( $file !~ m{\.$fe$} );


            my $path = $file;
               $path =~ s{^$root/}{};
               $path =~ s{\.$fe$}{};

            my $file_depth = ( $path =~ tr{/}{} ) + 1;

            if ( $depth && $file_depth > $depth ) {
                delete $index{$path};
                return;
            }

            my $mtime = File::stat::stat($file)->mtime;
            if ( ! exists $index{$path} || $index{$path}->{'lastmod'} != $mtime  ) {
                $index{$path} = {
                    lastmod => $mtime,
                    created => { $self->select( path => $path ) }->{'created'},
                };
            }
        },
        $root,
    );

    if ( $use_index ) {
        my $data = q{};
        for my $path ( sort keys %index ) {
            my ( $created, $lastmod ) = @{ $index{$path} }{qw( created lastmod )};
            $data .= "${created}:${lastmod}=>${path}\n";
        }

        my $fh = $index_file->openw or Carp::croak "Failed to open index file: $index_file: $!";
        print $fh $data;
        $fh->close;

    }

    return %index;
}

sub parse {
    my ( $self, $text ) = @_;
    my @lines = split m{\n}, $text;
    my %data;

    # parse title
    my $title = shift @lines;
    chomp($title);

    # parse meta and some property
    my $meta_prefix     = quotemeta($self->{'meta'}->{'prefix'});
    my $meta_mapping    = $self->{'meta'}->{'mapping'};
    my $dateparser      = $self->{'parser'}->{'date'};
    my $tagparser       = $self->{'parser'}->{'tag'};

    my %meta2prop       = map { $meta_mapping->{$_} => $_ } keys %{ $meta_mapping };
    my $meta            = {};

    my @body = ();
    while ( defined( my $line = shift @lines ) ) {
        if ( $line =~ m{^$meta_prefix([a-zA-Z0-9]+?)[:]\s*(.*?)\s*$} ) {
            my $key     = $1;
            my $value   = $2;

            if ( exists $meta2prop{$key} ) {
                my $prop = $meta2prop{$key};
                if ( $prop eq 'tags' ) {
                    $data{$prop} = [ $tagparser->( $value ) ];
                }
                elsif ( $prop eq 'created' ) {
                    $data{$prop} = $dateparser->( $value );
                }
                else {
                    $data{$prop} = $value;
                }
            }
            else {
                $meta->{$key} = $value;
            }

            next;
        }

        push @body, $line;
        last;
    }

    push @body, @lines;

    # parse body
    my $body = join qq{\n}, @body;

    # set data
    $data{'title'}          = $title;
    $data{'body_source'}    = $body;
    $data{'meta'}           = $meta;

    return %data;
}

sub build {
    my ( $self, %args ) = @_;

    my $title   = delete $args{'title'};
    my $body    = delete $args{'body_source'};

    my $meta    = delete $args{'meta'} || {};
    my %meta    = ();
    for my $key ( keys %{ $meta } ) {
        $meta{$key} = $meta->{$key};
    }

    my ( $tagformatter, $dateformatter ) = @{ $self->{'formatter'} }{qw( tag date )};
    my $mapping = $self->{'meta'}->{'mapping'};

    for my $prop ( qw( summary_source pagename created tags ) ) {
        my $key = $mapping->{$prop};
        if ( defined( my $value = delete $args{$prop} ) ) {
            if ( $prop eq 'created' ) {
                $value = $dateformatter->( $value );
            }
            elsif ( $prop eq 'tags' ) {
                my $tags = $value;
                Carp::croak "Argument 'tags' is not ARRAy reference." if ( ref $tags ne 'ARRAY' );
                $value = $tagformatter->( @{ $tags } );
            }

            $meta{$key} = $value;
        }
    }

    my $meta_prefix = $self->{'meta'}->{'prefix'};

    my $source = q{};
       $source .= "${title}\n";
       $source .= join( qq{\n}, map { "${meta_prefix}$_: " . $meta{$_} } sort keys %meta ) . qq{\n};
       $source .= "${body}";

    return $source;
}

1;

package hlosxom::entry;

use Carp ();

sub new {
    my ( $class, %args ) = @_;

    my $fullpath = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
    my $db       = delete $args{'db'}   or Carp::croak "Argument 'db' is not specified.";

    my ( $path, $fn );

    if ( $fullpath =~ m{^(?:(.*)/)?(.+)$} ) {
        $path           = $1;
        $fn             = $2;
    }
    else {
        Carp::croak "Invalid path: ${fullpath}";
    }

    my $self = bless {
        path        => {
            path            => $path,
            filename        => $fn,
        },
        property    => {},
        flag        => {
            loaded => 0,
        },
        db          => $db,
        formatter   => {},
    }, $class;

}

for my $prop (qw( title body_source summary_source pagename permalink created lastmod tags meta )) {
    no strict 'refs';
    *{$prop} = sub {
        my $self = shift;
        if ( @_ ) {
            $self->{'property'}->{$prop} = shift;
        }
        else {
            if ( ! exists $self->{'property'}->{$prop} && ! $self->loaded ) {
                $self->load;
            }
            return $self->{'property'}->{$prop};
        }
    };
}

for my $prop ( qw( body summary ) ) {
    no strict 'refs';
    *{$prop} = sub {
        my $self = shift;

        if ( @_ ) {
            $self->{'property'}->{$prop} = shift;
        }
        else {
            if ( ! exists $self->{'property'}->{"${prop}_source"} && ! $self->loaded ) {
                $self->load;
            }

            if ( ! exists $self->{'property'}->{$prop} ) {
                my $source = "${prop}_source";
                my $body    = $self->$source;
                my $stash   = $self->formatter;

                if ( exists $stash->{'formatter'} && exists $stash->{'method'} ) {
                    my ( $formatter, $method ) = @{ $stash }{qw( formatter method )};
                    $body = $formatter->$method( $self );
                }

                $self->{'property'}->{$prop} = $body
            }

            return $self->{'property'}->{$prop};
        }
    };
}

for my $prop ( qw( title body body_source summary summary_source pagename permalink created lastmod tags meta  ) ) {
    no strict 'refs';
    *{"clear_${prop}"} = sub {
        my ( $self ) = @_;
        my $ret = delete $self->{'property'}->{$prop};
        return $ret;
    }
}

sub clear_all {
    my ( $self ) = @_;

    $self->{'property'}  = {};
    $self->{'flag'}      = { loaded => 0 };
    $self->{'formatter'} = {};

    return 1;
}

sub register_formatter {
    my ( $self, $formatter, $method ) = @_;

    Carp::croak "formatter is not specified." if ( ! defined $formatter );
    Carp::croak "formatter method is not specified." if ( ! defined $method );

    $self->{'formatter'} = {
        formatter   => $formatter,
        method      => $method,
    };
}

sub clear_formatter {
    my ( $self ) = @_;

    $self->{'formatter'} = {};
}

sub formatter { $_[0]->{'formatter'} };

for my $flag (qw( loaded )) {
    no strict 'refs';
    *{$flag} = sub {
        my $self = shift;
        if ( @_ ) {
            $self->{'flag'}->{$flag} = shift;
        }
        else {
            return $self->{'flag'}->{$flag};
        }
    };
}

for my $prop (qw( path filename )) {
    no strict 'refs';
    *{$prop} = sub {
        my ( $self ) = @_;
        return $self->{'path'}->{$prop};
    }
}

sub db { $_[0]->{'db'} }

sub fullpath {
    my ( $self ) = @_;

    my $path    = $self->path;
    my $fn      = $self->filename;

    return "${path}/${fn}";
}

sub load {
    my ( $self, %args ) = @_;

    my $path = $self->fullpath;
    my $reload = ( !! $args{'reload'} ) ? 1 : 0 ;

    if ( $self->db->exists( path => $path ) ) {
        my %data = $self->db->select( path => $path );

        Carp::croak "data->{'tags'} is not ARRAY reference." if ( ref $data{'tags'} ne 'ARRAY' );
        Carp::croak "data->{'meta'} is not HASH reference." if ( ref $data{'meta'} ne 'HASH' );

        for my $prop ( qw( title body_source summary_source pagename permalink created lastmod tags meta ) ) {
            if ( ! exists $self->{'property'}->{$prop} || $reload ) {
                $self->{'property'}->{$prop} = $data{$prop};
            }
        }

        $self->loaded( 1 );
    }
    else {
        Carp::croak "${path} is not exists.";
    }
}

sub reload {
    my ( $self ) = @_;
    return $self->load( reload => 1 );
}

sub commit {
    my ( $self ) = @_;
    return $self->db->create_or_update(
        path => $self->fullpath,
        %{ $self->{'property'} },
    );
}

1;

package hlosxom::util;

use Carp ();
use Time::Local ();

sub env_value {
    my ( $key ) = @_;

    my $prefix  = uc 'hlosxom';
       $key     = uc $key;
    my $env     = "${prefix}_${key}";

    if ( exists $ENV{$env} ) {
        return $ENV{$env};
    }

    return;
}

sub merge_hash {
    my ( $left, $right ) = @_;

    if ( ! defined $right ) {
        return $left;
    }

    if ( ! defined $left ) {
        return $right;
    }

    Carp::croak "Left hash is not HASH reference."
        if ( ref $left ne 'HASH' );

    Carp::croak "Right hash is not HASH reference."
        if ( ref $right ne 'HASH' );

    my %merged = %{ $left };
    for my $key ( keys %{ $right } ) {
        if (
            ( ref $right->{$key} eq 'HASH' )
            && ( exists $left->{$key} && ref $left->{$key} eq 'HASH' )
        ) {
            $merged{$key} = merge_hash( $left->{$key}, $right->{$key} );
        }
        else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;

}

sub parse_date {
    my ( $w3cdtf ) = @_;

    $w3cdtf =~ m{
        ^(\d{4})
        (?: [-](\d{2})
            (?: [-](\d{2})
                (?: [T](\d{2})[:](\d{2})
                    (?: [:](\d{2})(?:\.(\d+))? )?
                    ( Z | ([-+]) (\d{2}):(\d{2}) )?
                )?
            )?
        )?
    }x or Carp::croak "Invalid W3C datetime format: ${w3cdtf}";

    my ( $yr, $mo, $da, $hr, $min, $sec, $nano, $tz );

    $yr     = $1 - 1900;
    $mo     = ( $2 || 1 ) - 1;
    $da     = $3 || 1;
    $hr     = $4 || 0;
    $min    = $5 || 0;
    $sec    = $6 || 0;

    if ( ! $8 ) {
        $tz = Time::Local::timegm(localtime 0);
    }
    elsif ( $8 eq 'Z' ) {
        $tz = 0;
    }
    else {
        $tz = ( $10 * 3600 + $11 * 60 );
        $tz *= -1 if ( $9 eq '-' );
    }

    my $time = Time::Local::timegm( $sec, $min, $hr, $da, $mo, $yr );

    return $time - $tz;
}

sub format_date {
    my ( $time  ) = @_;

    Carp::croak "Epoch time is not specified."  if ( ! defined $time );

    my $tz;
    my $z = Time::Local::timegm(localtime(0));
    my $zh = $z / 3600;
    my $zm = (abs($z) % 3600) / 60;
    if ( $zh == 0 && $zm == 0 ) {
        $tz = 'Z';
    }
    else {
        $tz = sprintf("%+03d:%02d", $zh, $zm);
    }

    my ( $sec, $min, $hr, $da, $mo, $yr ) = localtime($time);

    $yr += 1900;
    $mo += 1;

    return sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d%s',
        $yr, $mo, $da, $hr, $min, $sec, $tz,
    );
}

sub parse_tags {
    my ( $str ) = @_;

    $str =~ s{\s+}{ }g;
    $str =~ s{\s*[,]\s*$}{}g;

    return split m{\s*[,]\s*}, $str;
}

sub format_tags {
    my ( @tags ) = @_;

    return join q{, }, @tags;
}

1;

package main;

if ( hlosxom::util::env_value('bootstrap') ) {
    hlosxom->setup;
    hlosxom->run;
}

1;

__END__
