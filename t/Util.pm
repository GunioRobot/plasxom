package t::Util;

use strict;
use warnings;

use FindBin ();
use Path::Class;
use base qw( Exporter );

our ( $basedir, $plugindir, $script, $example );

our @EXPORT_OK = qw(
    $basedir $plugindir $script $example
    require_hlosxom require_plugin
);

{
    my @path = dir($FindBin::Bin)->dir_list;
    while ( my $dir = pop @path ) {
        if ( $dir eq 't' ) {
            $basedir    = dir(@path);
            $script     = $basedir->file('hlosxom.pl');
            $plugindir  = $basedir->subdir('plugins');
            $example    = $basedir->subdir('t', 'examples');
            last;
        }
    }
}

sub require_hlosxom {
    local $ENV{'HLOSXOM_BOOTSTRAP'} = 0;
    local $ENV{'HLOSXOM_PSGI'}      = 0;
    require $script;
}

sub require_plugin {
    my $plugin = shift or die "plugin name is not specified.";

    require $plugindir->file($plugin);
}

1;