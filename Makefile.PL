use inc::Module::Install;
name 'Path-AttrRouter';
all_from 'lib/Path/AttrRouter.pm';

requires 'Mouse' => '1.05';
requires 'Module::Pluggable::Object';
requires 'Text::SimpleTable' => '1.1';
requires 'Data::Util';
requires 'Class::Data::Inheritable';
requires 'Try::Tiny';

test_requires 'Test::More' => '0.88';
use_test_base;

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_include;
auto_set_repository;

WriteAll;
