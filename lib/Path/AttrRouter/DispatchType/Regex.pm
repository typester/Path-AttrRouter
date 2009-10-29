package Path::AttrRouter::DispatchType::Regex;
use Any::Moose;

extends 'Path::AttrRouter::DispatchType::Path';

has '+name' => (
    default => 'Regex',
);

has compiled => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

no Any::Moose;

sub match {
    my ($self, $path, $args, $captures) = @_;

    for my $compiled (@{ $self->compiled }) {
        if (my @captures = ($path =~ $compiled->{re})) {
            @$captures = @captures;
            return $compiled->{action};
        }
    }

    return;
}

sub register {
    my ($self, $action) = @_;

    my @register_regex = @{ $action->attributes->{Regex} || [] }
        or return;

    for my $regex (@register_regex) {
        $self->register_regex( $regex, $action );
    }
}

sub register_regex {
    my ($self, $re, $action) = @_;

    push @{ $self->compiled }, {
        re     => qr/$re/,
        action => $action,
        path   => $re,
    };
}

sub used {
    my ($self) = @_;
    scalar @{ $self->compiled };
}

sub list {
    my ($self) = @_;
    return unless $self->used;

    my @rows = [[ 1, 'Regex' ], [ 1, 'Private' ]];

    for my $re (@{ $self->compiled }) {
        push @rows, [ $re->{path}, '/' . $re->{action}->reverse ];
    }

    \@rows;
}

__PACKAGE__->meta->make_immutable;
