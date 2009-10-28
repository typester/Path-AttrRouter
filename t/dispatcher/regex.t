use Test::More;

use Path::AttrRouter;

{
    package MyController;
    use base 'Path::AttrRouter::Controller';

    sub root :Regex('^root$') {}

    package MyController::Sub;
    use base 'Path::AttrRouter::Controller';

    sub local :LocalRegex('^localregex$') { }
    sub global :Regex('^global$') { }
}

my $router = Path::AttrRouter->new( search_path => 'MyController' );

{
    my $m = $router->match('/root');
    is $m->action->name, 'root', 'root action ok';
}

{
    my $m = $router->match('/sub/localregex');
    is $m->action->name, 'local', 'local regex action ok';
}

{
    my $m = $router->match('/global');
    is $m->action->name, 'global', 'global regex action ok';
}

done_testing;
