package Path::AttrRouter::ActionChain;
use Any::Moose;

extends 'Path::AttrRouter::Action';

has chain => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

no Any::Moose;

sub dispatch {
    my ($self, $match, @args) = @_;

    local $match->{captures} = $match->captures;

    my @chain = @{ $self->chain };
    my $last  = pop @chain;

    for my $action (@chain) {
        my @c;
        if (defined $action->attributes->{CaptureArgs}[0]) {
            @c = splice @{ $match->{captures} },
                0, $action->attributes->{CaptureArgs}[0];
        }
        local $match->{captures} = \@c;
        $action->dispatch($match, @args);
    }

    $last->dispatch($match, @args);
}

sub from_chain {
    my ($class, $chains) = @_;
    my $final = $chains->[-1];

    $class->new({ %$final, chain => $chains });
}

__PACKAGE__->meta->make_immutable;
