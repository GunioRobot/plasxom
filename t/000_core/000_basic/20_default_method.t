#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 6;

require_plasxom;

# default config

isa_ok( plasxom->config, 'plasxom::hash' );

# default vars

isa_ok( plasxom->vars, 'plasxom::hash' );

# default api

isa_ok( plasxom->api, 'plasxom::api' );

# default entries schema class;

is( plasxom->entries_schema_class, 'plasxom::entries::blosxom' );

# default template classes

is( plasxom->template_source_class, 'plasxom::template::source::file' );
is( plasxom->template_renderer_class, 'plasxom::template::renderer::microtemplate' );
