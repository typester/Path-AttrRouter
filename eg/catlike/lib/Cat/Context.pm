package Cat::Context;
use Mouse;

use Plack::Request;
use Plack::Response;

has request => (
    is       => 'rw',
    isa      => 'Plack::Request',
    required => 1,
);

has response => (
    is      => 'rw',
    isa     => 'Plack::Response',
    default => sub { Plack::Response->new(200, [], '') },
);

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has match => (
    is      => 'rw',
    isa     => 'Path::AttrRouter::Match',
    handles => ['action'],
);

__PACKAGE__->meta->make_immutable;
