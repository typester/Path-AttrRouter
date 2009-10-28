use Test::More;

use Path::AttrRouter;

{
    package MyController;
    use base 'Path::AttrRouter::Controller';

    sub action1 :Path('action') { }
    sub action2 :Path('action') { }

    sub arg0 :Path('args') { }
    sub arg3 :Path('args') :Args(3) {}
    sub arg1 :Path('args') :Args(1) {}
    sub arg_inf :Path('args') :Args {}
    sub arg2 :Path('args') :Args(2) {}
}

my $router = Path::AttrRouter->new( search_path => 'MyController' );

{
    my $m = $router->match('/action');
    is $m->action->name, 'action2', 'latest action executed';
}

{
    my $m = $router->match('/args');
    is $m->action->name, 'arg0', 'arg0';
}

{
    my $m = $router->match('/args/1');
    is $m->action->name, 'arg1', 'arg1';
}

{
    my $m = $router->match('/args/1/2');
    is $m->action->name, 'arg2', 'arg2';
}

{
    my $m = $router->match('/args/1/2/3');
    is $m->action->name, 'arg3', 'arg3';
}

{
    my $m = $router->match('/args/1/2/3/4');
    is $m->action->name, 'arg_inf', 'arg_inf';
}


done_testing;
