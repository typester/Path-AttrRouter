use Test::More;

use FindBin;
use lib "$FindBin::Bin/loader"; # located file controller

use Path::AttrRouter;

{
    # on-memory controllers
    package My::Test::Controller;
    use base 'Path::AttrRouter::Controller';

    sub index :Path {}

    package My::Test::Controller::Memory;
    use base 'Path::AttrRouter::Controller';

    sub index :Path {}
}

my $router = Path::AttrRouter->new(
    search_path => 'My::Test::Controller',
);

ok $router->actions->{''},     'root namespace ok';
ok $router->actions->{memory}, 'memory namespace ok';
ok $router->actions->{file},   'file namespace ok';

ok $router->actions->{''}{index},     'root index action ok';
ok $router->actions->{memory}{index}, 'memory index action ok';
ok $router->actions->{file}{index},   'file index action ok';

done_testing;
