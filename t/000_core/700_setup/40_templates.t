#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom $example );
use Test::More tests => 4;

require_plasxom;

plasxom->config->merge(
    template => {
        renderer    => {  },
        source      => { root_dir => $example->subdir('core/template/flavours') },
    },
);

plasxom->setup_templates;

isa_ok( plasxom->templates, 'plasxom::templates' );

isa_ok( plasxom->templates->source, 'plasxom::template::source::file' );
is( plasxom->templates->source->root_dir, $example->subdir('core/template/flavours') );

isa_ok( plasxom->templates->renderer, 'plasxom::template::renderer::microtemplate' );
