use 5.012;
use warnings;

use CPANPLUS::Backend;
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

# set defaults
$a{url}        //= 'http://cpan.strawberryperl.com';
$a{out_dumper} //= 'upgrade-list.dumper.txt';
$a{out_nstore} //= 'upgrade-list.nstore.txt';

### SUBROUTINES

sub get_cpanplus_backend {
  my %args = @_;
  
  warn ">> creating CPANPLUS::Backend\n";
  my $cb = CPANPLUS::Backend->new;
  my $conf = $cb->configure_object;

  if ($args{url}) {
    my $url = $args{url};
    $url = "$url/" unless $url =~ m|/$|;
    warn ">> using cpan mirror '$url'\n";
    my ($scheme, $host, $path) = $url =~ m|(.*?)://(.*?)(/.*)|;
    $conf->set_conf('hosts', [ {scheme=>$scheme, path=>$path, host=>$host} ]);
  }

  return $cb;
}

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

sub modinfo2hash {
  my $mod = shift;
  return unless $mod && ref $mod eq 'CPANPLUS::Module';
  return {
    local_version => $mod->installed_version,
    cpan_version  => $mod->version,
    module        => $mod->module,
    distribution  => $mod->package_name,
    cpan_file     => $mod->author->cpanid . '/' . $mod->package,
    core_module   => $mod->module_is_supplied_with_perl_core ? 1 : 0,
  };
}

sub get_upgrade_list {
  my $cb = shift;
  die ">> no cpanplus backend" unless $cb;
  
  # get info about all installed modules
  warn ">> loading info about installed modules\n";
  my @all = $cb->installed;
  die ">> FATAL: cannot list installed modules via CPANPLUS\n" unless scalar(@all) > 0;

  # select modules that need upgrade
  my @to_upgrade = ();
  my @trouble_makers = ();

  my %seen;
  for my $mod (@all) {
    next if $mod->is_uptodate;           # skip this mod if it's up to date
    next if $mod->package_is_perl_core;  # skip this mod if it's core
    next if $seen{$mod->package}++;
    if ($mod->installed_version && $mod->version) {
      push @to_upgrade, $mod;
    }
    else {
      # undefined or '0' version
      push @trouble_makers, $mod;
    }
  }
  @to_upgrade = sort { $a->module cmp $b->module } @to_upgrade;
  @trouble_makers = sort { $a->module cmp $b->module } @trouble_makers;

  my $rv = { to_upgrade=>[], trouble_makers=>[], method=>'CPANPLUS', timestamp=>time };
  push @{$rv->{to_upgrade}}, modinfo2hash($_) for (@to_upgrade);
  push @{$rv->{trouble_makers}}, modinfo2hash($_) for (@trouble_makers);

  warn ">> count of all            = ", scalar(@all), "\n";
  warn ">> count of trouble_makers = ", scalar(@trouble_makers), "\n";
  warn ">> * $_->{cpan_file}\n" for (@{$rv->{trouble_makers}});
  warn ">> count of to_upgrade     = ", scalar(@to_upgrade), "\n";
  warn ">> * $_->{cpan_file}\n" for (@{$rv->{to_upgrade}});
  warn ">> get_upgrade_list finished\n";

  return $rv;
}

### MAIN

my $cb = get_cpanplus_backend(url=>$a{url});
my $data = get_upgrade_list($cb);
save_output($data, $a{out_nstore}, $a{out_dumper});

warn ">> done!\n";
exit 0;
