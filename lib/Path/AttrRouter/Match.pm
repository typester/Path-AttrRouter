package Path::AttrRouter::Match;
use Any::Moose;

has action => (
    is       => 'rw',
    isa      => 'Path::AttrRouter::Action',
    required => 1,
);

has args => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has captures => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

no Any::Moose;

sub dispatch {
    my ($self, @args) = @_;
    $self->action->dispatch( $self, @args );
}

__PACKAGE__->meta->make_immutable;
