#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom );
use Test::More tests => 2;

require_plasxom;

plasxom->config( plasxom::hash->new( cache => {} ) );

plasxom->setup_cache;

isa_ok( plasxom->cache, 'plasxom::cache' );

isa_ok( plasxom->cache->{'cache'}, 'plasxom::cache::memory' );
