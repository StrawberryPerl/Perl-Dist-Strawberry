use 5.012;
use warnings;

use CPANPLUS::Backend;
use Storable              qw(nstore);
use Data::Dumper          qw(Dumper);
use Getopt::Long          qw(GetOptions);
use File::Spec::Functions qw(catfile);

warn ">> started '$0'\n";

# parse commandline options
my @spec = (
    'module=s@',
    'url=s',
    'verbose=i',
);
my %a = ();
GetOptions(\%a, @spec) or die ">> invalid option(s)";

# defaults
$a{module}        //= [];
$a{url}           //= 'http://cpan.strawberryperl.com';
$a{verbose}       //= 1;
$a{interactivity} //= 0; # 1 = allow_build_interactivity

### SUBROUTINES

sub get_cpanplus_backend {
  my %args = @_;
  
  warn ">> creating CPANPLUS::Backend\n";
  my $cb = CPANPLUS::Backend->new();
  my $conf = $cb->configure_object();

  for (keys %args) {
    if ($_ eq 'url' && $args{$_}) {
      my $url = $args{url};
      $url = "$url/" unless $url =~ m|/$|;
      warn ">> using cpan mirror '$url'\n";
      my ($scheme, $host, $path) = $url =~ m|(.*?)://(.*?)(/.*)|;
      $conf->set_conf('hosts', [ {scheme=>$scheme, path=>$path, host=>$host} ]);
    }
    else {
      warn">> set_conf('$_' => '$args{$_}')\n";
      $conf->set_conf($_ => $args{$_});
    }
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

### MAIN

die ">> no modules specified" unless scalar(@{$a{module}});

my %cfg = (verbose => $a{verbose});

my $success = 1;
my $cb = get_cpanplus_backend( url=>$a{url}, %cfg );

for my $name (@{$a{module}}) {
  warn ">> Uninstalling '$name'\n";
  warn ">> ########### PARSE\n";
  my $mod_obj = $cb->parse_module(module=>$name);

  warn ">> ########### UNINSTALL\n";
  my $rv = $mod_obj->uninstall(type=>'all');
  warn ">> result:uninstall=" . ($rv//'undef') . "\n";
  $success = 0 unless $rv;
}

die ">> FAILUE\n" unless $success;

warn ">> done!\n";
exit 0;
