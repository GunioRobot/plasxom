#!perl

use strict;
use warnings;

use t::Util qw( require_hlosxom );
use Test::More tests => 2;

require_hlosxom;

hlosxom->config( hlosxom::config->new( cache => {} ) );

hlosxom->setup_cache;

isa_ok( hlosxom->cache, 'hlosxom::cache' );

isa_ok( hlosxom->cache->{'cache'}, 'hlosxom::cache::memory' );
