package Path::AttrRouter::AsciiTable;
use Mouse;

use Path::AttrRouter;
use Text::SimpleTable;

has router => (
    is       => 'ro',
    isa      => 'Path::AttrRouter',
    required => 1,
);

has term_width => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $width;
        if (exists $ENV{COLUMNS} and $ENV{COLUMNS} =~ /^\d+$/) {
            $width = $ENV{COLUMNS};
        }
        else {
            local $@;
            $width = eval q{
                use Term::Size::Any;
                my ($columns, $rows) = Term::Size::Any::chars;
                $columns;
            };
        }

        $width = 80 unless $width and $width >= 80;
        $width;
    },
);

no Mouse;

sub draw {
    my ($self) = @_;

    my $draw = q[];
    for my $type (@{ $self->router->dispatch_types }) {
        my $list = $type->list or next;

        my $total;
        my @header = @{ shift @$list };
        $total += $_->[0] for @header;

        my $rest = scalar(@header) * 4;

        for my $item (@header) {
            $item->[0] = int( ($self->term_width - $rest) * ($item->[0] / $total));
        }

        $total = 0; $total += $_->[0] for @header;
        if ($total < $self->term_width) {
            $header[-1]->[0] += $total < $self->term_width;
        }

        my $table = Text::SimpleTable->new(@header);
        for my $row (@$list) {
            if (defined $row) {
                $table->row(@{ $row });
            }
            else {
                $table->hr;
            }
        }

        $draw .= sprintf("Loaded %s actions:\n%s\n", $type->name, $table->draw);
    }

    return $draw;
}

__PACKAGE__->meta->make_immutable;
