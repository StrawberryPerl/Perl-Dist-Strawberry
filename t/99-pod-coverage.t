use Test::More;
plan skip_all => "Skipping author tests" if not $ENV{AUTHOR_TESTING};

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.17;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

plan tests => 1;
pod_coverage_ok( "Pod::WikiDoc" );
__END__
use Test::Pod::Coverage; # Fake CPANTS
