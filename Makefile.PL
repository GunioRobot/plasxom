#!perl

use strict;
use warnings;
use inc::Modle::Install;

name 'hlosxom';
all_from 'hlosxom.pl';

requires 'Path::Class';
requires 'Carp';
requires 'Text::MicroTemplate';

test_requires 'Test::More';
test_requires 'Path::Class';

tests 't/*/*/*.t';

auto_include;

WriteAll;
