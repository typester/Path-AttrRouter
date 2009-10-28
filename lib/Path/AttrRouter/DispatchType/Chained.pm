package Path::AttrRouter::DispatchType::Chained;
use Any::Moose;

use Carp;
use File::Spec::Unix;

use Path::AttrRouter::ActionChain;

has chain_from => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

sub match {
    my ($self, $path, $args, $captures) = @_;
    return if @$args;

    my @parts = split '/', $path;

    my ($chain, $action_captures, $parts) = $self->recurse_match('/', @parts);
    return unless $chain;

    @$args = @$parts;
    @$captures = @$action_captures;

    return Path::AttrRouter::ActionChain->from_chain($chain);
}

sub recurse_match {
    my ($self, $parent, @pathparts) = @_;

    my @chains = @{ $self->chain_from->{ $parent } }
        or return;

    for my $action (@chains) {
        my @parts = @pathparts;

        my $pathpart = $action->attributes->{PathPart}[0];
        if (length $pathpart) {
            my @p = split '/', $pathpart;
            next if @p > @parts;

            my @stripped = splice @parts, 0, scalar @p;
            next unless $pathpart eq join '/', @stripped;
        }

        if (defined $action->attributes->{CaptureArgs}[0]) {
            my $capture_args = $action->attributes->{CaptureArgs}[0];
            next if @parts < $capture_args;

            my @captures = splice @parts, 0, $capture_args;
            my ($actions, $captures, $action_parts)
                = $self->recurse_match('/'.$action->reverse, @parts);
            next unless $actions;

            return ([ $action, @$actions ], [@captures, @$captures], $action_parts);
        }
        else {
            next unless $action->match_args(\@parts);
            return ([ $action ], [], \@parts);
        }
    }
}

sub register {
    my ($self, $action) = @_;

    my @chained = @{ $action->attributes->{Chained} || [] }
        or return;

    my $parent = $chained[0];
    if ($parent) {
        unless ($parent =~ m!^/!) {
            $parent = File::Spec::Unix->rel2abs($parent, '/' . $action->namespace);
        }
    }
    else {
        $parent = '/';
    }
    $action->attributes->{Chained} = [$parent];

    my $children = $self->chain_from->{ $parent } ||= [];
    my @pathpart = @{ $action->attributes->{PathPart} || [] };

    my $part = defined $pathpart[0] ? $pathpart[0] : $action->name;
    $action->attributes->{PathPart} = [$part];

    my $num_parts = sub {
        my $action = $_[0];
        my @parts = split '/', $action->attributes->{PathPart};
        my $num   = scalar @parts;
        if (defined $action->attributes->{CaptureArgs}[0]) {
            $num += $action->attributes->{CaptureArgs}[0];
        }
        else {
            $num += $action->num_args;
        }
    };

    @$children = sort { $num_parts->($b) <=> $num_parts->($a) } @$children, $action;
}

__PACKAGE__->meta->make_immutable;
