package t::Util;

use strict;
use warnings;

use FindBin ();
use Path::Class;
use base qw( Exporter );

our ( $basedir, $plugindir, $script, $example );

our @EXPORT_OK = qw(
    $basedir $plugindir $script $example
    require_plasxom require_plugin
);

{
    my @path = dir($FindBin::Bin)->dir_list;
    while ( my $dir = pop @path ) {
        if ( $dir eq 't' ) {
            $basedir    = dir(@path);
            $script     = $basedir->file('plasxom.psgi');
            $plugindir  = $basedir->subdir('plugins');
            $example    = $basedir->subdir('t', 'examples');
            last;
        }
    }
}

sub require_plasxom {
    local $ENV{'PLASXOM_LIBMODE'} = 1;
    require $script;
}

sub require_plugin {
    my $plugin = shift or die "plugin name is not specified.";

    require $plugindir->file($plugin);
}

1;