#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 1;

require_plasxom;

can_ok(
    'plasxom::template::source',
    qw( new init create update select remove exists stat ),
);