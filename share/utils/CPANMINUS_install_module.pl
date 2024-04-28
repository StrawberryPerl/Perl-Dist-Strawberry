use v5.18;
use warnings;

use Carp                  qw( croak );
use Config;
use Data::Dumper          qw(Dumper);
use File::Spec::Functions qw(catfile);
use File::Temp            qw( tempfile );
use FindBin;
use Getopt::Long          qw(:config gnu_getopt no_ignore_case);
use IPC::Run3;
use Storable              qw(nstore);
use Syntax::Keyword::Try;

warn ">> started '$0'\n";

# parse commandline options
my @spec = (
    'module=s@',
    'install_to=s',
    'url=s',
    'verbose=i',
    'skiptest=i',
    'uninstall=i',
    'ignore_testfailure=i',
    'ignore_uptodate=i',
    'prereqs=i',
    'interactivity=i',
    'makefilepl_param=s',
    'buildpl_param=s',
    'signature=i',
    'out_dumper=s',
    'out_nstore=s',
);
GetOptions(\my %opts, @spec) or die ">> invalid option(s)";

# defaults
$opts{module}      //= [];
$opts{install_to}  //= '';
$opts{url}         //= ''; #'http://cpan.strawberryperl.com';
$opts{verbose}     //= 1;
$opts{uninstall}   //= 0;
$opts{skiptest}           //= 0; # 1 = do not run 'test' at all
$opts{ignore_testfailure} //= 0; # 1 = if 'test' fails continue with 'install'
$opts{ignore_uptodate}    //= 0; # 1 = install even if the module is already uptodate
$opts{prereqs}            //= 1; # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
$opts{interactivity}      //= 0; # 1 = allow_build_interactivity
$opts{makefilepl_param}   //= '';
$opts{buildpl_param}      //= '';
$opts{signature}          //= 0; # 0 = ignore signature, 1 = check signature if available
$opts{out_dumper}         //= "install-log.$$.dumper.txt";
$opts{out_nstore}         //= "install-log.$$.nstore.txt";

$opts{url} =~ s|/$||;
for (@{$opts{module}}) {
    $_ =~ s/-/::/g unless $_ =~ /[\/\.]/;
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

die ">> invalid install_to option" if $opts{install_to} && $opts{install_to} !~ /(perl|site|vendor)/;
die ">> invalid prereqs option (only 0, 1 or 3 allowed)" if defined $opts{prereqs} && $opts{prereqs} !~ /^(0|1|3)$/;
die ">> no modules specified" unless scalar(@{$opts{module}});

my $success = 1;
my $env = {};
my @args = ($^X, "$FindBin::Bin/cpanm");

push @args, @{$opts{module}};
push @args, '--verbose'         if $opts{verbose};
push @args, '--notest'          if $opts{skiptest};
push @args, '--force'           if $opts{ignore_testfailure};
push @args, '--reinstall'       if $opts{ignore_uptodate};
push @args, '--interactive'     if $opts{interactivity};
push @args, '--uninstall'       if $opts{uninstall};
push @args, '--mirror', $opts{url}, '--mirror-only' if $opts{url};
push @args, '--configure-args', ($opts{buildpl_param} || $opts{makefilepl_param}) if $opts{makefilepl_param} || $opts{buildpl_param};

if ($opts{install_to} eq 'site') {
  $env->{PERL_MM_OPT} = "INSTALLDIRS=site UNINST=1";      # INSTALL_BASE=$Config{sitelibexp}
  $env->{PERL_MB_OPT} = "--installdirs=site --uninst=1";  # --install_base=$Config{vendorlibexp}
}
elsif ($opts{install_to} eq 'vendor') {
  $env->{PERL_MM_OPT} = "INSTALLDIRS=vendor UNINST=1";    # INSTALL_BASE=$Config{vendorlibexp}
  $env->{PERL_MB_OPT} = "--installdirs=vendor uninst=1";  # --install_base=$Config{vendorlibexp}
}
elsif ($opts{install_to} eq 'perl' || $opts{install_to} eq 'core') {
  $env->{PERL_MM_OPT} = "INSTALLDIRS=perl UNINST=1";      # INSTALL_BASE=$Config{vendorlibexp}
  $env->{PERL_MB_OPT} = "--installdirs=core --uninst=1";  # --install_base=$Config{vendorlibexp}
}
else {
  $env->{PERL_MM_OPT} = 'UNINST=1';
  $env->{PERL_MB_OPT} = '--uninst=1';
}

### --configure-args, --build-args, --test-args, --install-args
# $opts{prereqs}            //= 1; # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
# $opts{signature}          //= 0; # 0 = ignore signature, 1 = check signature if available

my ($exit_code, $out);
{
    my $rv;
    my %original_env = %ENV;
    local %ENV;
    %ENV = (%original_env, %$env);
    warn ">> ", join ' ', @{$opts{module}}, "\n";
    $rv = IPC::Run3::run3(\@args, \undef, \$out, \$out);
    $exit_code = $? // -666;
    $success = $rv && $exit_code == 0 ? 1 : 0;
}

say "###\n", $out, "###";
say "###\n", Dumper(\@args), "###";

my @list = split /[\n\r]+/, $out;
@list = map { s/[\r\n]*$//; $_ } @list;
@list = grep { /^Successfully (re)?installed (\S+)/ } @list;
@list = map { s/^Successfully (re)?installed (\S+).*$/$2/; $_ } @list;

save_output({installed => \@list, success=>$success}, $opts{out_nstore}, $opts{out_dumper});
die ">> FAILUE [exit_code=$exit_code]\n" unless $success;
warn ">> done!\n";
exit 0;
