use inc::Module::Install;
name 'Path-AttrRouter';
all_from 'lib/Path/AttrRouter.pm';

test_requires 'Test::More';
use_test_base;
author_tests('xt');

auto_include;
auto_set_repository;

WriteAll;
