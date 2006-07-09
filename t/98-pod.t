use Test::More;
plan skip_all => "Skipping author tests" if not $ENV{AUTHOR_TESTING};

my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
__END__
use Test::Pod;
