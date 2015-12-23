package Perl::Dist::Strawberry::Step::InstallPerlCore;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use Data::Dump qw(pp);
use Archive::Zip           qw( AZ_OK );
use Archive::Tar           qw();
use File::Spec::Functions  qw(catdir catfile rel2abs catpath splitpath);
use File::Find::Rule;
use File::Path             qw(make_path remove_tree);
use File::Copy             qw(copy);
use File::Glob             qw(bsd_glob);
use File::Slurp;
use Text::Patch;
use Text::Diff;
#use Win32;

sub check {
  my $self = shift;
  my ($rv, $out);
}

sub run {
  my $self = shift;
  my $image_dir = $self->global->{image_dir};

  # Log execute_special's environment
  $self->execute_special('set', catfile($self->global->{debug_dir}, 'perl_set.log.txt'));

  # Get the initial directory contents to compare against later.
  $self->boss->message( 0, 'Preparing '.__PACKAGE__."\n" );
  my $dir = catdir($image_dir, 'perl');
  make_path($dir) unless -d $dir;

  # Download the perl tarball if needed.
  my $tgz = $self->boss->mirror_url( $self->{config}->{url}, $self->global->{download_dir} );

  # Unpack to the build directory
  my $unpack_to = catdir( $self->global->{build_dir}, 'perl_core' );  
  if ( -d $unpack_to ) {
    $self->boss->message( 2, "Removing previous '$unpack_to'\n" );
    remove_tree($unpack_to);
  }
  my @files = $self->_extract( $tgz, $unpack_to );

  # Get the versioned name of the directory
  my $perlsrc;
  for (glob("$unpack_to/*")) {
    $perlsrc = File::Basename::basename($_) if -d $_;
  }
  die "ERROR: cannot detect perl-src dir" unless $perlsrc;
 
  #get verion string - e.g. '5.15.9'
  my ($version) = grep { /INST_VER/ } read_file(catfile($unpack_to, $perlsrc, qw/win32 makefile.mk/));
  $version =~ s/^.*?(5\..*?)[\r\n]*$/$1/;

  # some handy variables
  my $app_id = $self->global->{app_simplename} // 'perl';
  my $app_ver = $self->global->{app_version} // $version;
  $app_ver .= "-beta".$self->global->{beta} if $self->global->{beta};
  my $now = scalar(localtime);
  my $arch = $self->global->{bits} == 64 ? 'x64' : 'i386';
  my $cf_email = $self->{config}->{cf_email} // 'builder@somewhere.com',
  
  # prepare dta used for template (TT) processing
  my $tt_vars = {
        %{$self->global},
        myuname => "Win32 $app_id $app_ver #1 $now $arch",
  };

  # Patch perl source
  my $patch = $self->{config}->{patch};
  if ($patch) {
    while (my ($new, $dst) = each %$patch) {
      $self->_patch_file($self->boss->resolve_name($new), catfile($unpack_to, $perlsrc, $dst), catdir($unpack_to, $perlsrc), $tt_vars);
    }
  }
  
  # keep *.diff files
  my @items = File::Find::Rule->file->relative->name('*.diff')->in($unpack_to);
  for (@items) {
    my $src = catfile($unpack_to, $_);
    my $dst = $_;
    $dst =~ s/[\\\/]/_/g;
    $dst = catfile($self->global->{debug_dir}, $dst);
    copy($src, $dst) or die "ERROR: copy '$src' > '$dst' failed";
  }

  # Copy in licenses
  if ( ref $self->{config}->{license} eq 'HASH' ) {
    my $licenses = $self->{config}->{license};
    foreach my $key ( keys %{$licenses} ) {
      my $src = catfile($unpack_to, $perlsrc, $key);
      my $dst = $self->boss->resolve_name($licenses->{$key});
      my ($volume,$directories) = splitpath($dst);
      make_path(catdir($volume,$directories));
      copy($src, $dst) or die "ERROR: copy '$src' > '$dst' failed";
    }
  }
  
  # extract global settings passed from commandline
  my $dbg = defined $self->global->{perl_debug}    ? $self->global->{perl_debug}    : ($self->{config}->{perl_debug}    // 0);
  my $uld = defined $self->global->{perl_ldouble}  ? $self->global->{perl_ldouble}  : ($self->{config}->{perl_ldouble}  // 0);
  my $u64 = defined $self->global->{perl_64bitint} ? $self->global->{perl_64bitint} : ($self->{config}->{perl_64bitint} // $self->{config}->{use_64_bit_int} // 0);
  # XXX use_64_bit_int is for backwards compatibility

  # Build win32 perl
  SCOPE: {
    my $wd = $self->_push_dir( $unpack_to, $perlsrc, 'win32' );
    my $INST_TOP   = catdir( $image_dir, 'perl' );
    my $CCHOME     = catdir( $image_dir, 'c' );
    my ($INST_DRV) = splitpath( $INST_TOP, 1 );
    my ($new_env, $log);

    # necessary workaround for building 32bit perl on 64bit Windows
    my @make_args = ("INST_DRV=$INST_DRV", "INST_TOP=$INST_TOP", "CCHOME=$CCHOME", "EMAIL=$cf_email");
    push @make_args, 'GCC_4XX=define', 'GCCHELPERDLL=$(CCHOME)\bin\libgcc_s_sjlj-1.dll'; #perl-5.12/14 only

    # enable debug build
    push @make_args, 'CFG=Debug' if $dbg > 0;
    
    # enable 64bit ints on 32bit perl
    push @make_args, 'USE_64_BIT_INT=define' if $u64 && $self->global->{bits} == 32;
    # enable long doubles
    push @make_args, 'USE_LONG_DOUBLE=define' if $uld;
    # enable BUILDOPTEXTRA
    push @make_args, "BUILDOPTEXTRA=$self->{config}->{buildoptextra}" if $self->{config}->{buildoptextra};

    $new_env->{USERNAME} = (split /@/, $cf_email)[0]; # trick to set correct cf_by
    my @extralibs;
    if (my $extra1 = catdir((bsd_glob("$CCHOME/*-mingw32/lib"))[0])) {
      push @extralibs, $extra1 if -d $extra1;
    }
    if (my $extra2 = catdir((bsd_glob("$CCHOME/lib/gcc/*-mingw32/*"))[0])) {
      push @extralibs, $extra2 if -d $extra2;
    }
    push @make_args, "EXTRALIBDIRS=" . join(';', @extralibs) if @extralibs;
    if ($self->global->{bits} == 64) {
      $new_env->{PROCESSOR_ARCHITECTURE} = 'AMD64';
    }
    else {
      $new_env->{PROCESSOR_ARCHITECTURE} = 'x86';
      push @make_args, 'WIN64=undef';
    }

    #create debuging build scripts in 'win32' subdir
    my $set_simple_path = "set PATH=$image_dir\\c\\bin;\%SystemRoot\%\\system32;\%SystemRoot\%";
    write_file('_do_dmake.bat', $set_simple_path."\n".join(' ', 'dmake', @make_args).' %*');
    write_file('_do_dmake_install.bat', $set_simple_path."\n".join(' ', 'dmake', @make_args, 'install'));
    write_file('_do_dmake_test.bat', $set_simple_path."\n".join(' ', 'dmake', @make_args, 'test'));

    # Compile perl.
    my $rv;
    $self->boss->message( 1, "Building perl $version (dbg=$dbg, u64=$u64, uld=$uld)...\n" );
    $log = catfile($self->global->{debug_dir}, 'perl_dmake_all.log.txt');

    if ($self->global->{bits} == 64) {
      #XXX-FIXME-XXX 'dmake all' fails with redirected output for 64bit build via IPC::Run3
      $rv = $self->execute_special(['dmake', @make_args, 'all'], undef, undef, $new_env);
    }
    else {
      $rv = $self->execute_special(['dmake', @make_args, 'all'], $log, $log, $new_env);
    }

    die "FATAL: dmake all FAILED!" unless(defined $rv && $rv == 0);

    # Get information required for testing and installing perl.
    #my $long_build = Win32::GetLongPathName( rel2abs( $self->global->{build_dir} ) );

    # Testing perl if requested.
    if ($self->global->{test_core}) {
      $new_env->{PERL_SKIP_TTY_TEST} = 1;
      $self->boss->message( 1, "Testing perl $version ...\n" );
      $log = catfile($self->global->{debug_dir}, 'perl_dmake_test.log.txt');
      $self->execute_special(['dmake', @make_args, 'test'], $log, $log, $new_env);
      $self->boss->message( 1, "dmake test FAILED!") unless(defined $rv && $rv == 0);
    }

    # Installing perl.
    $self->boss->message( 1, "Installing perl $version ...\n" );
    $log = catfile($self->global->{debug_dir}, 'perl_dmake_install.log.txt');
    $rv = $self->execute_special(['dmake', @make_args, 'install', 'UNINST=1'], $log, $log, $new_env);
    die "FATAL: dmake install FAILED!" unless(defined $rv && $rv == 0);
  }
  
  # Debug version with separated debug symbols [EXPERIMENTAL]
  if ($dbg > 1) {
    my @bin = File::Find::Rule->file->name('*perl*.dll', 'perl.exe', 'wperl.exe', 'perl5*.exe')->in("$image_dir\\perl\\bin");
    my @lib = File::Find::Rule->file->name('*.dll')->in("$image_dir\\perl\\lib");

    my $ch = "$image_dir\\perl\\lib\\Config_heavy.pl";
    my $ch_content = read_file($ch, {binmode=>':raw'});
    $ch_content =~ s/(ccflags|optimize|ccflags_nolargefiles)(=.*?)-g -O2 -DDEBUGGING/$1$2-s -O2/sg;
    $ch_content =~ s/(lddlflags|ldflags|ldflags_nolargefiles)(=.*?)-g /$1$2-s /sg;

    if ($dbg eq '2') {
      $self->_strip_debug($_, 1) for (@bin); #keep *.debug files
      $self->_strip_debug($_, 1) for (@lib); #keep *.debug files
      my $ro = $self->_unset_ro($ch);
      write_file($ch, {binmode=>':raw'}, $ch_content);
      $self->_restore_ro($ch, $ro);
    }
    if ($dbg eq '3') {
      $self->_strip_debug($_, 1) for (@bin);
      $self->_strip_debug($_, 0) for (@lib); #do not keep *.debug files
      my $ro = $self->_unset_ro($ch);
      write_file($ch, {binmode=>':raw'}, $ch_content);
      $self->_restore_ro($ch, $ro);
    }
  }

  # Delete unwanted dirs
  remove_tree("$image_dir/perl/html") if -d "$image_dir/perl/html";
  remove_tree("$image_dir/perl/man")  if -d "$image_dir/perl/man";
  
  # If using gcc4, copy the helper dll into perl's bin directory.
  my $from;
  $from = catfile($image_dir, qw/c bin libgcc_s_sjlj-1.dll/);
  copy($from, catfile($image_dir, qw/perl bin libgcc_s_sjlj-1.dll/)) if -f $from;
  $from = catfile($image_dir, qw/c bin libstdc++-6.dll/);
  copy($from, catfile($image_dir, qw/perl bin libstdc++-6.dll/)) if -f $from;
  $from = catfile($image_dir, qw/c bin libwinpthread-1.dll/);
  copy($from, catfile($image_dir, qw/perl bin libwinpthread-1.dll/)) if -f $from;

  # Delete a2p.exe (Can't relocate a binary).
  my $a = catfile($image_dir, 'perl', 'bin', 'a2p.exe');
  if (-f $a) {
    $self->boss->message(3, "removing file '$a'");
    unlink $a or die "ERROR: Could not delete '$a'";
  }

  die "FATAL: perl.exe not properly installed" unless -f catfile($image_dir, qw/perl bin perl.exe/);
  
  # Create some missing directories
  my @d = ( catdir($image_dir, qw/perl vendor lib/),
            catdir($image_dir, qw/perl site bin/),
            catdir($image_dir, qw/perl site lib/) );
  for (@d) { make_path($_) unless -d $_; }
 
  # store some output data
  $self->{data}->{output}->{perl_version} = $version;
  
  #XXX-TODO store perl -V
  #$self->{data}->{output}->{perl_version} = `perl -V`;

  return 1;
}

sub test {
  #XXX-FIXME maybe some kind of post_check
}

sub _strip_debug {
  my ($self, $fullpath, $keep_debug) = @_;
  if ($keep_debug) {
    my $fullpath_dbg = "$fullpath.debug";
    my $ro = $self->_unset_ro($fullpath);
    
    ### not correct: warning: section .gnu_debuglink not found in C:\strawberry\perl\bin\perl520.dll.debug
    #$self->execute_standard(['objcopy', '--only-keep-debug', $fullpath, $fullpath_dbg]);
    #$self->execute_standard(['objcopy', '--strip-debug', $fullpath]);
    #$self->execute_standard(['objcopy', "--add-gnu-debuglink=$fullpath_dbg", $fullpath]);
    
    ### workaround from https://sourceware.org/bugzilla/show_bug.cgi?id=14527
    $self->execute_standard(['objcopy', '--only-keep-debug', $fullpath, $fullpath_dbg]);
    $self->execute_standard(['objcopy', "--add-gnu-debuglink=$fullpath_dbg", $fullpath]);
    $self->execute_standard(['objcopy', '--only-keep-debug', $fullpath, $fullpath_dbg]);
    $self->execute_standard(['objcopy', '--remove-section=.gnu_debuglink', $fullpath]);
    $self->execute_standard(['objcopy', '--strip-debug', $fullpath]);
    $self->execute_standard(['objcopy', "--add-gnu-debuglink=$fullpath_dbg", $fullpath]);
    
    $self->_restore_ro($fullpath, $ro);
  }
  else {
    my $ro = $self->_unset_ro($fullpath);
    $self->execute_standard(['objcopy', '--strip-debug', $fullpath]);
    $self->_restore_ro($fullpath, $ro);
  }
}

1;