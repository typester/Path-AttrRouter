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

done_testing;
