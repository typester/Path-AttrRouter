package Path::AttrRouter;
use Any::Moose;

use Carp;
use Path::AttrRouter::Controller;
use Path::AttrRouter::Action;
use Path::AttrRouter::Match;

our $VERSION = '0.01';

has search_path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has actions => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has action_class => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Path::AttrRouter::Action',
);

has dispatch_types => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my @types;
        for (qw/Path Regex Chained/) {
            my $class = "Path::AttrRouter::DispatchType::$_";
            $self->_ensure_class_loaded($class);
            push @types, $class->new;
        }

        \@types;
    },
);

no Any::Moose;

sub BUILD {
    my $self = shift;

    # search on-memory modules
    my @modules = $self->_search_loaded_classes($self->search_path);

    # search unload modules
    $self->_ensure_class_loaded('Module::Pluggable::Object');
    my $finder = Module::Pluggable::Object->new(search_path => $self->search_path);
    push @modules, $finder->plugins;

    $self->_load_modules(@modules);
}

sub dispatch {
    my ($self, $path) = @_;

    if (my $match = $self->match($path)) {
        if ($match->action->can('chain')) {
            $match->action->dispatch($match);
        }
        return $match->action->dispatch( $match->args || $match->captures );
    }
    croak qq[No action found for path:"$path"];
}

sub match {
    my ($self, $path) = @_;

    my @path = split m!/!, $path;
    unshift @path, '' unless @path;

    my ($action, @args, @captures);
 DESCEND:
    while (@path) {
        my $p = join '/', @path;
        $p =~ s!^/!!;

        for my $type (@{ $self->dispatch_types }) {
            $action = $type->match($p, \@args, \@captures);
            last DESCEND if $action;
        }

        my $arg = pop @path;
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @args, $arg;
    }

    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
        for grep {defined} @captures;

    if ($action) {
        return Path::AttrRouter::Match->new(
            action   => $action,
            args     => \@args,
            captures => \@captures,
        );
    }
    return;
}

sub _load_modules {
    my ($self, @modules) = @_;

    my $root = $self->search_path;
    for my $module (@modules) {
        $self->_ensure_class_loaded($module);

        (my $namespace = $module) =~ s/^$root(?:::)?//;
        $namespace =~ s!::!/!g;

        my $controller = $module->new( namespace => lc $namespace );
        $self->_register($controller);
    }
}

sub _register {
    my ($self, $controller) = @_;
    my $context_class = ref $controller || $controller;

    $controller->_method_cache([ @{$controller->_method_cache} ]);

    $self->_ensure_class_loaded('Data::Util');
    while (my $attr = shift @{ $controller->_attr_cache || [] }) {
        my ($pkg, $method) = Data::Util::get_code_info($attr->[0]);
        push @{ $controller->_method_cache }, [ $method, $attr->[1] ];
    }

    for my $cache (@{ $controller->_method_cache || [] }) {
        my ($method, $attrs) = @$cache;
        $attrs = $self->_parse_action_attrs( $controller, $method, @$attrs );

        my $ns = $controller->namespace;
        my $reverse = $ns ? "${ns}/${method}" : $method;

        my $action = $self->action_class->new(
            name       => $method,
            reverse    => $reverse,
            namespace  => $ns,
            attributes => $attrs,
            controller => $controller,
        );
        $self->_register_action($action);
    }
}

sub _register_action {
    my ($self, $action) = @_;

    for my $type (@{ $self->dispatch_types }) {
        $type->register($action);
    }

    my $container = $self->actions->{ $action->namespace } ||= {};
    $container->{ $action->name } = $action;
}

# synbol table walking code from Mouse::Util
sub _search_loaded_classes {
    my ($self, $path) = @_;
    # walk the symbol table tree to avoid autovififying
    # \*{${main::}{"Foo::"}} == \*main::Foo::

    my @found;
    $path =~ s/::$//;

    my $pack = \%::;
    for my $part (split '::', $path) {
        my $entry = \$pack->{ $part . '::' };
        return @found if ref $entry ne 'GLOB';
        $pack = *{$entry}{HASH} or return @found;
    }

    if (exists $pack->{ISA} and my $isa = $pack->{ISA}) {
        if (defined *{$isa}{ARRAY} and @$isa != 0) {
            (my $module = $path) =~ s/::$//;
            push @found, $module;
        }
    }

    for my $submodule (grep /.+::$/, keys %$pack) {
        push @found, $self->_search_loaded_classes($path . '::' . $submodule);
    }

    return @found;
}

sub _parse_action_attrs {
    my ($self, $controller, $name, @attrs) = @_;

    my %parsed;
    for my $attr (@attrs) {
        if (my ($k, $v) = ( $attr =~ /^(.*?)(?:\(\s*(.+?)\s*\))?$/ )) {
            ( $v =~ s/^'(.*)'$/$1/ ) || ( $v =~ s/^"(.*)"/$1/ )
                if defined $v;

            my $initializer = "_parse_${k}_attr";
            if ($controller->can($initializer)) {
                ($k, $v) = $controller->$initializer($name, $v);
                push @{ $parsed{$k} }, $v;
            }
            else {
                carp qq{Unsupported attribute "${k}". ignored};
            }
        }
    }

    return \%parsed;
}

sub _ensure_class_loaded {
    my ($self, $class) = @_;
    Any::Moose::load_class($class) unless Any::Moose::is_class_loaded($class);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Path::AttrRouter - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use Path::AttrRouter;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
