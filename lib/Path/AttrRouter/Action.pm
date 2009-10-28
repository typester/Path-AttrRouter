package Path::AttrRouter::Action;
use Any::Moose;

has [qw/namespace reverse name/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has attributes => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has controller => (
    is       => 'rw',
    isa      => 'Object | Str',
    required => 1,
);

has num_args => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->attributes->{Args} ? $self->attributes->{Args}[0] : 0;
    },
);

no Any::Moose;

sub dispatch {
    my ($self, $match, @args) = @_;

    my @action_args = @{ $match->captures } ? @{ $match->captures } : @{ $match->args };

    my $code = $self->controller->can( $self->name );
    $code->( $self->controller, @args, @action_args);
}

sub match_args {
    my ($self, $args) = @_;

    my $num_args = $self->num_args;
    return 1 unless defined($num_args) && length($num_args);
    return scalar(@$args) == $num_args;
}

__PACKAGE__->meta->make_immutable;


