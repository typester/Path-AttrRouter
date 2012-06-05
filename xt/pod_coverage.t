use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
pod_coverage_ok(
    "Path::AttrRouter",
    { also_private => [ qr/^[A-Z_]+$/ ], }
);
done_testing;
