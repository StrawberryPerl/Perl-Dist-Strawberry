use v5.18;
use warnings;

use CPANPLUS::Backend;
use Storable              qw(nstore);
use Data::Dumper          qw(Dumper);
use Getopt::Long          qw(:config gnu_getopt no_ignore_case);
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

GetOptions(\my %opts, @spec) or die ">> invalid option(s)";

# defaults
$opts{module}      //= [];
$opts{install_to}  //= '';
$opts{url}         //= 'http://cpan.strawberryperl.com';
$opts{verbose}     //= 1;
$opts{skiptest}           //= 0; # 1 = do not run 'test' at all
$opts{ignore_testfailure} //= 0; # 1 = if 'test' fails continue with 'install'
$opts{ignore_uptodate}    //= 0; # 1 = install even if the module is already uptodate
$opts{prereqs}            //= 1; # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
$opts{interactivity}      //= 0; # 1 = allow_build_interactivity
$opts{makefilepl_param}   //= '';
$opts{buildpl_param}      //= '';
$opts{signature}          //= 0; # 0 = ignore signature, 1 = check signature if available

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
            $conf->set_conf('hosts', [ {scheme => $scheme, path => $path, host => $host} ]);
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

die ">> invalid install_to option" if $opts{install_to} && $opts{install_to} !~ /(perl|site|vendor)/;
die ">> invalid prereqs option (only 0, 1 or 3 allowed)" if defined $opts{prereqs} && $opts{prereqs} !~ /^(0|1|3)$/;
die ">> no modules specified" unless scalar(@{$opts{module}});

my %cfg = (
    allow_build_interactivity => $opts{interactivity},
    prereqs => $opts{prereqs},
    verbose => $opts{verbose},
    signature => $opts{signature},
);

my (@mm, @mb);
if ($opts{install_to}) {
    push @mm, "INSTALLDIRS=" . $opts{install_to};
    push @mb, "--installdirs " . ($opts{install_to} eq 'perl' ? 'core' : $opts{install_to});
}
push @mm, $opts{makefilepl_param} if $opts{makefilepl_param};
push @mb, $opts{buildpl_param}    if $opts{buildpl_param};

$cfg{makemakerflags} = join(" ", @mm);
$cfg{buildflags}     = join(" ", @mb);

my $success = 1;
my $cb = get_cpanplus_backend( url => $opts{url}, %cfg );

for my $name (@{$opts{module}}) {
    warn ">> Installing '$name'\n";
    warn ">> ########### PARSE\n";
    my $mod_obj = $cb->parse_module(module=>$name);
    warn ">> is_uptodate=", $mod_obj->is_uptodate, "\n";
    next if $mod_obj->is_uptodate && !$opts{ignore_uptodate};

    #XXX-FIXME does not follow prereqs=>0
    #warn ">> ########### PREPARE\n";
    #warn ">> result:prepare=", $mod_obj->install(target=>'prepare', verbose=>$opts{verbose}, prereqs=>0, prereq_build=>0), "\n";

    #XXX-FIXME do not know how to prevent double building during create & install
    #warn ">> ########### CREATE\n";
    #warn ">> result:create=", $mod_obj->install(target=>'create',  verbose=>$opts{verbose}, skiptest=>$opts{skiptest}), "\n";

    warn ">> ########### INSTALL\n";
    my $rv_install = $mod_obj->install(skiptest => $opts{skiptest}, force => $opts{ignore_testfailure});
    warn ">> result:install=" . ($rv_install // 'undef') . "\n";
    $success = 0 unless $rv_install;

    #XXX-TODO: try somehow distinguish: build failure / test failure
}

die ">> FAILUE\n" unless $success;

warn ">> done!\n";
exit 0;
