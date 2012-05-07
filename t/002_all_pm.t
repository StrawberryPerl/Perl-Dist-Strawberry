use strict;
use warnings;

use Test::More tests => 1;
use File::Find qw(find);

my @files;
find({ wanted=>sub { push @files, $_ if /\.pm$/ }, no_chdir=>1 }, 'lib');

for my $m (sort @files) {
  $m =~ s|[\\/]|::|g;
  $m =~ s|^lib::||;
  $m =~ s|\.pm$||;
  eval "use $m; 1;" or die "ERROR: 'use $m' failed";
}

ok 1, 'all done';
