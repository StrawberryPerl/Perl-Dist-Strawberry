use v5.18;
use warnings;

use CPAN;
use File::Spec::Functions qw(catfile);
use Getopt::Long qw(:config gnu_getopt no_ignore_case);

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
GetOptions(\my %opts, @spec) or die ">> invalid option(s)";

#defaults
$opts{module}      //= [];
$opts{install_to}  //= '';
$opts{url}         //= 'http://cpan.strawberryperl.com';
$opts{run_tests}   //= 1,
$opts{follow_deps} //= 1;

$opts{internet}    //= 1;
$opts{assume}      //= 0;
$opts{dp_dir}      //= 'c:\temp\xxx';
$opts{dist_file}   //= 'c:\temp\xxx.dist.file.txt';
$opts{output_dir}  //= 'c:\temp\xxx';
$opts{use_sqlite}  //= 0;
$opts{force}       //= 0;

my $module_list = '';

CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
$CPAN::Config->{'urllist'}     = [ $opts{url} ];
$CPAN::Config->{'use_sqlite'}  = $opts{use_sqlite};
$CPAN::Config->{'prefs_dir'}   = $opts{dp_dir};
$CPAN::Config->{'patches_dir'} = $opts{dp_dir};
if ($opts{follow_deps}) {
    $CPAN::Config->{'prerequisites_policy'} = q[follow];
}
else {
    $CPAN::Config->{'prerequisites_policy'} = q[ignore];
}
$CPAN::Config->{'connect_to_internet_ok'} = $opts{internet};
$CPAN::Config->{'ftp'} = q[];
if ($opts{install_to} =~ /(perl|site|vendor)/) {
    my $module_build_dirs = $opts{install_to};
    $module_build_dirs = 'core' if $module_build_dirs eq 'perl';
    $CPAN::Config->{'makepl_arg'}         = "INSTALLDIRS=$opts{install_to}";
    $CPAN::Config->{'make_install_arg'}   = "INSTALLDIRS=$opts{install_to}";
    $CPAN::Config->{'mbuildpl_arg'}       = "--installdirs $module_build_dirs";
    $CPAN::Config->{'mbuild_install_arg'} = "--installdirs $module_build_dirs";
}
open(my $cpan_fh, '>', $opts{dist_file}) or die ">> open: $!";
MODULE:
foreach my $name (@{$opts{module}}) {
    warn ">> Installing $name from CPAN...\n";
    my $module = CPAN::Shell->expandany($name) or die ">> CPAN.pm couldn't locate $name";

    if ( $module->uptodate() ) {
        unlink $opts{dist_file};
        warn ">> $name is up to date\n";
        say $cpan_fh "$name;;;" or die ">> say: $!";
        next MODULE;
    }

    my $error;
    {
        local $@;
        $error = $@ || 'Error' unless eval {
            if ($opts{run_tests} == 1) {
                CPAN::Shell->install($name);
            }
            elsif ($opts{run_tests} == 2) {
                CPAN::Shell->force('install', $name);
            }
            elsif ($opts{run_tests} == 0) {
                CPAN::Shell->notest('install', $name);
            }
            else {
                die "invalid run_tests";
            }
            1;
        };
    }
    #XXX-FIXME probably not needed
    #my $id = $module->distribution()->pretty_id();
    #my $time = time;
    #my $module_id = $name;
    #$module_id =~ s{::}{_}gmsx;
    #my $filename = catfile('$output_dir', "$time.$module_id.output.txt");
    #write_file($filename, $output);
    #die "Installation of $name failed: $error\n" if $error;
    #say $cpan_fh "$name;$id;$filename;"  or die "say: $!";

    warn ">> ERROR=$error" if $error;
    warn ">> Completed install of '$name'\n";
    die ">> Installation of '$name' appears to have failed\n" unless $opts{assume} or $module->uptodate();
}
close $cpan_fh or die ">> close: $!";
exit 0;
