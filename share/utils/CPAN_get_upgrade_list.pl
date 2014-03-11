use 5.012;
use warnings;

use CPAN;
use Storable              qw(nstore);
use Data::Dumper          qw(Dumper);
use Getopt::Long          qw(GetOptions);

warn ">> started '$0'\n";

# parse commandline options
my @spec = (
    'url=s',
    'out_dumper=s',
    'out_nstore=s',
);
GetOptions(\my %a, @spec) or die ">> invalid option(s)";

my $out_nstore = $a{out_nstore} // 'upgrade-list.nstore.txt';
my $out_dumper = $a{out_dumper} // 'upgrade-list.dumper.txt';
my $url = $a{url} // 'http://cpan.strawberryperl.com';

warn Dumper($url);
CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
$CPAN::Config->{'urllist'} = [ $url ];

my ($module, %seen, %need);
my @toget = ();

warn ">> gonna call CPAN::Shell\n";
CPAN::Shell->reload('index');
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
      if (CPAN::Version->vgt($latest, $have) && !($have eq "undef" && $latest ne "undef")) {
        #warn "UPGRADE NEEDED: '$inst_file' have=$have latest=$latest\n" if "$have" ne "$latest";
      }
      else {
        ++$next_MODULE 
      }
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

  push @toget, { distribution  => $module->distribution->base_id, 
                 cpan_file     => $module->cpan_file,
                 cpan_version  => $module->cpan_version,
                 local_version => $module->inst_version,
               };
  $need{$module->id}++;
}

##@toget = sort { $a->distribution cmp $b->distribution } @toget;
my $rv = { to_upgrade=>\@toget, method=>'CPAN', timestamp=>time };

if (scalar(@toget)==0) {
  warn ">> All modules are up to date\n";
}
else {
  warn ">> ", scalar(@toget), " module(s) need upgrade\n";
  warn ">> * $_->{cpan_file}\n" for (@toget);
}

if ($out_nstore) {
  #store via Storable
  nstore $rv, $out_nstore;
}

if ($out_dumper) {
  #store via Data::Dumper
  open my $fh, ">", $out_dumper or die ">> open: $!";
  print $fh Dumper($rv);
  close $fh;
}

warn ">> Done!\n";
exit 0;
