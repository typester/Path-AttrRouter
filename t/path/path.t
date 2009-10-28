use Test::More;

use Path::AttrRouter;

{
    package MyController;
    use base 'Path::AttrRouter::Controller';

    sub index :Path { }

    sub path1 :Path('path1') { }
    sub path2 :Local { }
    sub path3 :Global {}

    package MyController::Sub;
    use base 'Path::AttrRouter::Controller';

    sub index :Path { }

    sub path1 :Path('path1') {}
    sub path2 :Local { }
    sub path4 :Global {}
    sub path5 :Path('/path5') {}
}

my $router = Path::AttrRouter->new( search_path => 'MyController' );

{
    my $m = $router->match('/');
    is $m->action->name, 'index', 'index ok';
    is $m->action->namespace, '', 'index ns ok';
}

{
    my $m = $router->match('/path1');
    is $m->action->name, 'path1', 'path1 ok';
    is $m->action->namespace, '', 'path1 ns ok';
}

{
    my $m = $router->match('/path2');
    is $m->action->name, 'path2', 'path2 ok';
    is $m->action->namespace, '', 'path2 ns ok';
}

{
    my $m = $router->match('/path3');
    is $m->action->name, 'path3', 'path3 ok';
    is $m->action->namespace, '', 'path3 ns ok';
}

{
    my $m = $router->match('/sub');
    is $m->action->name, 'index', 'sub index ok';
    is $m->action->namespace, 'sub', 'sub index ns ok';
}

{
    my $m = $router->match('/sub/path1');
    is $m->action->name, 'path1', 'sub path1 ok';
    is $m->action->namespace, 'sub', 'sub index ns ok';
}

{
    my $m = $router->match('/sub/path2');
    is $m->action->name, 'path2', 'sub path2 ok';
    is $m->action->namespace, 'sub', 'sub index ns ok';
}

{
    my $m = $router->match('/path4');
    is $m->action->name, 'path4', 'sub path4 ok';
    is $m->action->namespace, 'sub', 'sub index ns ok';
}

{
    my $m = $router->match('/path5');
    is $m->action->name, 'path5', 'sub path4 ok';
    is $m->action->namespace, 'sub', 'sub index ns ok';
}

done_testing;
