#!perl

use strict;
use warnings;
use inc::Modle::Install;

name 'hlosxom';
all_from 'hlosxom.pl';

requires 'Path::Class';
requires 'Carp';
requires 'Text::MicroTemplate';
requires 'File::Find';
requires 'File::stat';
requires 'Data::Dumper';
requires 'Time::localtime';
requires 'Plack';
requires 'Plack::Request';

test_requires 'Test::More';
test_requires 'Path::Class';
test_requires 'Time::Local';
test_requires 'File::stat';
test_requires 'File::Temp';
test_requires 'HTTP::Request';
test_requires 'HTTP::Request::AsCGI';
test_requires 'Test::Warn';
test_requires 'Plack::Request';

tests 't/*/*/*.t';

auto_include;

WriteAll;
