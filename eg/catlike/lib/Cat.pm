package Cat;
use Mouse;

use Plack::Request;
use Path::AttrRouter;

use Cat::Context;

has router => (
    is  => 'rw',
    isa => 'Path::AttrRouter',
);

has handler => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        my ($self) = @_;
        return sub {
            my $req = Plack::Request->new(@_);
            my $res = $self->handle_request($req);
            $res->finalize;
        };
    },
);

has context => (
    is  => 'rw',
    isa => 'Cat::Context',
);

no Mouse;

sub BUILD {
    my ($self) = @_;

    my $router = Path::AttrRouter->new(
        search_path  => ref($self) . '::Controller',
        action_class => 'Cat::Action',
    );
    $self->router($router);

    warn $router->routing_table->draw;
}

sub handle_request {
    my ($self, $req) = @_;

    my $c = Cat::Context->new( request => $req );
    my $m = $c->match( $self->router->match($req->path) );

    if ($m) {
        $self->dispatch_action($c, 'begin')
            and $self->dispatch_auto_action($c)
            and $m->dispatch($c);

        $self->dispatch_action($c, 'end');
    }
    else {
        $c->response->status(404);
        $c->response->body('404 Not Found');
    }

    $c->response;
}

sub dispatch_action {
    my ($self, $c, $name) = @_;

    my $begin = ($self->router->get_actions($name, $c->action->namespace))[-1]
        or return 1;
    $begin->dispatch($c);

    1;
}

sub dispatch_auto_action {
    my ($self, $c) = @_;

    for my $auto ($self->router->get_actions('auto', $c->action->namespace)) {
        $auto->dispatch($c) or return 0;
    }

    1;
}

__PACKAGE__->meta->make_immutable;

