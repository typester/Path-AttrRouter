use Test::More;

use Path::AttrRouter;

my $page;
{
    package MyController;
    use base 'Path::AttrRouter::Controller';

    sub page :Chained('/') :PathPart :CaptureArgs(1) {
        my ($self, $page_name) = @_;
        $page = $page_name;
    }

    sub edit :Chained('page') :PathPart { }

    package MyController::Comment;
    use base 'Path::AttrRouter::Controller';

    sub comment :Chained('../page') :Args(1) {
        my ($self, $id) = @_;
    }

    sub comments :Chained('../page') :PathPart('comment') {
        my ($self,) = @_;
    }

    sub tag_root :Chained('../page') :PathPart('tag') :CaptureArgs(0) {
    }
    sub tag_instance :Chained('tag_root') :PathPart('') :CaptureArgs(1) {
        my ($self, $id) = @_;
    }
    sub tag_view :Chained('tag_instance') :PathPart('') :Args(0) {
        my ($self) = @_;
    }
    sub tag_add :Chained('tag_root') :PathPart('add') :Args(0) {
        my ($self) = @_;
    }

    sub default :Chained('../page') :PathPart('') :Args { }

    package MyController::OrderArgs;
    use base 'Path::AttrRouter::Controller';

    sub base :Chained('/') :PathPart('orderargs') :CaptureArgs(0) {
        my ($self, $c) = @_;
    }

    sub path1_0 :Chained('base') :PathPart('path1') {
        my ($self, $c, @args) = @_;
    }

    sub path1_1 :Chained('base') :PathPart('path1') :Args(1) {
        my ($self, $c, @args) = @_;
    }

    sub path1_2 :Chained('base') :PathPart('path1') :Args(2) {
        my ($self, $c, @args) = @_;
    }

    sub path1_inf :Chained('base') :PathPart('path1') :Args {
        my ($self, $c, @args) = @_;
    }

    sub path2_inf :Chained('base') :PathPart('path2') :Args {
        my ($self, $c, @args) = @_;
    }

    sub path2_2 :Chained('base') :PathPart('path2') :Args(2) {
        my ($self, $c, @args) = @_;
    }

    sub path2_1 :Chained('base') :PathPart('path2') :Args(1) {
        my ($self, $c, @args) = @_;
    }

    sub path2_0 :Chained('base') :PathPart('path2') {
        my ($self, $c, @args) = @_;
    }
}

my $router = Path::AttrRouter->new( search_path => 'MyController' );

{
    my $m = $router->match('/page/hello/edit');
    is $m->action->name, 'edit', 'edit ok';

    $m->dispatch;
    is $page, 'hello', 'page name ok';
}

{
    my $m = $router->match('/page/hello/comment/1');
    is $m->action->name, 'comment', 'edit ok';
    is $m->args->[0], '1', 'args ok';

    $m->dispatch;
    is $page, 'hello', 'page name ok';
}

{
    my $m = $router->match('/page/hello/comment');
    is $m->action->name, 'comments', 'edit ok';

    $m->dispatch;
    is $page, 'hello', 'page name ok';
}

{
    my $m = $router->match('/page/hello/none');
    is $m->action->name, 'default', 'default action ok';
}

{
    my $m = $router->match('/page/hello/tag/1/');
    is $m->action->name, 'tag_view', 'tag_view ok';
}
{
    my $m = $router->match('/page/hello/tag/add/');
    is $m->action->name, 'tag_add', 'tag_add ok';
}

# args order
for my $type (qw/1 2/) {
    {
        my $m = $router->match("/orderargs/path${type}");
        is $m->action->name, "path${type}_0", "path${type} args0 ok";
    }
    {
        my $m = $router->match("/orderargs/path${type}/foo");
        is $m->action->name, "path${type}_1", "path${type} args1 ok";
    }
    {
        my $m = $router->match("/orderargs/path${type}/foo/bar");
        is $m->action->name, "path${type}_2", "path${type} args2 ok";
    }
    {
        my $m = $router->match("/orderargs/path${type}/foo/bar/buz");
        is $m->action->name, "path${type}_inf", "path${type} args_inf ok";
    }
}

done_testing;
