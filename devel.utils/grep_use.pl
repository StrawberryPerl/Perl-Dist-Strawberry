use strict;
use warnings;

use File::Find::Rule;
use File::Slurp;
use FindBin;
use Data::Dump 'pp';

my $libdir = "$FindBin::Bin/../lib";

my @pm_files = File::Find::Rule->file()->name('*.pm')->in($libdir);

my @all_lines;

for (@pm_files) {
  my @l = read_file($_);
  push  @all_lines, @l;
}

@all_lines = grep { /^use / } @all_lines;
@all_lines = map { s/^(use\s*[^\s;]+).*[\r\n]*$/$1/; $_ } @all_lines;
my %uniq = map { $_=> 1 } @all_lines;
@all_lines = sort keys %uniq;

pp \@all_lines;
