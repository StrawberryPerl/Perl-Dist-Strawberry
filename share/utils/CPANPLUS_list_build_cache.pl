use strict;
use warnings;

use CPANPLUS::Backend;
use File::Glob            qw(bsd_glob);
use File::Basename;
use Data::Dumper;
use Storable              qw(nstore);
use Getopt::Long          qw(GetOptions);

warn ">> started '$0'\n";

# parse commandline options
my @spec = (
    'out_dumper=s',
    'out_nstore=s',
);
GetOptions(\my %a, @spec) or die ">> invalid option(s)";

# set defaults
$a{out_dumper} //= 'build-cache-list.dumper.txt';
$a{out_nstore} //= 'build-cache-list.nstore.txt';

### SUBROUTINES

sub save_output {
  my ($data, $out_nstore, $out_dumper) = @_;
  if ($out_nstore) {
    warn ">> storing results via Storable to '$out_nstore'\n";
    nstore($data, $out_nstore) or die ">> store failed";;
  }
  if ($out_dumper) {
    warn ">> storing results via Data::Dumper to '$out_nstore'\n";
    open my $fh, ">", $out_dumper or die ">> open: $!";
    print $fh Dumper($data) or die ">> print: $!";
    close $fh or die ">> close: $!";
  }
}

### MAIN

my $cb = CPANPLUS::Backend->new();
my $conf = $cb->configure_object();
my $base = $conf->get_conf('base');
my $perl_ver = sprintf "%vd", $^V;
my @dirs = map { basename($_) } grep { -d $_ } bsd_glob("$base/$perl_ver/build/*");
save_output(\@dirs, $a{out_nstore}, $a{out_dumper});
