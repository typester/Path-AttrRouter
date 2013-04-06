BEGIN {
    my @devmods = qw(
        Module::Install::TestBase
        Module::Install::AuthorTests
        Module::Install::ReadmeFromPod
        Module::Install::Repository
    );
    my @not_available;

    {
        $|=1;
        local *STDOUT;
        eval qq{use inc::Module::Install; 1;} or push @not_available, 'inc::Module::Install';
    }

    for my $mod (@devmods) {
        eval qq{require $mod} or push @not_available, $mod;
    }
    if (@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `$^X $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        print "\n";
        exit -1;
    }
}

use inc::Module::Install;
$Module::Install::AUTHOR = 0 if $ENV{TRAVIS};

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

no_index directory => qw/xt eg/;

WriteAll;
