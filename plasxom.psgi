#!/usr/bin/perl

use strict;
use warnings;

# global
use Carp ();
use Path::Class ();

# template
use Text::MicroTemplate ();

# entries
use File::Find ();
use File::stat ();
use Data::Dumper ();

# date
use Time::localtime ();
use Time::Local ();

# util
use Time::Local ();

# handler
use Plack::Request;
use Plack::Response;

package plasxom;

our $VERSION = '0.02';

my %stash = ();
for my $property ( qw( config plugins templates vars cache entries entries_schema_class template_source_class template_renderer_class server dispatcher api ) ) {
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

for my $property (qw( request response flavour )) {
    no strict 'refs';
    *{$property} = sub {
        my $self = shift;
        if ( @_ ) {
            $self->{$property} = shift @_;
        }
        else {
            return $self->{$property};
        }
    }
}

*req = __PACKAGE__->can('request');
*res = __PACKAGE__->can('response');

__PACKAGE__->config( plasxom::hash->new() );

__PACKAGE__->vars( plasxom::hash->new() );

__PACKAGE__->api( plasxom::api->new() );

__PACKAGE__->entries_schema_class('plasxom::entries::blosxom');
__PACKAGE__->template_source_class('plasxom::template::source::file');
__PACKAGE__->template_renderer_class('plasxom::template::renderer::microtemplate');

sub setup {
    my ( $class ) = @_;

    $class->setup_config;
    $class->setup_vars;
    $class->setup_cache;
    $class->setup_plugins;
    $class->setup_templates;
    $class->setup_entries;
    $class->setup_dispatcher;
    $class->setup_engine;

}

sub setup_config {
    my ( $class ) =  @_;

    my $file = plasxom::util::env_value('config');
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

    $class->cache( plasxom::cache->new( %{ $config } ) );
}

sub setup_plugins {
    my ( $class ) = @_;

    my $config = $class->config->{'plugin'};

    my $dirs    = $config->{'plugin_dir'};
       $dirs    = [ $dirs ] if ( ref $dirs ne 'ARRAY' );
    my $state   = $config->{'plugin_state_dir'};
    my $order   = $class->config->{'plugins'};

    my $plugins = plasxom::plugins->new(
        search_dirs => $dirs,
        state_dir   => $state,
        order       => $order,
    );

    $class->plugins( $plugins );

    $plugins->context( $class );

    $plugins->setup;
}

sub setup_templates {
    my ( $class ) = @_;

    my $source_class    = $class->template_source_class || 'plasxom::template::source::file';
    my %source_config   = %{ $class->config->{'template'}->{'source'} || {} };

    my $renderer_class  = $class->template_renderer_class || 'plasxom::template::renderer::microtemplate';
    my %renderer_config = %{ $class->config->{'template'}->{'renderer'} || {} };

    my $source      = $source_class->new( %source_config );
    my $renderer    = $renderer_class->new( %renderer_config );

    my $tmpls = plasxom::templates->new( source => $source, renderer => $renderer );

    $class->templates( $tmpls );
}

sub setup_entries {
    my ( $class ) = @_;

    my $schema = $class->entries_schema_class || 'plasxom::entries::blosxom';
    my %config = %{ $class->config->{'entries'} || {} };

    if ( exists $config{'use_cache'} && $config{'use_cache'} ) {
        $config{'cache'} = $class->cache;
    }

    my $entries = plasxom::entries->new(
        schema => $schema,
        %config,
    );

    $class->entries( $entries );


    $class->plugins->run_plugins('filter' => $entries);
}

sub setup_dispatcher {
    my ( $class ) = @_;

    my %config = %{ $class->config->{'dispatch'} || {} };
    my $dispatcher = plasxom::dispatcher->new( %config );

    $class->dispatcher( $dispatcher );
}

sub setup_engine {
    my ( $class ) = @_;

    my %config      = %{ $class->config->{'server'} || {} };
    my $middleware  = delete $config{'middleware'} || [];

    Carp::croak "config->{'server'}->{'middleware'} is not ARRAY reference." if ( ref $middleware ne 'ARRAY' );
    my $count = 0;
    for my $mw ( @{ $middleware } ) {
        Carp::croak "config->{'server'}->{'middleware'}->[${count}] is not ARRAY reference. middleware example: [ \$middleware, \@args ]"
            if ( ref $mw ne 'ARRAY' );
    }

    $class->server( { middleware => $middleware } );
}

sub handler {
    my ( $env ) = @_;

    my $app = __PACKAGE__->new;
       $app->req( Plack::Request->new($env) );
       $app->res( Plack::Response->new );
       $app->res->status(200);
       $app->plugins->context( $app );

    $app->run;

    return $app->res->finalize;
}

sub new {
    my ( $class ) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub run {
    my ( $self ) = @_;

    $self->prepare;

    if ( ! $self->plugins->run_plugin_first('skip') ) {
        $self->templatize;
    }

    $self->finalize;
}

sub prepare {
    my ( $self ) = @_;

    $self->prepare_plugins;
    $self->prepare_flavour;
    $self->prepare_entries;
}

sub prepare_plugins {
    my ( $self ) = @_;
    $self->plugins->prepare;
}

sub prepare_flavour {
    my ( $self ) = @_;

    my %config = %{ $self->config->{'flavour'} || {} };
    my $default = delete $config{'default'};
       $default = 'html' if ( ! defined $default );

    $self->flavour( $self->dispatcher->dispatch( $self->req ) );
    $self->flavour->flavour( $default ) if ( ! defined $self->flavour->flavour );

    $self->plugins->run_plugins('flavour' => $self->flavour);
}

sub prepare_entries {
    my ( $self ) = @_;

    my $flavour = $self->flavour;
    my $entries = $self->entries;
    my $plugins = $self->plugins;

    # reload index
    for my $entry ( @{ $entries->index } ) {
        if ( ! $entries->exists( path => $entry->{'path'}->{'fullpath'} ) ) {
            $entries->reindex;
        }
    }

    # reload entry
    for my $entry ( @{ $entries->index } ) {
        if ( $entry->is_modified_source ) {
            $entry->reload;
        }
    }

    # update entries
    $plugins->run_plugins( update => $entries );

    my %args    = ();

    # date, flavour and pagename
    for my $prop (qw( year month day flavour pagename )) {
        $args{$prop} = $flavour->$prop if ( $flavour->$prop );
    }

    # path, filename
    my $path            = $flavour->path;
       $path            = q{} if ( ! defined $path );
    $args{'path'}       = $path if ( $path ne q{} );

    my $filename        = $flavour->filename;
       $filename        = q{} if ( ! defined $filename );
    $args{'filename'}   = $filename if ( $filename ne q{} );

    # meta
    if ( scalar(keys %{ $flavour->meta || {} }) ) {
        $args{'meta'} = {};
        my $meta = $flavour->meta;
        for my $key ( keys %{ $meta } ) {
            my $value = $meta->{$key};
            $args{'meta'}->{$key} = "$value";
        }
    }

    # stash
    if ( scalar( keys %{ $flavour->stash || {} } ) ) {
        $args{'stash'} = {};
        my $stash = $flavour->stash;
        for my $key ( keys %{ $stash } ) {
            my $value = $stash->{$key};
            $args{'stash'}->{$key} = "$value";
        }
    }

    # tags
    if ( @{ $flavour->tags } ) {
        $args{'tag'} = {
            op      => $flavour->tag_op || 'AND',
            words   => [@{ $flavour->tags }],
        };
    }

    # page
    my $page;
    if ( defined $flavour->page ) {
        $page = $flavour->page;
        if ( $page eq 'all' ) {
            $page   = 'all';
        }
        else {
            $page   ||= 1;
            $page   = 1 if ( $page !~ m{^\d+$} );
            $args{'page'} = $page;
        }
    }
    elsif ( defined $flavour->year || defined $flavour->month || defined $flavour->day ) {
        $page   = 'all';
    }

    my $method = ( $page eq 'all' ) ? 'filter' : 'pagiante' ;

    my $filtered = [ $entries->$method( %args ) ];
    $self->entries->filtered( $filtered );

    $self->plugins->run_plugins('entries' => $filtered);
}

sub templatize {
    my ( $self ) = @_;

    my $flavour     = $self->flavour;
    my $plugins     = $self->plugins;
    my $templates   = $self->templates;

    my $path_info   = $flavour->path_info || q{};
    my $flav_ext    = $flavour->flavour;

    my $content_type    = $templates->dispatch( $path_info, 'content_type', $flav_ext );
    my $ctt_source      = $content_type->source;
       $ctt_source      =~ s{\n.*}{}s;
    $content_type->source( $ctt_source );

    my $template        = $templates->dispatch( $path_info, 'template', $flav_ext );
    my $vars            = {
        entries => $self->entries->filtered,
        flavour => $flavour,
    };

    $plugins->run_plugins('templatize', $content_type, $template, $vars);

    my $ctt    = $content_type->render( $self, $vars );
    my $output = $template->render( $self, $vars );

    $plugins->run_plugins('output', \$ctt, \$output);

    $self->res->content_type($ctt);
    $self->res->body( $output );
}

sub finalize {
    my ( $self ) = @_;
    $self->plugins->run_plugins('end');
}

sub application {
    my ( $class ) = @_;

    $class->setup;

    my %config  = %{ $class->server };
    my $mws     = delete $config{'middleware'} || [];

    my $app     = $class->can('handler');

    for my $mw ( @{ $mws } ) {
        my ( $mwclass, @args ) = @{ $mw };

        my ( $failed, $error );
        do {
            local $@;
            my $failed = not eval "use ${mwclass}; 1";
            my $error  = $@;
        };
        die "Failed to load Plack middleware class: ${mwclass}: ${error}" if ( $failed );

        $app = $mwclass->wrap( $app, @args );
    }

    return $app;
}

1;

package plasxom::hash;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub merge {
    my ( $self, %new ) = @_;
    my %base = %{ $self };
    my $new = plasxom::util::merge_hash( \%base, \%new );
    %{ $self } = %{ $new };
}

1;

package plasxom::api;

sub new {
    my ( $class ) = @_;
    return bless { API => {} }, $class;
}

sub register {
    my ( $self, $instance, @methods ) = @_;

    while ( my ( $method, $function ) = splice @methods, 0, 2 ) {
        Carp::croak "Method Code is not CODE reference." if ( ref $function ne 'CODE' );
        $self->{'API'}->{$method} = {
            instance => $instance,
            function => $function,
        };
    }
}

sub call {
    my ( $self, $method, @args ) = @_;
    Carp::croak "${method} is not exists." if ( ! exists $self->{'API'}->{$method} );
    my ( $instance, $function ) = @{ $self->{'API'}->{$method} }{qw( instance function )};

    return $function->( $instance, @args );
}

1;

package plasxom::template;

sub new {
    my ( $class, %args ) = @_;

    my $loader      = delete $args{'source'}    or Carp::croak "Argument 'source' is not specified.";
    my $renderer    = delete $args{'renderer'}  or Carp::croak "Argument 'renderer' is not specified.";
    my $path        = delete $args{'path'}      or Carp::croak "Argument 'path' is not specified.";

    my $self = bless {
        source      => q{},
        compiled    => undef,
        loader      => $loader,
        renderer    => $renderer,
        path        => $path,
        lastmod     => 0,
    }, $class;

    return $self;
}

sub path { $_[0]->{'path'} }

sub source {
    my $self = shift;

    if ( @_ ) {
        my $source = shift @_;
        undef($self->{'compiled'});
        $self->{'source'} = $source;
    }
    else {
        $self->load if ( ! $self->loaded );
        return $self->{'source'};
    }
}

sub compiled {
    my ( $self ) = @_;

    my $compiled = $self->{'compiled'};
    return $compiled if ( ref $compiled eq 'CODE' );

    $compiled = $self->{'renderer'}->compile( $self->source );
    $self->{'compiled'} = $compiled;

    return $compiled;
}

sub render {
    my ( $self, @args ) = @_;
    return $self->compiled->( @args );
}

sub load {
    my ( $self, %args ) = @_;
    my $reload = exists $args{'reload'} && !! $args{'reload'} ;
    return 1 if ( ! $reload && $self->loaded );

    my $loader  = $self->{'loader'};
    my $path    = $self->path;

    if ( $loader->exists( path => $path ) ) {
        $self->{'source'}   = $loader->select( path => $path );
        $self->{'lastmod'}  = $loader->stat( path => $path )->{'lastmod'};
        $self->loaded(1);
    }
    else {
        Carp::carp "Template '${path}' does not exists.";
        return;
    }
}
sub loaded {
    my $self = shift;

    if ( @_ ) {
        $self->{'loaded'} = shift @_;
    }
    else {
        return $self->{'loaded'};
    }

}

sub reload {
    my ( $self ) = @_;
    $self->load( reload => 1 );
}

sub commit {
    my ( $self ) = @_;
    my $path    = $self->path;
    my $loader  = $self->{'loader'};

    my $method  = ( $loader->exists( path => $path ) ) ? 'update' : 'create' ;
    $loader->$method( path => $path, source => $self->{'source'} );
    $self->{'lastmod'} = $loader->stat( path => $path )->{'lastmod'};

    return 1;
}

sub remove {
    my ( $self ) = @_;
    return $self->{'loader'}->remove( path => $self->path );
}

sub lastmod { $_[0]->{'lastmod'} }

sub is_modified_source {
    my ( $self ) = @_;

    my $loader  = $self->{'loader'};
    my $stat    = $loader->stat( path => $self->path );
    my $lastmod = $self->lastmod;

    return ( ! exists $stat->{'lastmod'} || $stat->{'lastmod'} != $lastmod );
}
1;

package plasxom::templates;

sub new {
    my ( $class, %args ) = @_;

    my $source      = delete $args{'source'} or Carp::croak "Argument 'source' is not specified.";
    my $renderer    = delete $args{'renderer'} or Carp::croak "Argument 'renderer' is not specified.";

    my $self = bless {
        source      => $source,
        renderer    => $renderer,
        template    => {},
    }, $class;

    return $self;
}

sub source      { $_[0]->{'source'}     }
sub renderer    { $_[0]->{'renderer'}   }
sub template    { $_[0]->{'template'}   }

sub load {
    my ( $self, $path ) = @_;

    $path =~ s{/+}{/}g;
    $path =~ s{^/*}{};

    my $template = $self->template;

    if ( ! exists $template->{$path} ) {
        $template->{$path} = plasxom::template->new( source => $self->source, renderer => $self->renderer, path => $path );
    }

    return $template->{$path};
}

sub dispatch {
    my ( $self, $path, $chunk, $flavour ) = @_;

    $path =~ s{/+}{/}g;
    $path =~ s{^/*}{};
    $path =~ s{/*$}{};

    my $source  = $self->source;

    do {
        my $full = "${path}/${chunk}.${flavour}";
           $full =~ s{^/+}{};
        if ( $source->exists( path => $full ) ) {
            return $self->load( $full );
        }
    }
    while ( $path =~ s{/*([^/]*)$}{} && $1 );

    return $self->load( "${chunk}.${flavour}" );
}

1;

package plasxom::template::source;

sub new {
    my ( $class, @args ) = @_;
    my $self = bless { config => {} }, $class;

    $self->init( @args );

    return $self;
}

sub config { $_[0]->{'config'} }

for my $method (qw( init create update select remove exists stat )) {
    no strict 'refs';
    *{$method} = sub { Carp::croak __PACKAGE__ . "::${method} is not implemented." };
}

1;

package plasxom::template::source::file;

use base qw( plasxom::template::source );

sub init {
    my ( $self, %args ) = @_;

    my $root_dir = delete $args{'root_dir'} or Carp::croak "Argument 'root_dir' is not specified.";
       $root_dir = Path::Class::dir($root_dir)->absolute->cleanup;

    $self->{'root_dir'} = $root_dir;
}

sub root_dir { $_[0]->{'root_dir'} }

sub create {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
    Carp::croak "${path} is already exists." if ( $self->exists( path => $path ) );

    return $self->update( path => $path, %args );
}

sub update {
    my ( $self, %args ) = @_;

    my $path    = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
    my $source  = delete $args{'source'} or Carp::croak "Argument 'source' is not specified.";
    my $file    = $self->root_dir->file($path);

    if ( ! -d $file->dir ) {
        $file->dir->mkpath;
    }

    my $fh = $file->openw or Carp::croak "Failed to open file: ${file}: ${!}";
    print $fh $source;
    $fh->close;

    return 1;
}

sub select {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    if ( $self->exists( path => $path ) ) {
        my $file    = $self->root_dir->file($path);
        my $fh      = $file->openr or Carp::croak "Failed to open file: $file: $!";
        my $source  = do { local $/; <$fh> };
        $fh->close;

        return $source;
    }
    return q{};
}

sub remove {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    if ( $self->exists( path => $path ) ) {
        my $file = $self->root_dir->file($path);
        return $file->remove();
    }
    else {
        Carp::carp("${path} does not exists.");
        return;
    }

}

sub exists {
    my ( $self, %args ) = @_;
    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    if ( -e $self->root_dir->file($path) && -r _ ) {
        return 1;
    }

    return 0;
}

sub stat {
    my ( $self, %args ) = @_;
    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    if ( $self->exists( path => $path ) ) {
        return { lastmod => $self->root_dir->file($path)->stat->mtime };
    }

    return { notfound => 1 };
}

1;

package plasxom::template::renderer;

sub new {
    my ( $class, @args ) = @_;
    my $self = bless { config => {} }, $class;

    $self->init( @args );

    return $self;
}

for my $method (qw( init compile )) {
    no strict 'refs';
    *{$method} = sub { __PACKAGE__ . "::${method} is not implemented." };
}

sub render {
    my ( $self, $template, @vars ) = @_;
    return $self->compile( $template )->( @vars );
}

1;

package plasxom::template::renderer::microtemplate;

use base qw( plasxom::template::renderer );

sub compile {
    my ( $self, $source ) = @_;

    my $compiled = Text::MicroTemplate::build_mt($source);

    return sub {
        my @args = @_;
        return $compiled->( @args )->as_string;
    };
}

sub raw ($) {
    my ( $str ) = shift;
    return Text::MicroTemplate::EncodedString->new($str);
}

1;

package plasxom::cache;

sub new {
    my ( $class, %args ) = @_;

    my $cache_class = delete $args{'class'} || 'plasxom::cache::memory';
    my $args  = delete $args{'args'};
    my $deref = ( !! $args{'deref'} ) ? 1 : 0 ;

    my $module_path = $cache_class . '.pm';
       $module_path =~ s{::}{/}g;

    eval { require $module_path } if ( $cache_class ne 'plasxom::cache::memory' );
    Carp::croak "Failed to load cache class: ${cache_class} => ${module_path}: $@" if ( $@ );

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

sub remove {
    my ( $self, $key ) = @_;
    return $self->{'cache'}->remove( $key );
}

1;

package plasxom::cache::memory;

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

sub remove {
    my ( $self, $key ) = @_;
    delete $self->{$key};
}

package plasxom::plugins;

sub new {
    my ( $class, %args ) = @_;

    my $dirs = delete $args{'search_dirs'} or die "Argument 'search_dirs' is not specified.";
    my $state = delete $args{'state_dir'} or die "Argument 'state_dir' is not specified";
    my $order = delete $args{'order'};

    Carp::croak "Plugin order is not ARRAY reference." if ( ref $order ne 'ARRAY' );

    $dirs = [ $dirs ] if ( ref $dirs ne 'ARRAY' );

    my @plugin_dirs = ();
    for my $dir ( @{ $dirs } ) {
        push @plugin_dirs, Path::Class::Dir->new( $dir );
    }
    my $state_dir   = Path::Class::Dir->new($state);

    my $self = bless {
        search_dirs => [ @plugin_dirs ],
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
        my ( $module, $config ) = @{ $order }{qw( plugin config )};

        my $package = $module;
           $package = "plasxom::plugin::${package}" if ( $package !~ m{^plasxom::plugin} );

        for my $dir ( @{ $self->search_dirs } ) {
            my $path = "${dir}/${module}";

            if ( -e $path && -r _ ) {
                eval { require $path };

                Carp::croak "Failed to load plugin: ${package}: ${path}: ${@}" if ( $@ );
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

package plasxom::plugin;

use Carp ();

sub new {
    my ( $class, %args ) = @_;

    my $config = delete $args{'config'} || {};
    my $state  = delete $args{'state'} or Carp::croak "Argument 'state' is not specified.";

    my $self = bless {
        config => $config,
        state  => $state,
    }, $class;

    $self->init;

    return $self;
}

sub config  { $_[0]->{'config'} }
sub state   { $_[0]->{'state'}  }

sub init  { 1 }
sub setup { 1 }
sub start { 1 }

package plasxom::entries;

sub new {
    my ( $class, %args ) = @_;

    my $schema = delete $args{'schema'} or Carp::croak "Argument 'schema' is not specified.";
    my $num    = delete $args{'num_entries'} || 5;
    my $hide   = delete $args{'hide_from_index'} || [];
    Carp::croak "Argument 'hide_from_index' is not ARRAY reference." if ( ref $hide ne 'ARRAY' );

    my %config = %args;
    my $db = $schema->new( %config );

    Carp::croak "Argument 'num_entries' is not number" if ( $num !~ m{^\d+$} );

    my $self = bless {
        db          => $db,
        index       => [],
        all         => [],
        filtered    => [],
        config      => {
            num_entries => $num,
            hide        => $hide,
        },
        flag        => {
            indexed => 0,
        },
    }, $class;
    return $self;
}

sub db { $_[0]->{'db'} }

sub indexed_all {
    my $self = shift;

    if ( @_ ) {
        $self->{'flag'}->{'indexed_all'} = shift @_;
    }
    else {
        return $self->{'flag'}->{'indexed_all'};
    }
}

sub indexed {
    my $self = shift;

    if ( @_ ) {
        $self->{'flag'}->{'indexed'} = shift @_;
    }
    else {
        return $self->{'flag'}->{'indexed'};
    }
}

sub num_entries {
    my $self = shift;

    if ( @_ ) {
        my $num = shift @_;
        Carp::croak "Argument is not number" if ( $num !~ m{^\d+$} );
        $self->{'config'}->{'num_entries'} = $num;
    }
    else {
        return $self->{'config'}->{'num_entries'};
    }
}

sub filtered {
    my $self = shift;

    if ( @_ ) {
        my $list = shift @_;
        Carp::croak "Argument is not ARRAY reference." if ( ref $list ne 'ARRAY' );
        $self->{'filtered'} = $list;
    }
    else {
        return $self->{'filtered'};
    }
}

sub all {
    my ( $self ) = @_;
    return $self->{'all'} if ( $self->indexed_all );

    my @index = ();
    my %entries = $self->db->index();

    for my $path ( keys %entries ) {
        my $entry = plasxom::entry->new(
            db      => $self->db,
            path    => $path,
            %{ $entries{$path} },
        );
        push @index, $entry;
    }

    @index = sort { $a->{'path'}->{'fullpath'} cmp $b->{'path'}->{'fullpath'} } @index;

    $self->{'all'} = \@index;
    $self->indexed_all(1);

    return $self->{'all'};
}

sub index {
    my ( $self ) = @_;
    return $self->{'index'} if ( $self->indexed );

    my $hide  = $self->{'config'}->{'hide'};
    my @index = ();

    for my $entry ( @{ $self->all } ) {
        my $fullpath = $entry->{'path'}->{'fullpath'};
        next if ( grep { $fullpath =~ $_ } @{ $hide } );
        push @index, $entry;
    }

    $self->{'index'} = [ @index ];
    $self->indexed(1);

    return $self->{'index'};
}

sub reindex_all {
    my ( $self ) = @_;

    $self->indexed_all(0);
    return $self->all;
}

sub reindex {
    my ( $self ) = @_;
    $self->indexed(0);
    return $self->index;
}

sub exists {
    my ( $self, %args ) = @_;
    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    return $self->db->exists( path => $path );
}

sub entry {
    my ( $self, %args ) = @_;
    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";

    if ( $self->exists( path => $path ) && ref( my $entry = ( grep { $_->{'path'}->{'fullpath'} eq $path } @{ $self->all } )[0] ) eq 'plasxom::entry' ) {
        return $entry;
    }
    else {
        return plasxom::entry->new(
            path    => $path,
            db      => $self->db,
            created => time(),
        );
    }
}

sub filter {
    my ( $self, %args ) = @_;

    my $path        = delete $args{'path'};
       $path        = q{} if ( ! defined $path );
    my $filename    = delete $args{'filename'};
       $filename    = q{} if ( ! defined $filename );
    my $page        = delete $args{'pagename'};
       $page        = q{} if ( ! defined $page );

    my %datetime;
    for my $prop ( qw( year month day hour minute second ) ) {
        if ( exists $args{$prop} ) {
            my $value = delete $args{$prop};
            Carp::croak "Argument '$prop' is not number: $value" if ( $value !~ m{^\d+$} );
            $datetime{$prop} = $value;
        }
    }

    my $meta    = delete $args{'meta'} || {};
    Carp::croak "Argument 'meta' is not HASH reference." if ( ref $meta ne 'HASH' );

    my $stash   = delete $args{'stash'} || {};
    Carp::croak "Argument 'stash' is not HASH reference." if ( ref $stash ne 'HASH' );

    my $tag     = delete $args{'tag'};
    Carp::croak "Argument 'tag' is not HASH reference." if ( defined $tag && ref $tag ne 'HASH' );

    my %text = ();
    for my $prop ( qw( title body summary ) ) {
        if ( exists $args{$prop} ) {
            my $value = delete $args{$prop};
            Carp::croak "Argument '$prop' is not HASH reference." if ( ref $value ne 'HASH' );
            $text{$prop} = $value;
        }
    }

    my $sortp   = delete $args{'sort'} || 'created';
    Carp::croak "Argument 'sort' is not CODE reference or plasxom::entry->property" if ( ref $sortp && ! ref $sortp ne 'CODE' );
    Carp::croak "Argument 'sort' is not plasxom::entry property: $sortp" if ( ! ref $sortp && ! plasxom::entry->can($sortp) );
    my $sortsub;
    if ( ref $sortp eq 'CODE' ) {
        $sortsub = $sortp;
    }
    else {
        $sortsub = sub { $_[1]->$sortp cmp $_[0]->$sortp };
    }

    # prepare
    my $index   = $self->index;
    my %new     = ();

    # filter path
    $path =~ s{/+}{/}g;
    $path =~ s{^/*}{};
    $path = quotemeta($path);

    for my $entry ( @{ $index } ) {
        my $fn = $entry->{'path'}->{'fullpath'};
        if ( $fn =~ m{^$path} ) {
            $new{$fn} = $entry;
        }
    }

    # filter filename
    $filename =~ s{/}{}g;
    $filename = quotemeta($filename);
    for my $fn ( keys %new ) {
        if ( $new{$fn}->{'path'}->{'filename'} !~ m{$filename} ) {
            delete $new{$fn};
        }
    }

    # filter pagename
    if ( $page ne q{} ) {
        for my $fn ( keys %new ) {
            if ( $new{$fn}->pagename ne $page ) {
                delete $new{$fn};
            }
        }
    }

    # filter date
    if ( %datetime ) {
        for my $fn ( keys %new ) {
            my $entry   = $new{$fn};
            my $date    = $entry->date;
            for my $prop ( keys %datetime ) {
                my $target = $date->$prop;
                if ( $target != $datetime{$prop} ) {
                    delete $new{$fn};
                }
            }
        }
    
    }

    # filter meta and stash
    if ( scalar( keys %{ $meta } ) || scalar( keys %{ $stash } ) ) {
        for my $name ( qw( meta stash ) ) {
            my $target = ( $name eq 'meta' ) ? $meta : $stash ;
            if ( scalar( keys %{ $target } ) ) {
                for my $key ( sort keys %{ $target } ) {
                    my $value = $target->{$key};
                    Carp::croak "Argument '${name}->{${key}}' does not set compare value." if ( ! defined $value );
                    FILES: for my $fn ( keys %new ) {
                        my $targetdata = $new{$fn}->$name->{$key};
                        if ( ! defined $targetdata ) {
                            delete $new{$fn};
                            next FILES;
                        }

                        if ( ref $value eq 'Regexp' ) {
                            delete $new{$fn} if ( $targetdata !~ $value );
                        }
                        else {
                            delete $new{$fn} if ( $targetdata ne $value );
                        }
                    }
                }
            }
        }
    }

    # filter tag
    if ( defined $tag && ref $tag eq 'HASH' ) {
        my $words = $tag->{'words'} || [];
           $words = [ $words ] if ( ref $words ne 'ARRAY' );
        Carp::croak "Argument 'tag'->{'words'} is empty." if ( @{ $words } == 0 );
        my $op    = $tag->{'op'} || 'AND';
        Carp::croak "Unknown tag search operation: $op" if ( $op ne 'AND' && $op ne 'OR' );

        ENTRIES: for my $fn ( keys %new ) {
            my $tags = $new{$fn}->tags || [];
            WORDS: for my $word ( @{ $words } ) {
                for my $tag ( @{ $tags } ) {
                    if ( $word eq $tag ) {
                        next WORDS      if ( $op eq 'AND' );
                        next ENTRIES    if ( $op eq 'OR' );
                    }
                }
                delete $new{$fn} if ( $op eq 'AND' );
            }
            delete $new{$fn} if ( $op eq 'OR' );
        }

    }

    # filter text property
    if ( %text ) {
        for my $prop ( sort keys %text ) {
            my $conf = $text{$prop};
            my $op   = $conf->{'op'} || 'AND';
            Carp::croak "Unknown $prop search opeartion: $op" if ( $op ne 'AND' && $op ne 'OR' );
            my $words = $conf->{'words'} || [];
               $words = [ $words ] if ( ref $words ne 'ARRAY' );
            Carp::croak "Argument '$prop'->{'words'} is empty" if ( @{ $words } == 0 );
            my $filter = sub { return $_[0] };
               $filter = $conf->{'filter'} if ( exists $conf->{'filter'} );
            Carp::croak "Argument '$prop'->{'filter'} is not CODE reference." if ( ref $filter ne 'CODE' );

            ENTRIES: for my $fn ( keys %new ) {
                my $target = $new{$fn}->$prop;
                   $target = $filter->( $target );
                WORDS: for my $word ( @{ $words } ) {
                    $word = quotemeta($word);
                    if ( $target =~ m{$word} ) {
                        next WORDS      if ( $op eq 'AND'   );
                        next ENTRIES    if ( $op eq 'OR'    );
                    }
                    delete $new{$fn} if ( $op eq 'AND' );
                }
                delete $new{$fn} if ( $op eq 'OR' );
            }
        }
    }

    # sort
    my @sorted = sort { $sortsub->( $a, $b ) } map { $new{$_} } sort keys %new;

    return @sorted;
}

sub pagiante {
    my ( $self, %args ) = @_;

    my $page = delete $args{'page'} || 1 ;
    Carp::croak "Argument 'page' is not number: $page" if ( $page !~ m{^\d+$} );

    my $num_entries = delete $args{'num_entries'};
       $num_entries ||= $self->num_entries || 5;
    Carp::croak "Argument 'num_entries' is not number: $num_entries" if ( $num_entries !~ m{^\d+$} );

    my @filtered = $self->filter( %args );

    my $max     = scalar( @filtered ) - 1;
    my $from    = $num_entries * ( $page - 1 );
    my $to      = $from + ( $num_entries - 1 );

    return () if ( $from > $max );

    $to = $max if ( $to > $max );

    return @filtered[ $from .. $to ];
}

sub total_page {
    my ( $self, %args ) = @_;

    my $page = delete $args{'page'} || 1 ;
    Carp::croak "Argument 'page' is not number: $page" if ( $page !~ m{^\d+$} );

    my $num_entries = delete $args{'num_entries'};
       $num_entries ||= $self->num_entries || 5;
    Carp::croak "Argument 'num_entries' is not number: $num_entries" if ( $num_entries !~ m{^\d+$} );

    my @filtered = $self->filter( %args );

    my $max = scalar( @filtered );

    my $total = $max / $num_entries;
       $total = int( $total + 1 ) if ( $total !~ m{^\d+$} );

    return $total;
}

1;

package plasxom::entries::base;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { config => {} }, $class;

    $self->init( %args );

    return $self;
}

sub config { $_[0]->{'config'} }
sub init   { Carp::croak __PACKAGE__ . "::init is not implemented." }

for my $method (qw( create update select remove exists index stat )) {
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

package plasxom::entries::blosxom;

use base qw( plasxom::entries::base );

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

    my $dateparser      = delete $args{'meta_date_parser'}      || plasxom::util->can('parse_date');
    my $dateformatter   = delete $args{'meta_date_formatter'}   || plasxom::util->can('format_date');

    my $tagparser       = delete $args{'meta_tag_parser'}       || plasxom::util->can('parse_tags');
    my $tagformatter    = delete $args{'meta_tag_formatter'}    || plasxom::util->can('format_tags');

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
        Carp::croak "Cache object is not plasxom::cache instance." if ( ref $cache ne 'plasxom::cache' );

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

    my $auto_update = delete $args{'auto_update'};
       $auto_update = !! $auto_update;

    $self->{'config'}->{'auto_update'} = $auto_update;

    my $readonly    = delete $args{'readonly'};
       $readonly    = !! $readonly;

    $self->{'config'}->{'readonly'} = $readonly;
}

sub entries_dir     { $_[0]->{'config'}->{'entries_dir'}    }
sub file_extension  { $_[0]->{'config'}->{'file_extension'} }
sub depth           { $_[0]->{'config'}->{'depth'}          }
sub use_cache       { $_[0]->{'config'}->{'use_cache'}      }
sub use_index       { $_[0]->{'config'}->{'use_index'}      }
sub auto_update     { $_[0]->{'config'}->{'auto_update'}    }
sub readonly        { $_[0]->{'config'}->{'readonly'}       }

my %path_cache = ();
sub entry_path {
    my ( $self, $opath ) = @_;

    if ( exists $path_cache{$opath} ) {
        return $path_cache{$opath};
    }

    my $path = $opath;
    $path =~ s{/+}{/}g;
    $path =~ s{^/*}{};
    $path =~ s{/*$}{};

    $path_cache{$opath} = $path;

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

    if ( $self->readonly ) {
        Carp::carp "Entries are readonly.";
        return;
    }

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
            my $data = $cache->get("plasxom-entries-blosxom:${path}");
            if ( defined $data && $data->{'lastmod'} == File::stat::stat( $file )->mtime ) {
                return %{ $data };
            }
        }

        my $fh = $file->openr or Carp::croak "Failed to open file: $file: $!";
        my $source = do { local $/; <$fh> };
        $fh->close;

        my %data = $self->parse( $source );
           $data{'lastmod'} = File::stat::stat($file)->mtime;

        my $updated = 0;
        if ( ! exists $data{'created'}  ) {
            $data{'created'} = $data{'lastmod'};
            $updated++;
        }

        if ( ! $self->readonly && $updated && $self->auto_update ) {
            $self->update( path => $path, %data );
        }

        $cache->set( "plasxom-entries-blosxom:${path}" => \%data ) if ( $use_cache );

        return %data;
    }

    return ();
}

sub remove {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);

    if ( $self->exists( path => $path ) ) {
        if ( $self->use_cache ) {
            $self->{'cache'}->remove("plasxom-entries-blosxom:${path}");
        }
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
    my $entries_dir = $self->entries_dir;
    my $file_depth  = ( $path =~ tr{/}{} ) + 1;

    if ( ( ! $depth || $depth && $file_depth <= $depth ) && -e "${entries_dir}/${path}" && -r _ ) {
        return 1;
    }

    return 0;
}

sub stat {
    my ( $self, %args ) = @_;

    my $path = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
       $path = $self->entry_path($path);

    if ( $self->exists( path => $path ) ) {
        return { lastmod => $self->entries_dir->file("${path}." . $self->file_extension)->stat->mtime },
    }

    return { notfound => 1 };
}

sub index  {
    my ( $self ) = @_;

    my $use_index   = $self->use_index;
    my $index_file  = $self->{'index'};

    my $root        = $self->entries_dir->as_foreign('Unix')->stringify;

    my %index       = ();
    my %new         = ();

    if ( $use_index && -e $index_file && -r _ ) {
        my $data = eval { do $index_file->stringify } || {};
        Carp::croak "Failed to load index file: $index_file: $@" if ( $@ );
        %index = %{ $data };
    }

    my $depth = $self->depth;
    my $fe    = $self->file_extension;

    File::Find::find(
        sub {
            my $file = $File::Find::name;

            return if ( -d $file || ! -r $file || $file !~ m{\.$fe$} );

            my $path = $file;
               $path =~ s{^$root/}{};
               $path =~ s{\.$fe$}{};

            my $file_depth = ( $path =~ tr{/}{} ) + 1;

            if ( $depth && $file_depth > $depth ) {
                return;
            }

            my $mtime = File::stat::stat($file)->mtime;

            if ( ! exists $index{$path} || $index{$path}->{'lastmod'} != $mtime ) {
                my %data = $self->select( path => $path );
                delete $data{'body_source'};
                delete $data{'summary_source'};
                $new{$path} = {
                    %data,
                    lastmod => $mtime,
                };
            }
            else {
                $new{$path} = $index{$path};
            }
        },
        $root,
    );

    if ( $use_index ) {
        local $Data::Dumper::Terse = 1;
        my $data = Data::Dumper::Dumper( \%new );

        if ( ! -d $index_file->dir ) {
            $index_file->dir->mkpath;
        }

        my $fh = $index_file->openw or Carp::croak "Failed to open index file: $index_file: $!";
        print $fh $data;
        $fh->close;
    }

    return %new;
}

sub parse {
    my ( $self, $text ) = @_;
    my @lines = split m{\n}, $text;
    my %data = (
        meta => {},
        tags => [],
    );

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
                $meta{$key} = $value;
            }
            elsif ( $prop eq 'tags' ) {
                my $tags = $value;
                Carp::croak "Argument 'tags' is not ARRAy reference." if ( ref $tags ne 'ARRAY' );
                $value = $tagformatter->( @{ $tags } );
                $meta{$key} = $value if ( @{ $tags } > 0 );
            }
            else {
                $meta{$key} = $value;
            }
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

package plasxom::date;

our %month2num = (  nil => '00', Jan => '01', Feb => '02', Mar => '03',
                    Apr => '04', May => '05', Jun => '06', Jul => '07',
                    Aug => '08', Sep => '09', Oct => '10', Nov => '11', Dec => '12' );

our @num2month = sort { $month2num{$a} <=> $month2num{$b} } keys %month2num;

our @fullmonth = qw( nil January February March April May June July
                     August September October November December );

my %cache;

sub new {
    my ( $class, %args ) = @_;
    my $epoch = delete $args{'epoch'} or Carp::croak "Argument 'epoch' is not specified.";

    if ( exists $cache{$epoch} ) {
        return $cache{$epoch};
    }

    my $ctime = Time::localtime::ctime($epoch);
    my ( $dw, $mo, $da, $hr, $min, $sec, $yr )
        = ( $ctime =~ m{(\w{3})[ ]+(\w{3})[ ]+(\d{1,2})[ ]+(\d{2}):(\d{2}):(\d{2})[ ]+(\d{4})$} );
    $da = sprintf('%02d', $da);
    my $mo_num = $month2num{$mo};

    my $self = bless {
        epoch       => $epoch,
        year        => $yr,
        month       => $mo_num,
        shortmonth  => $mo,
        fullmonth   => $fullmonth[$mo_num],
        day         => $da,
        hour        => $hr,
        minute      => $min,
        second      => $sec,
        dayweek     => $dw,
    }, $class;

    $cache{$epoch} = $self;
    return $self;
}

sub epoch       { $_[0]->{'epoch'}      }
sub year        { $_[0]->{'year'}       }
sub month       { $_[0]->{'month'}      }
sub shortmonth  { $_[0]->{'shortmonth'} }
sub fullmonth   { $_[0]->{'fullmonth'}  }
sub day         { $_[0]->{'day'}        }
sub hour        { $_[0]->{'hour'}       }
sub minute      { $_[0]->{'minute'}     }
sub second      { $_[0]->{'second'}     }
sub dayweek     { $_[0]->{'dayweek'}    }

sub ymd {
    my ( $self ) = @_;
    my ( $yr, $mo, $da ) = @{ $self }{qw( year month day )};
    return "${yr}-${mo}-${da}";
}

sub time {
    my ( $self ) = @_;
    my ( $hr, $min, $sec ) = @{ $self }{qw( hour minute second )};
    return "${hr}:${min}:${sec}";
}

1;

package plasxom::entry;

sub new {
    my ( $class, %args ) = @_;

    my $fullpath = delete $args{'path'} or Carp::croak "Argument 'path' is not specified.";
    my $db       = delete $args{'db'}   or Carp::croak "Argument 'db' is not specified.";

    my ( $path, $fn );
    if ( $fullpath =~ m{^(?:(.*)/)?(.+)$} ) {
        $path           = $1 || q{};
        $fn             = $2 || q{};
    }
    else {
        Carp::croak "Invalid path: ${fullpath}";
    }

    my $stash = delete $args{'stash'} || {};
    Carp::croak "Argument 'stash' is not HASH reference." if ( ref $stash ne 'HASH' );

    my $self = bless {
        path        => {
            path            => $path,
            filename        => $fn,
            fullpath        => $fullpath,
        },
        property    => { %args },
        stash       => { %{ $stash } },
        flag        => {
            loaded => 0,
        },
        db          => $db,
        formatter   => [],
    }, $class;

}

for my $prop (qw( title body_source summary_source permalink pagename created lastmod tags meta )) {
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
                my $source      = "${prop}_source";
                my $body        = $self->$source;
                my $formatters  = $self->formatter || [];

                FORMAT: for my $stash ( @{ $formatters } ) {
                    my ( $instance, $method, $handle ) = @{ $stash }{qw( formatter method handle )};
                    if ( $instance->$handle( $self, $prop ) ) {
                        $body = $instance->$method( $self, $prop );
                        last FORMAT;
                    }
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
    $self->{'formatter'} = [];
    $self->{'stash'}     = {};

    return 1;
}

sub register_formatter {
    my ( $self, $formatter, $method, $handle ) = @_;

    Carp::croak "formatter is not specified." if ( ! defined $formatter );
    Carp::croak "formatter method is not specified." if ( ! defined $method );
    Carp::croak "formatter handler is not specified." if ( ! defined $handle );

    $self->{'formatter'} ||= [];
    push @{ $self->{'formatter'} }, +{
        formatter   => $formatter,
        method      => $method,
        handle      => $handle,
    };
}

sub clear_formatter {
    my ( $self ) = @_;

    $self->{'formatter'} = [];
}

sub formatter { $_[0]->{'formatter'} };

sub loaded {
    my $self = shift;

    if ( @_ ) {
        $self->{'flag'}->{'loaded'} = shift @_;
    }
    else {
        return $self->{'flag'}->{'loaded'};
    }

}

sub stash { $_[0]->{'stash'} }

sub date {
    my ( $self ) = @_;
    return plasxom::date->new( epoch => $self->created, );
}

sub path        { $_[0]->{'path'}->{'path'}     }
sub filename    { $_[0]->{'path'}->{'filename'} }
sub fullpath    { $_[0]->{'path'}->{'fullpath'} }
sub db          { $_[0]->{'db'} }

sub load {
    my ( $self, %args ) = @_;

    my $path = $self->{'path'}->{'fullpath'};
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
}

sub reload {
    my ( $self ) = @_;
    return $self->load( reload => 1 );
}

sub commit {
    my ( $self ) = @_;

    my $path = $self->{'path'}->{'fullpath'};
    if ( defined( my $ret = $self->db->create_or_update( path => $path, %{ $self->{'property'} } ) ) ) {
        my $stat = $self->db->stat( path => $path );
        $self->lastmod( $stat->{'lastmod'} ) if ( exists $stat->{'lastmod'} );
        return $ret;
    }
    return;
}

sub is_modified_source {
    my ( $self ) = @_;

    if ( $self->db->exists( path => $self->{'path'}->{'fullpath'} ) ) {
        my $lastmod = $self->lastmod;
        my $stat    = $self->db->stat( path => $self->{'path'}->{'fullpath'} );
        if ( ! exists $stat->{'lastmod'} || $stat->{'lastmod'} != $lastmod ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif ( !! $self->loaded ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub remove {
    my ( $self ) = @_;
    return $self->db->remove( path => $self->{'path'}->{'fullpath'} );
}

1;

package plasxom::flavour;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { meta => {}, stash => {}, tags => [] }, $class;

    for my $prop ( keys %args ) {
        my $value = $args{$prop};
        Carp::croak "Unknown flavour property: ${prop} => ${value}" if ( ! $self->can($prop) );
        $self->$prop( $value );
    }

    return $self;
}

for my $prop (qw( year month day flavour tags meta no_matched pagename tag_op page stash path_info )) {
    no strict 'refs';
    *{$prop} = sub {
        my $self = shift;
        if ( @_ ) {
            $self->{$prop} = shift @_;
        }
        else {
            return $self->{$prop};
        }
    }
}

sub url {
    my $self = shift;

    if ( @_ ) {
        my $url = shift @_;
           $url =~ s{/*$}{};
        $self->{'url'} = $url;
    }
    else {
        return $self->{'url'};
    }
}

sub path {
    my $self = shift;

    if ( @_ ) {
        my $path = shift @_;
           $path =~ s{/+}{/}g;
           $path =~ s{^/*}{};
           $path =~ s{/*$}{};
        $self->{'path'} = $path;
    }
    else {
        return $self->{'path'};
    }
}

sub filename {
    my $self = shift;

    if ( @_ ) {
        my $filename = shift @_;
           $filename =~ s{^/*}{};
        $self->{'filename'} = $filename;
    }
    else {
        return $self->{'filename'};
    }
}

sub fullpath {
    my $self = shift;

    my $path        = $self->path       || q{};
    my $filename    = $self->filename   || q{};
    my $flavour     = $self->flavour    || q{};

       $filename  &&= "/${filename}";
       $flavour   &&= ".${flavour}";
       $filename  &&= "${filename}${flavour}";

    return "${path}${filename}";
}

1;

package plasxom::dispatcher;

sub new {
    my ( $class, %args ) = @_;

    my $regexp  = delete $args{'regexp'} || {};
    my $rule    = delete $args{'rule'} or Carp::croak "dispatch rule is not specified.";
    Carp::croak "Argument 'rule' is not ARRAY reference." if ( ref $rule ne 'ARRAY' );

    my $compiled = $class->compile_rule( $rule, $regexp );

    my $self = bless { rules => $compiled }, $class;

    return $self;
}

sub compile_rule {
    my ( $class, $rules, $user_regexp ) = @_;

    my $regexp = plasxom::hash->new(
        year        => qr{(\d{4})},
        month       => qr{(\d{2})},
        day         => qr{(\d{1,2})},
        path        => qr{((?:[^/]+?/)*)},
        filename    => qr{([^/]+?)},
        flavour     => qr{([a-zA-Z0-9_\-]+)},
    );

    for my $key ( keys %{ $user_regexp || {} } ) {
        my $value = $user_regexp->{$key};
        Carp::croak "regexp->$key is not Regexp" if ( ref $value && ref $value ne 'Regexp' );
        $regexp->merge( $key => $value );
    }

    for ( my $i = 0; $i < @{ $rules }; $i++ ) {
        my $rule = $rules->[$i];
        my $path = $rule->{'path'};

        Carp::croak "rule->[$i]->{'path'} is not specified." if ( ! defined $path );

        my @capture = ();
        $path =~ s/[{]([a-zA-Z0-9_\-.]+?)[}]/
            my $match = $1;
            if ( $match =~ m{^meta[.]} || $match =~ m{^stash[.]} || plasxom::flavour->can($match) ) {
                push @capture, $match;
                $regexp->{$match};
            }
            else {
                Carp::croak "'$match' is not plasxom::flavour property.";
            }
        /ge;

        for my $key ( keys %{ $rule->{'flavour'} || {} } ) {
            if ( ! $key =~ m{^meta[.]} && ! $key =~ m{^stash[.]} && ! plasxom::flavour->can($key) ) {
                Carp::croak "'$key' is not plasxom::flavour property.";
            }
        }

        $rule->{'path'}      = qr{$path};
        $rule->{'capture'} ||= [ @capture ];
    }

    return $rules;
}

sub rules { $_[0]->{'rules'} }

sub dispatch {
    my ( $self, $req ) = @_;

    my $flavour     = plasxom::flavour->new;
    my $path_info   = $req->path_info || q{};
    my $uri         = $req->uri;

    $path_info      =~ s{%([0-9A-Fa-f][0-9A-Fa-f])}{pack('H2', $1)}eg;

    # url
    my $url = q{};
       $url .= $req->env->{'psgi.url_scheme'} || 'http';
       $url .= '://' . $uri->host;
       $url .= $uri->path;

    my $len = length($path_info);
    my $frg = substr( $url, -$len );
    substr( $url, -$len ) = q{} if ( $frg eq $path_info );

    $flavour->url( $url );

    # path_info
    my $script = $req->env->{'SCRIPT_NAME'} || q{};
       $path_info =~ s{$script}{};
    $flavour->path_info( $path_info );

    # path
    RULES: for my $rule ( @{ $self->rules } ) {
        my ( $regexp, $capture, $flav, $condition, $hook )
            = @{ $rule }{qw( path capture flavour condition after_hook )};


        # condition
        if ( defined $condition && ref $condition eq 'HASH' ) {
            my ( $method, $function ) = @{ $condition }{qw( method function )};
            $method = [ $method ] if ( ref $method ne 'ARRAY' );

            next RULES if ( @{ $method } && ! grep { $req->method eq uc $_ } @{ $method } );
            next RULES if ( ref $function eq 'CODE' && ! $function->( $req ) );
        }

        # path
        if ( my @matched = ( $path_info =~ $regexp ) ) {
            my %matched = ();
            @matched{@{ $capture || [] }} = @matched;

            for my $key ( keys %matched ) {
                if ( $key =~ m{^meta[.](.+)} ) {
                    $flavour->meta->{$1} = $matched{$key};
                }
                elsif ( $key =~ m{^stash[.](.+)} ) {
                    $flavour->stash->{$1} = $matched{$key};
                }
                else {
                    $flavour->$key( $matched{$key} );
                }
            }

            # merge flav
            for my $prop ( keys %{ $flav || {} } ) {
                if ( $prop =~ m{^meta[.](.+)} ) {
                    $flavour->meta->{$1} = $flav->{$prop};
                }
                elsif ( $prop =~ m{^stash[.](.+)} ) {
                    $flavour->stash->{$1} = $flav->{$prop};
                }
                else {
                    $flavour->$prop( $flav->{$prop} );
                }
            }

            # after hook
            if ( ref $hook eq 'CODE' ) {
                $hook->( $req, $flavour );
            }

            return $flavour;
        }
    }

    $flavour->no_matched(1);

    return $flavour;
}

package plasxom::util;

sub env_value {
    my ( $key ) = @_;

    my $prefix  = uc 'plasxom';
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

    my $tags = eval $str || [];
    Carp::carp "Tag Parse error: $str: $@" if ( $@ );

    return @{ $tags };
}

sub format_tags {
    my ( @tags ) = @_;

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse  = 1;
    my $str = Data::Dumper::Dumper([ @tags ]);

    return $str;
}

1;

package main;

return plasxom->application if ( ! plasxom::util::env_value('libmode') );

1;

package plasxom;
__END__

=head1 NAME

plasxom - Plack based blosxom clone

=head1 SYNPOSIS

    
    ## work dir
    $ mkdir work
    $ cd work
    
    ## setup plasxom
    $ git clone git://github.com/nyarla/plasxom.git plasxom
    $ cd plasxom
    $ perl Makefile.PL
    $ make && make test
    $ cd ..

    ## write configuration file
    $ touch config.pl
    $ vi config.pl

    ## specifiying config file
    $ export PLASXOM_CONFIG=/path/to/work/config.pl

    ## run plasxom
    plackup --app ./plasxom/plasxom.psgi

=head1 SITES

    github:                     http://github.com/nyarla/plasxom
    nyarla's blog (Japanese):   http://blog.nyarla.net/, http://diary.nyarla.net

=head1 AUTHOR

Naoki Okamura (Nyarla) E<lt>nyarla[:)]thotep.netE<gt>

=head1 SEE ALSO

L<Plack>, L<PSGI>

=head1 LICENSE

Copyright (c) 2009 Naoki Okamura (Nyarla) E<lt>nyarla[:)]thotep.netE<gt>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
