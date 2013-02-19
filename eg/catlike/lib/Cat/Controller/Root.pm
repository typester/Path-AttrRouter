package Cat::Controller::Root;
use Mouse;
use Path::AttrRouter::Controller '-extends';

use Text::MicroTemplate::File;

has '+namespace' => default => '';

has mt => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        Text::MicroTemplate::File->new(
            include_path => [ "./root" ],
        );
    },
);

no Mouse;

sub index :Path {
    my ($self, $c) = @_;
}

sub end :Private {
    my ($self, $c) = @_;

    unless ($c->response->body and $c->response->status =~ /^3/) {
        $c->response->body(
            $self->mt->render_file( $c->action->reverse . '.mt', $c )
        );
    }
}

__PACKAGE__->meta->make_immutable;
y
