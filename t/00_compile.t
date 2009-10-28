use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Path::AttrRouter' }

no warnings 'uninitialized';

diag "Soft dependency versions:";

eval { require Moose };
diag "    Moose: $Moose::VERSION";

eval{ require Mouse };
diag "    Mouse: $Mouse::VERSION";

eval{ require Any::Moose };
diag "    Any::Moose: $Any::Moose::VERSION";

