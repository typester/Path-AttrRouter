package Path::AttrRouter::Action;
use Mouse;

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

        return 0 unless exists $self->attributes->{Args};

        if (defined $self->attributes->{Args}[0]) {
            return $self->attributes->{Args}[0];
        }
        else {
            return;
        }
    },
);

has chain => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

no Mouse;

sub dispatch {
    my $self = shift;

    my $class  = $self->controller;
    my $method = $self->name;

    $class->$method(@_);
}

sub match {
    my ($self, $condition) = @_;

    return 0 unless $self->match_args($condition->{args});
    return 1;
}

sub match_args {
    my ($self, $args) = @_;

    my $num_args = $self->num_args;
    return 1 unless defined($num_args) && length($num_args);
    return scalar(@$args) == $num_args;
}

sub from_chain {
    my ($class, $chains) = @_;
    my $final = $chains->[-1];

    $class->new({ %$final, chain => $chains });
}

__PACKAGE__->meta->make_immutable;


