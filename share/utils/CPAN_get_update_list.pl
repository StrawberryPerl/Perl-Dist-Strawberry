use strict;
use warnings;

use CPAN;
use Storable qw(nstore);
use Data::Dumper;

my ($out_nstore, $out_dumper, $url) = @ARGV;

$out_nstore = 'upgrade-list.nstore.txt' unless $out_nstore;
$out_dumper = 'upgrade-list.dumper.txt' unless $out_dumper;
$url = 'http://cpan.strawberryperl.com' unless $url;

CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
$CPAN::Config->{'urllist'} = [ $url ];

my ($module, %seen, %need);
my @toget = ();

warn ">> Gonna call CPAN::Shell\n";
my @modulelist = CPAN::Shell->expand('Module', '/./');

# Schwartzian transform from CPAN.pm.
my @expand;
@expand = map {
  $_->[1]
} sort {
  $b->[0] <=> $a->[0]
  ||
  $a->[1]{ID} cmp $b->[1]{ID},
} map {
  [$_->_is_representative_module,
   $_
  ]
} @modulelist;

require Config;
my $vendorlib=$Config::Config{'installvendorlib'};

for $module (@expand) {
  my $file = $module->cpan_file;

  # If there's no file to download, skip it.
  next unless defined $file;

  $file =~ s{^./../}{};
  my $latest  = $module->cpan_version;
  my $inst_file = $module->inst_file;
  my $have;
  my $next_MODULE;
  eval { # version.pm involved!
    if ($inst_file and $vendorlib ne substr($inst_file,0,length($vendorlib))) {
      $have = $module->inst_version;
      local $^W = 0;
      ++$next_MODULE unless CPAN::Version->vgt($latest, $have) && !($have eq "undef" && $latest ne "undef");
      # to be pedantic we should probably say:
      #    && !($have eq "undef" && $latest ne "undef" && $latest gt "");
      # to catch the case where CPAN has a version 0 and we have a version undef
    } else {
       ++$next_MODULE;
    }
  };

  next if $next_MODULE;
  next if ($@);

  $seen{$file} ||= 0;
  next if $seen{$file}++;

  push @toget, $module;
  $need{$module->id}++;
}

if (scalar(@toget)==0) {
  warn ">> All modules are up to date\n";
}
else {
  warn ">> ", scalar(@toget), " module(s) need upgrade\n";
}

if ($out_nstore) {
  #store via Storable
  nstore \@toget, $out_nstore;
}

if ($out_dumper) {
  #store via Data::Dumper
  open my $fh, ">", $out_dumper or die ">> open: $!";
  print $fh Dumper(\@toget);
  close $fh;
}

warn ">> Done!\n";
exit 0;
