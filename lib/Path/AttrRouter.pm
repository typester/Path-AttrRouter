package Path::AttrRouter;
use Mouse;

use Carp;
use Path::AttrRouter::Controller;
use Path::AttrRouter::Action;
use Path::AttrRouter::Match;
use Try::Tiny;

our $VERSION = '0.02';

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

has action_cache => (
    is  => 'rw',
    isa => 'Str',
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

has routing_table => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->_ensure_class_loaded('Path::AttrRouter::AsciiTable');
        Path::AttrRouter::AsciiTable->new( router => $self );
    },
);

no Mouse;

sub BUILD {
    my $self = shift;

    $self->_ensure_class_loaded($self->action_class);

    if (my $cache_file = $self->action_cache) {
        $self->_load_cached_modules($cache_file);
    }
    else {
        $self->_load_modules;
    }
}

sub match {
    my ($self, $path, $condition) = @_;

    my @path = split m!/!, $path;
    unshift @path, '' unless @path;

    my ($action, @args, @captures);
 DESCEND:
    while (@path) {
        my $p = join '/', @path;
        $p =~ s!^/!!;

        for my $type (@{ $self->dispatch_types }) {
            $action = $type->match({
                path => $p,
                args => \@args,
                captures => \@captures,
                action_class => $self->action_class,
                $condition ? (%$condition) : (),
            });
            last DESCEND if $action;
        }

        my $arg = pop @path;
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @args, $arg;
    }

    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
        for grep {defined} @captures;

    if ($action) {
        # recreate controller instance if it is cached object
        unless (ref $action->controller) {
            $action->controller($self->_load_module($action->controller));
            for my $act (@{ $action->chain }) {
                $act->controller($self->_load_module($act->controller));
            }
        }

        return Path::AttrRouter::Match->new(
            action   => $action,
            args     => \@args,
            captures => \@captures,
            router   => $self,
        );
    }
    return;
}

sub print_table {
    print shift->routing_table->draw;
}

sub get_action {
    my ($self, $name, $namespace) = @_;
    return unless $name;

    $namespace ||= '';
    $namespace = '' if $namespace eq '/';

    my $container = $self->actions->{ $namespace } or return;
    my $action = $container->{ $name } or return;

    $action->controller( $self->_load_module($action->controller) )
        unless ref $action->controller;

    $action;
}

sub get_actions {
    my ($self, $action, $namespace) = @_;
    return () unless $action;

    my @actions = grep { defined } map { $_->{ $action } } $self->_get_action_containers($namespace);
    $_->controller( $self->_load_module($_->controller) )
        for grep { !ref $_->controller } @actions;

    @actions;
}

sub _get_action_containers {
    my ($self, $namespace) = @_;
    $namespace ||= '';
    $namespace = '' if $namespace eq '/';

    my @containers;
    if (length $namespace) {
        do {
            my $container = $self->actions->{ $namespace };
            push @containers, $container if $container;
        } while $namespace =~ s!/[^/]+$!!;
    }
    push @containers, $self->actions->{''} if $self->actions->{''};

    reverse @containers;
}

sub make_action_cache {
    my ($self, $file) = @_;

    my $used_dispatch_types = [grep { $_->used } @{ $self->dispatch_types }];

    # decompile regexp action because storable doen't recognize compiled regexp
    my ($regex_type) = grep { $_->name eq 'Regex' } @{ $self->dispatch_types };
    if ($regex_type->used) {
        for my $compiled (@{ $regex_type->compiled }) {
            $compiled->{re} = "$compiled->{re}";
        }
    }

    for my $namespace (keys %{ $self->actions }) {
        my $container = $self->actions->{ $namespace };
        for my $name (keys %{ $container || {} }) {
            my $action = $container->{$name};
            $action->{controller} = ref $action->{controller};
        }
    }

    my $cache = {
        dispatch_types => $used_dispatch_types,
        actions        => $self->actions,
    };

    Storable::store($cache, $file);
}

sub _load_modules {
    my ($self) = @_;

    # search on-memory modules
    my @modules = $self->_search_loaded_classes($self->search_path);

    # search unload modules
    $self->_ensure_class_loaded('Module::Pluggable::Object');
    my $finder = Module::Pluggable::Object->new(search_path => $self->search_path);
    push @modules, $finder->plugins;

    # root module
    (my $root_class = $self->search_path) =~ s/::$//;
    unshift @modules, $root_class if try { $self->_ensure_class_loaded($root_class) };

    # uniquify
    @modules = do {
        my %found;
        $found{$_}++ for @modules;
        keys %found;
    };

    my $root = $self->search_path;
    for my $module (@modules) {
        my $controller = $self->_load_module($module);
        $self->_register($controller);
    }
}

sub _load_module {
    my ($self, $module) = @_;

    my $root = $self->search_path;
    $self->_ensure_class_loaded($module);

    (my $namespace = $module) =~ s/^$root(?:::)?//;
    $namespace =~ s!::!/!g;

    if (my $cache = $self->{__object_cache}{$module}) {
        return $cache;
    }
    else {
        my $controller = $module->new;
        $controller->namespace(lc $namespace) unless defined $controller->namespace;
        return $self->{__object_cache}{$module} = $controller;
    }
}

sub _load_cached_modules {
    my ($self, $cache_file) = @_;

    $self->_ensure_class_loaded('Storable');

    my $cache = try { Storable::retrieve($cache_file) };

    unless ($cache) {
        # load modules and fill cache
        $self->_load_modules;
        $self->make_action_cache($cache_file);
        return;
    }

    $self->_ensure_class_loaded(ref $_) for @{ $cache->{dispatch_types} || [] };
    $self->dispatch_types($cache->{dispatch_types});
    $self->actions($cache->{actions});
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
                ($k, $v) = $controller->$initializer($name, $v)
                    or next;
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
    Mouse::load_class($class);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Path::AttrRouter - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

    package MyController;
    use base 'Path::AttrRouter::Controller';
    
    sub index :Path { }
    sub index2 :Path :Args(2) { }
    sub index1 :Path :Args(1) { }
    sub index3 :Path :Args(3) { }
    
    package MyController::Args;
    use base 'Path::AttrRouter::Controller';
    
    sub index :Path :Args(1) {
        my ($self, $arg) = @_;
    }
    
    package MyController::Regex;
    use base 'Path::AttrRouter::Controller';
    
    sub index :Regex('^regex/(\d+)/(.+)') {
        my ($self, @captures) = @_;
    }
    
    package main;
    use Path::AttrRouter;
    
    my $router = Path::AttrRouter->new( search_path => 'MyController' );
    my $m = $router->match('/args/hoge');
    print $m->action->name, "\n";      # => 'index'
    print $m->action->namespace, "\n"; # => 'args'
    print $m->args->[0], "\n";         # hoge

=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 METHODS

=over 4

=item get_action

=item get_actions

=item make_action_cache

=item match

=item print_table

=back

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
