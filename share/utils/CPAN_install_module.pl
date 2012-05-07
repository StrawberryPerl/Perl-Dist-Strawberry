use 5.012;
use warnings;

use CPAN;
use File::Spec::Functions qw(catfile);
use Getopt::Long;

my @spec = (
    'module=s@',
    'url=s',
    'dp_dir=s',
    'install_to=s',
    'dist_file=s',
    'output_dir=s',
    'use_sqlite=i',
    'run_tests=i',
    'follow_deps=i',
    'internet=i',
    'assume=i',
);
my %a = ();
GetOptions(\%a, @spec) or die ">> invalid option(s)";

#defaults
$a{module}      //= [];
$a{install_to}  //= '';
$a{url}         //= 'http://cpan.strawberryperl.com';
$a{run_tests}   //= 1,
$a{follow_deps} //= 1;

$a{internet}    //= 1;
$a{assume}      //= 0;
$a{dp_dir}      //= 'c:\temp\xxx';
$a{dist_file}   //= 'c:\temp\xxx.dist.file.txt';
$a{output_dir}  //= 'c:\temp\xxx';
$a{use_sqlite}  //= 0;
$a{force}       //= 0;

my $module_list = '';

CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
$CPAN::Config->{'urllist'}     = [ $a{url} ];
$CPAN::Config->{'use_sqlite'}  = $a{use_sqlite};
$CPAN::Config->{'prefs_dir'}   = $a{dp_dir};
$CPAN::Config->{'patches_dir'} = $a{dp_dir};
if ($a{follow_deps}) {
  $CPAN::Config->{'prerequisites_policy'} = q[follow];
}
else {
  $CPAN::Config->{'prerequisites_policy'} = q[ignore];
}
$CPAN::Config->{'connect_to_internet_ok'} = $a{internet};
$CPAN::Config->{'ftp'} = q[];
if ($a{install_to} =~ /(perl|site|vendor)/) {
  my $module_build_dirs = $a{install_to};
  $module_build_dirs = 'core' if $module_build_dirs eq 'perl';
  $CPAN::Config->{'makepl_arg'}         = "INSTALLDIRS=$a{install_to}";
  $CPAN::Config->{'make_install_arg'}   = "INSTALLDIRS=$a{install_to}";
  $CPAN::Config->{'mbuildpl_arg'}       = "--installdirs $module_build_dirs";
  $CPAN::Config->{'mbuild_install_arg'} = "--installdirs $module_build_dirs";
}
open(my $cpan_fh, '>', $a{dist_file}) or die ">> open: $!";
MODULE:
foreach my $name (@{$a{module}}) {
  warn ">> Installing $name from CPAN...\n";
  my $module = CPAN::Shell->expandany($name) or die ">> CPAN.pm couldn't locate $name";

  if ( $module->uptodate() ) {
    unlink $a{dist_file};
    warn ">> $name is up to date\n";
    say $cpan_fh "$name;;;" or die ">> say: $!";
    next MODULE;
  }
  eval {
    if ($a{run_tests} == 1) {
      CPAN::Shell->install($name);
    }
    elsif ($a{run_tests} == 2) {
      CPAN::Shell->force('install', $name);
    }
    elsif ($a{run_tests} == 0) {
      CPAN::Shell->notest('install', $name);
    }
    else {
      die "invalid run_tests";
    }
  };
  my $error = $@;
       
       #XXX-FIXME probably not needed
       #my $id = $module->distribution()->pretty_id();
       #my $time = time;
       #my $module_id = $name;
       #$module_id =~ s{::}{_}gmsx;
       #my $filename = catfile('$output_dir', "$time.$module_id.output.txt");
       #write_file($filename, $output);
       #die "Installation of $name failed: $error\n" if $error;
       #say $cpan_fh "$name;$id;$filename;"  or die "say: $!";
       
  warn ">> Completed install of '$name'\n";
  warn ">> ERROR=$error" if $error;
  die ">> Installation of '$name' appears to have failed\n" unless $a{assume} or $module->uptodate();
}
close $cpan_fh or die ">> close: $!";
exit 0;
