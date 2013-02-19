package Path::AttrRouter::DispatchType::Path;
use Mouse;

has name => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Path',
);

has paths => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

no Mouse;

sub match {
    my ($self, $condition) = @_;

    my $path = $condition->{path};

    $path = '/' if !defined $path || !length $path;

    for my $action (@{ $self->paths->{$path} || [] }) {
        return $action if $action->match($condition);
    }

    return;
}

sub register {
    my ($self, $action) = @_;

    my @register_paths = @{ $action->attributes->{Path} || [] }
        or return;

    for my $path (@register_paths) {
        $self->register_path( $path => $action );
    }

    1;
}

sub used {
    my $self = shift;
    scalar( keys %{ $self->paths } );
}

sub register_path {
    my ($self, $path, $action) = @_;

    $path =~ s!^/!!;
    $path = '/' unless length $path;

    my $actions  = $self->paths->{ $path } ||= [];
    my $num_args = $action->num_args;

    unless (@$actions) {
        push @$actions, $action;
        return;
    }

    if (defined $num_args) {
        my $p;
        for ($p = 0; $p < @$actions; ++$p) {
            last unless defined $actions->[$p]->num_args;
            last if $actions->[$p]->num_args <= $num_args;
        }

        unless (defined $p) {
            unshift @$actions, $action;
        }
        else {
            @$actions = (@$actions[0..$p-1], $action, @$actions[$p..$#$actions]);
        }
    }
    else {
        push @$actions, $action;
    }
}

sub list {
    my ($self) = @_;
    return unless $self->used;

    my @rows = [[ 1 => 'Path'], [ 1 => 'Private' ]];

    for my $path (sort keys %{ $self->paths }) {
        for my $action (@{ $self->paths->{ $path } }) {
            my $display_path = $path eq '/' ? '' : "/$path";

            if (defined $action->num_args) {
                $display_path .= '/*' for 1 .. $action->num_args;
            }
            else {
                $display_path .= '/...';
            }

            push @rows, [ $display_path || '/', '/' . $action->reverse ];
        }
    }

    return \@rows;
}

__PACKAGE__->meta->make_immutable;
