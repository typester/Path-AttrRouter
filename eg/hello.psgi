use strict;
use warnings;

use Path::AttrRouter;
use Plack::Request;

{
    package Hello::Controller;
    use strict;
    use warnings;
    use base 'Path::AttrRouter::Controller';

    sub index :Path {
        my ($self, $req) = @_;

        my $res = $req->new_response(200);
        $res->body('Hello World!');

        $res;
    }
}

my $router = Path::AttrRouter->new( search_path => 'Hello::Controller' );
warn $router->routing_table->draw;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my $m = $router->match( $req->path );

    my $res;
    if ($m) {
        $res = $m->dispatch($req);
    }
    else {
        $res = $req->new_response(404);
        $res->body('404 Not Found');
    }

    $res->finalize;
};
