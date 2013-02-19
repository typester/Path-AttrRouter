package Path::AttrRouter::Match;
use Mouse;

has action => (
    is       => 'rw',
    isa      => 'Path::AttrRouter::Action',
    required => 1,
);

has args => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 1,
);

has captures => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 1,
);

has router => (
    is       => 'rw',
    required => 1,
    weak_ref => 1,
);

no Mouse;

sub dispatch {
    my ($self, @args) = @_;
    my $action = $self->action;

    if (my @chain = @{ $action->chain }) {
        my $last = pop @chain;

        local $self->{captures} = $self->captures;
        for my $act (@chain) {
            my @c;
            if (defined $act->attributes->{CaptureArgs}[0]) {
                @c = splice @{ $self->{captures} },
                    0, $act->attributes->{CaptureArgs}[0];
            }
            local $self->{captures} = \@c;
            $act->dispatch(@args, @c);
        }
        $last->dispatch(@args, @{ $self->args });
    }
    else {
        my @match_args = @{ $self->captures } ? @{ $self->captures } : @{ $self->args };
        $self->action->dispatch( @args, @match_args );
    }
}

__PACKAGE__->meta->make_immutable;
