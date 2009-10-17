package t::Util;

use strict;
use warnings;

use FindBin ();
use Path::Class;
use base qw( Exporter );

our ( $basedir, $script, $example );

our @EXPORT_OK = qw(
    $basedir $script $example
    require_hlosxom
);

{
    my @path = dir($FindBin::Bin)->dir_list;
    while ( my $dir = pop @path ) {
        if ( $dir eq 't' ) {
            $basedir = dir(@path);
            $script  = $basedir->file('hlosxom.pl');
            $example = $basedir->subdir('t', 'examples');
            last;
        }
    }
}

sub require_hlosxom {
    local $ENV{'HLOSXOM_BOOTSTRAP'} = 0;
    local $ENV{'HLOSXOM_PSGI'}      = 0;
    require $script;
}

1;