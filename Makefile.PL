use inc::Module::Install;
name 'Path-AttrRouter';
all_from 'lib/Path/AttrRouter.pm';

requires 'Any::Moose' => '0.10';
requires 'Module::Pluggable::Object';

test_requires 'Test::More' => '0.88';
use_test_base;
author_tests('xt');

auto_include;
auto_set_repository;

WriteAll;
