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
    'install_to=s',
    'url=s',
    'verbose=i',
    'skiptest=i',
    'ignore_testfailure=i',
    'ignore_uptodate=i',
    'prereqs=i',
    'interactivity=i',
    'makefilepl_param=s',
    'buildpl_param=s',
    'signature=i',
);
my %a = ();
GetOptions(\%a, @spec) or die ">> invalid option(s)";

# defaults
$a{module}      //= [];
$a{install_to}  //= '';
$a{url}         //= 'http://cpan.strawberryperl.com';
$a{verbose}     //= 1;
$a{skiptest}           //= 0; # 1 = do not run 'test' at all
$a{ignore_testfailure} //= 0; # 1 = if 'test' fails continue with 'install'
$a{ignore_uptodate}    //= 0; # 1 = install even if the module is already uptodate
$a{prereqs}            //= 1; # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
$a{interactivity}      //= 0; # 1 = allow_build_interactivity
$a{makefilepl_param}   //= '';
$a{buildpl_param}      //= '';
$a{signature}          //= 0; # 0 = ignore signature, 1 = check signature if available

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

die ">> invalid install_to option" if $a{install_to} && $a{install_to} !~ /(perl|site|vendor)/;
die ">> invalid prereqs option (only 0, 1 or 3 allowed)" if defined $a{prereqs} && $a{prereqs} !~ /^(0|1|3)$/;
die ">> no modules specified" unless scalar(@{$a{module}});

my %cfg = (
    allow_build_interactivity => $a{interactivity},
    prereqs => $a{prereqs},
    verbose => $a{verbose},
    signature => $a{signature},
);

my (@mm, @mb);
if ($a{install_to}) {
  push @mm, "INSTALLDIRS=" . $a{install_to};
  push @mb, "--installdirs " . ($a{install_to} eq 'perl' ? 'core' : $a{install_to});
}
push @mm, $a{makefilepl_param} if $a{makefilepl_param};
push @mb, $a{buildpl_param}    if $a{buildpl_param};

$cfg{makemakerflags} = join(" ", @mm);
$cfg{buildflags}     = join(" ", @mb);

my $success = 1;
my $cb = get_cpanplus_backend( url=>$a{url}, %cfg );

for my $name (@{$a{module}}) {
  warn ">> Installing '$name'\n";
  warn ">> ########### PARSE\n";
  my $mod_obj = $cb->parse_module(module=>$name);
  warn ">> is_uptodate=", $mod_obj->is_uptodate, "\n";
  next if $mod_obj->is_uptodate && !$a{ignore_uptodate};
  
  #XXX-FIXME does not follow prereqs=>0
  #warn ">> ########### PREPARE\n";
  #warn ">> result:prepare=", $mod_obj->install(target=>'prepare', verbose=>$a{verbose}, prereqs=>0, prereq_build=>0), "\n";
  
  #XXX-FIXME do not know how to prevent double building during create & install
  #warn ">> ########### CREATE\n";
  #warn ">> result:create=", $mod_obj->install(target=>'create',  verbose=>$a{verbose}, skiptest=>$a{skiptest}), "\n";

  warn ">> ########### INSTALL\n";
  my $rv_install = $mod_obj->install(skiptest=>$a{skiptest}, force=>$a{ignore_testfailure});
  warn ">> result:install=" . ($rv_install//'undef') . "\n";
  $success = 0 unless $rv_install;
  
  #XXX-TODO: try somehow distinguish: build failure / test failure
}

die ">> FAILUE\n" unless $success;

warn ">> done!\n";
exit 0;
