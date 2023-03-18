package Perl::Dist::Strawberry::Step;

use 5.012;
use warnings;

use Data::Dump qw(pp);
use Archive::Zip           qw( AZ_OK );
use Archive::Tar           qw();
use File::Spec::Functions  qw(catdir catfile rel2abs catpath splitpath canonpath);
use File::Path             qw(make_path remove_tree);
use File::Copy             qw(copy);
use Storable               qw(retrieve);
use Template;
use File::Slurp;
use Text::Diff;
use Win32;
use Win32::File::Object;
use IPC::Run3;
use Digest::SHA1;

##### mandatory methods for all Step-like classes - new(), check(), run(), test()

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  return $self;
}

sub run {
  my $self = shift;
  die "ERROR: starting generic implementation run() for '", ref($self), "' - override run() in your class\n";
}

sub test {
  my $self = shift;
  warn "WARNING: no 'data' found (we are gonna continue)", ref($self), "\n" unless defined $self->{data}
}

sub check {
  my $self = shift;
  die "no 'config' found" unless $self->{config};
  die "invalid 'config' - hashref expected" unless ref $self->{config} eq 'HASH';
}

#####

sub boss {
  shift->{boss};
}

sub global { # accessor to global data
  return shift->{boss}->global;
}

sub insert_fragment {
  my ($self, $name, $filelist) = @_;
}

sub _push_dir { #XXX-FIXME maybe without leading _
  my $self = shift;
  my $dir  = catdir(@_);
  $self->boss->message(6, "Lexically changing directory to '$dir'");
  return File::pushd::pushd($dir);
}

sub _extract_filemap {
  my ($self, $archive, $filemap, $basedir, $file_only) = @_;

  my @files;

  if ($archive =~ /\.zip$/i) {
    @files = $self->_extract_filemap_zip( $archive, $filemap, $basedir, $file_only );
  }
  elsif ( $archive =~ /\.(tar\.gz|tgz|tar\.bz2|tbz|tar)$/i ) {
    local $Archive::Tar::CHMOD = 0;
    my $tar = Archive::Tar->new($archive);
    for my $file ( $tar->get_files() ) {
      my $f       = $file->full_path();
      my $canon_f = File::Spec::Unix->canonpath($f);
      for my $tgt ( keys %{$filemap} ) {
        my $canon_tgt = File::Spec::Unix->canonpath($tgt);
        my $t;
        if ($file_only) {
          next if $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E\z}imsx;
          ( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}{$filemap->{$tgt}}imsx;
        }
        else {
          next if $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E}imsx;
          ( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}{$filemap->{$tgt}}imsx;
        }
        my $full_t = catfile( $basedir, $t );
        $self->boss->message( 2, "* extracting $f to $full_t\n" );
        $tar->extract_file( $f, $full_t );
        push @files, $full_t;
      }
    }
  }
  elsif ( $archive =~ /\.(tar\.xz|txz)$/ ) {
    # First attempt at trying to use .xz files. TODO: Improve.
    eval {
      require IO::Uncompress::UnXz;
      IO::Uncompress::UnXz->VERSION(2.025);
      1;
    } or die "Tried to extract the file $archive without the xz libraries installed";
    local $Archive::Tar::CHMOD = 0;
    my $xz = IO::Uncompress::UnXz->new( $archive, BlockSize => 16_384 );
    my $tar = Archive::Tar->new($xz);
    for my $file ( $tar->get_files() ) {
      my $f       = $file->full_path();
      my $canon_f = File::Spec::Unix->canonpath($f);
      for my $tgt ( keys %{$filemap} ) {
        my $canon_tgt = File::Spec::Unix->canonpath($tgt);
        my $t;
        if ($file_only) {
          next if
          $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E\z}imsx;
          ( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}{$filemap->{$tgt}}imsx;
        }
        else {
          next if
          $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E}imsx;
          ( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}{$filemap->{$tgt}}imsx;
        }
        my $full_t = catfile( $basedir, $t );
        $self->boss->message( 2, "* extracting $f to $full_t\n" );
        $tar->extract_file( $f, $full_t );
        push @files, $full_t;
      }
    }
  }
  else {
    die "Didn't recognize archive type for $archive";
  }

  return @files;
}

sub _extract_filemap_zip {
  my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

  my @files;
  my $zip = Archive::Zip->new($archive);
  my $wd  = $self->_push_dir($basedir);
  while ( my ( $f, $t ) = each %{$filemap} ) {
    $self->boss->message( 2, "* extracting $f to $t\n" );
    my $dest = catfile( $basedir, $t );

    my @members = $zip->membersMatching("^\Q$f");

    foreach my $member (@members) {
      my $filename = $member->fileName();
      $filename =~ s{\A\Q$f}{$dest}msx; # At the beginning of the string, change $f to $dest.
      $filename = _convert_name($filename);
      my $status = $member->extractToFileNamed($filename);

      die 'Error in archive extraction' if $status != AZ_OK;
      push @files, $filename;
    }
  }
  return @files;
}

sub _extract { #XXX-FIXME maybe remove leading _
  my ( $self, $from, $to ) = @_;
  File::Path::mkpath($to);
  my $wd = $self->_push_dir($to);

  my @filelist;

  $self->boss->message( 2, "* extracting '$from'" );
  if ( $from =~ /\.zip$/i ) {
    my $zip = Archive::Zip->new($from);
    die "Could not open archive $from for extraction" if !defined $zip;

    # I can't just do an extractTree here, as I'm trying to keep track of what got extracted.
    my @members = $zip->members();
    foreach my $member (@members) {
      my $filename = $member->fileName();
      $filename = _convert_name($filename); # Converts filename to Windows format.
      my $status = $member->extractToFileNamed($filename);
      die 'Error in archive extraction' if $status != AZ_OK;
      push @filelist, $filename;
    }
  }
  elsif ( $from =~ /\.(tar\.gz|tgz|tar\.bz2|tbz|tar)$/i ) {
    local $Archive::Tar::CHMOD = 0;
    my @fl = @filelist = Archive::Tar->extract_archive( $from, 1 );
    @filelist = map { catfile( $to, $_ ) } @fl;
    die 'Error in archive extraction' if !@filelist;
  }
  elsif ( $from =~ /\.(tar\.xz|txz)$/ ) {
    # First attempt at trying to use .xz files. TODO: Improve.
    eval {
      require IO::Uncompress::UnXz;
      IO::Uncompress::UnXz->VERSION(2.025);
      1;
    } or die "Tried to extract the file $from without the xz libraries installed";
    local $Archive::Tar::CHMOD = 0;
    my $xz = IO::Uncompress::UnXz->new( $from, BlockSize => 16_384 );
    my @fl = @filelist = Archive::Tar->extract_archive($xz);
    @filelist = map { catfile( $to, $_ ) } @fl;
    die 'Error in archive extraction' if !@filelist;
  }
  else {
    die "Didn't recognize archive type for $from";
  }

  return @filelist;
}

sub _convert_name {
  my $name     = shift;
  my @paths    = split m{\/}ms, $name;
  my $filename = pop @paths;
  $filename //= '';
  my $local_dirs = @paths ? catdir(@paths) : '';
  my $local_name = catpath('', $local_dirs, $filename);
  $local_name = rel2abs($local_name);
  return $local_name;
}

sub get_path_string {
  my $self = shift;

  my @p = ( catdir($self->global->{image_dir}, qw/perl site bin/),
            catdir($self->global->{image_dir}, qw/perl bin/),
            catdir($self->global->{image_dir}, qw/c bin/) );
  return join ';', @p;
}

sub execute_standard {
  my ($self, $cmd, $out, $err, $env) = @_;
  $err = $out if scalar(@_) <= 3;
  $env = {} unless $env;
  my %original_env = %ENV;
  local %ENV;
  %ENV = (%original_env, %$env);

  my $output_dir = $self->global->{output_dir};
  make_path($output_dir) unless -d $output_dir;

  # Execute the child process
  $self->boss->message(4, "execute_standard stdout='$out'\n") if $out;
  $self->boss->message(4, "execute_standard stderr='$err'\n") if $err;
  $self->boss->message(4, "execute_standard cmd=".pp($cmd)."\n");
  my $exit_code;
  my $rv = IPC::Run3::run3($cmd, \undef, $out, $err);
  $exit_code = $? if $rv;
  $self->boss->message(4, "execute_standard exit_code=$exit_code\n");
  return $exit_code;
}

sub execute_special {
  my ($self, $cmd, $out, $err, $env) = @_;
  $err = $out if scalar(@_) <= 3;
  $env = {} unless $env;
  my %original_env = %ENV;
  local %ENV;
  %ENV = (%original_env, %{$self->global->{build_ENV}}, %$env); #SPECIAL

  $self->boss->message(4, "execute_special PATH='$ENV{PATH}'\n");

  my $output_dir = $self->global->{output_dir};
  make_path($output_dir) unless -d $output_dir;

  # Execute the child process
  $self->boss->message(4, "execute_special stdout='$out'\n") if $out;
  $self->boss->message(4, "execute_special stderr='$err'\n") if $err;
  $self->boss->message(6, "execute_special env=".pp(\%ENV)."\n");
  $self->boss->message(4, "execute_special cmd=".pp($cmd)."\n");
  my $exit_code;
  my $rv = IPC::Run3::run3($cmd, \undef, $out, $err);
  $exit_code = $? if $rv;
  $self->boss->message(4, "execute_special exit_code=$exit_code\n");

  return $exit_code;
}

sub backup_file {
  my ($self, $file) = @_;
  return unless -f $file;
  my ($v, $d, $f) = splitpath(canonpath($file));
  my $now = time;
  my $new = File::Spec->catpath($v, $d, "OLD_$now.$f");
  $self->boss->message(3, "backup_file '$new'");
  rename($file, $new);
}

sub _patch_file {
  my ($self, $new, $dst, $dir, $tt_vars, $no_backup) = @_;
$self->boss->message(5, "PATCHING '$new' '$dst' '$dir' $tt_vars $no_backup\n");

if ($dst =~ /\*$/) {
    warn "WE IS PATCHIN '$new'";
}
  if ($new eq 'config_H.gc' and ref($dst) =~ /HASH/) {
    $self->boss->message(5, "_patch_file: using hash of values to update config_H.gc'\n");
    $self->_update_config_H_gc ("$dir/win32/config_H.gc", $dst);
  }
  elsif ($new eq 'config.gc' and ref($dst) =~ /HASH/) {
    $self->boss->message(5, "_patch_file: using hash of values to update config.gc'\n");
    $self->_update_config_gc ("$dir/win32/config.gc", $dst);
  }
  elsif (!-f $new) {
    warn "ERROR: non-existing file '$new'";
  }
  elsif ($new =~ /\.tt$/) {
    $self->boss->message(5, "_patch_file: applying template on '$dst'\n");
    copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
    my $indata = read_file($new);
    my $outdata = '';
    my $template = Template->new();
    write_file(catfile($self->global->{debug_dir}, 'TTvars_patch_file_'.time.'.txt'), pp($tt_vars)); #debug dump
    $template->process(\$indata, $tt_vars, \$outdata) || die $template->error();

    my $r = $self->_unset_ro($dst);
    write_file($dst, $outdata);
    $self->_restore_ro($dst, $r);

    write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
  }
  elsif ($new =~ /\.(diff|patch)$/ && $dst =~ /\*$/) {
    $self->boss->message(5, "_patch_file: applying DIFF on dir '$dir'\n");
    #$self->_apply_patch($dir, $new);
    {
      my $wd = $self->_push_dir($dir);
      system("patch -i $new -p1") == 0 or die "patch '$new' FAILED";
    }
  }
  elsif ($new =~ /\.(diff|patch)$/) {
    $self->boss->message(5, "_patch_file: applying DIFF on '$dst'\n");
    copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
    my $diff = read_file($new);
    my $indata = read_file($dst);
    my $outdata = patch($indata, $diff, STYLE=>"Unified");

    my $r = $self->_unset_ro($dst);
    write_file($dst, $outdata);
    $self->_restore_ro($dst, $r);

    write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
  }
  else {
    $self->boss->message(5, "_patch_file: copying to '$dst'\n");
    copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";

    my $r = $self->_unset_ro($dst);
    copy($new, $dst) or warn "ERROR: copy failed";
    $self->_restore_ro($dst, $r);

    write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
  }
}

sub _unset_ro { #XXX-todo used from more modules, perhaps remove leading _
  my ($self, $to) = @_;
  return undef unless -f $to;
  my $file = Win32::File::Object->new($to, 1);
  my $readonly = $file->readonly();
  $file->readonly(0);
  return $readonly;
}

sub _restore_ro {
  my ($self, $to, $ro) = @_;
  return unless -f $to;
  return unless defined $ro;
  my $file = Win32::File::Object->new($to, 1);
  $file->readonly($ro);
}

sub sha1_file {
  my ($self, $file) = @_;
  my $sha1 = Digest::SHA1->new;
  open FILE, '<', $file or die "ERROR: open failed";
  binmode FILE;
  $sha1->addfile(*FILE);
  close FILE;
  return $sha1->hexdigest;
}

sub install_modlist {
  my ($self, @list) = @_;

  return 1 unless @list;
  my $success = 1;
  my @distlist_final = ();

  $self->boss->message(1, "NOTE: global option test_modules=0 (all tests will be skipped") unless $self->global->{test_modules};

  my ($distlist, $rv);
  my $count = scalar(@list);
  my $i = 0;
  for my $item (@list) {
    $i++;
    $item = { module=>$item } unless ref $item; # if item is scalar we assume module name
    my $name = $item->{module};
    if ($name) {
      my @msg;
      push @msg, 'IGNORE_TESTFAILURE' if $item->{ignore_testfailure};
      push @msg, 'SKIPTEST' if $item->{skiptest};
      $self->boss->message(1, sprintf("installing %2d/%d '%s' \t".join(' ',@msg), $i, $count, $name));
      ($distlist, $rv) = $self->_install_module(%$item);
      push @distlist_final, @$distlist;
      unless(defined $rv && $rv == 0) {
        $self->boss->message(1, "WARNING: non-zero exit code '$rv' - gonna continue but overall result of this task will be 'FAILED'");
        $success = 0;
      }
    }
    else {
      $self->boss->message(1, sprintf("SKIPPING!! %2d/%d ERROR: invalid item", $i, $count));
      $success = 0;
    }
  }

  $self->boss->message(2, "WARNING: empty distribution_list (that's not good)") unless scalar(@distlist_final)>0;

  # store some output data
  $self->{data}->{output}->{distributions} = \@distlist_final;

  return $success;
}

sub _install_module {
  my ($self, %args) = @_;

  my $now = time;

  my $shortname = $args{module};
  $shortname =~ s|^.*[\\/]||;
  $shortname =~ s|:+|_|g;
  $shortname =~ s|[\\/]+|_|g;
  $shortname =~ s/\.(tar\.gz|tar\.bz2|zip|tar|gz)$//;
  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANMINUS_install_module.pl");
  my $log         = catfile($self->global->{debug_dir}, "mod_install_${shortname}_${now}.log.txt");
  my $dumper_file = catfile($self->global->{debug_dir}, "mod_install_${shortname}_${now}.list.dumper.txt");
  my $nstore_file = catfile($self->global->{debug_dir}, "mod_install_${shortname}_${now}.list.nstore.txt");

  my $env = {
    PERL_MM_USE_DEFAULT=>1, AUTOMATED_TESTING=>undef, RELEASE_TESTING=>undef,
    PERL5_CPANPLUS_HOME=>$self->global->{build_ENV}->{APPDATA}, #workaround for CPANPLUS
    PKG_CONFIG_PATH => ($self->global->{image_dir} . '/c/lib/pkgconf'),  #  just to be sure
  };
  # resolve macros in env{}
  if (defined $args{env} && ref $args{env} eq 'HASH') {
    for my $var (keys %{$args{env}}) {
      if ($var eq 'HARNESS_SKIP') { #should leave as is, RT#113182
        $env->{$var} = $args{env}->{$var};
      } else {
        $env->{$var} = $self->boss->resolve_name($args{env}->{$var});
      }
    }
  }
  # resolve macros (with skip canonpath)
  $args{makefilepl_param} = $self->boss->resolve_name($args{makefilepl_param}, 1) if defined $args{makefilepl_param};
  $args{buildpl_param}    = $self->boss->resolve_name($args{buildpl_param}, 1)    if defined $args{buildpl_param};
  $args{module} = $self->boss->resolve_name($args{module});
  $args{module} =~ s|\\|/|g; # cpanm dislikes backslashes

  my %params = ( '-url' => $self->global->{cpan_url}, '-install_to' => 'vendor', '-module' => $args{module} ); #XXX-TODO multiple modules?
  $params{'-out_dumper'}         = $dumper_file if $dumper_file;
  $params{'-out_nstore'}         = $nstore_file if $nstore_file;
  $params{'-install_to'}         = $args{install_to}         if defined $args{install_to};
  $params{'-verbose'}            = $args{verbose}            if defined $args{verbose};
  $params{'-skiptest'}           = $args{skiptest}           if defined $args{skiptest};
  $params{'-ignore_testfailure'} = $args{ignore_testfailure} if defined $args{ignore_testfailure};
  $params{'-ignore_uptodate'}    = $args{ignore_uptodate}    if defined $args{ignore_uptodate};
  $params{'-prereqs'}            = $args{prereqs}            if defined $args{prereqs};
  $params{'-interactivity'}      = $args{interactivity}      if defined $args{interactivity};
  $params{'-makefilepl_param'}   = $args{makefilepl_param}   if defined $args{makefilepl_param}; #XXX-TODO multiple args?
  $params{'-buildpl_param'}      = $args{buildpl_param}      if defined $args{buildpl_param};    #XXX-TODO multiple args?

  # handle global test skip
  $params{'-skiptest'} = 1 unless $self->global->{test_modules};
  # Execute the module install script
  my $rv = $self->execute_special(['perl', $script_pl, %params], $log, $log, $env);
  unless(defined $rv && $rv == 0) {
    rename $log, catfile($self->global->{debug_dir}, "mod_install_${shortname}_FAIL_${now}.log.txt");
    return [], $rv;
  }
  my $data = retrieve($nstore_file) or die "ERROR: retrieve failed";
  return ($data->{installed}//[]), $rv;
}

# pure perl implementation of patch functionality
sub _apply_patch {
  my ($self, $dir_to_be_patched, $patch_file) = @_;
  my ($src, $diff);

  undef local $/;
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  $diff = <DAT>;
  close(DAT);
  $diff =~ s/\r\n/\n/g; #normalise newlines
  $diff =~ s/\ndiff /\nSpLiTmArKeRdiff /g;
  my @patches = split('SpLiTmArKeR', $diff);

  print STDERR "Applying patch file: '$patch_file'\n";
  foreach my $p (@patches) {
    next if $p =~ /^>From [0-9a-f]{40} /; #git intro
    my ($old, $new) = $p =~ /\n---\s*(.+?)\n\+\+\+\s*(.+?)\n/s;
    warn "SKIP: not a patch\n" and next unless defined $old && defined $new;
    my $k = $old ne '/dev/null' ? $old : $new;
    # doing the same like -p1 for 'patch'
    $k =~ s|\\|/|g;
    $k =~ s|^[^/]*/(.*)$|$1|;
    $k = catfile($dir_to_be_patched, $k);
    print STDERR "- gonna patch '$k'\n";

    $src = "";
    if (-f $k) {
       open(SRC, $k) or die "###ERROR### Cannot open file: '$k'\n";
       $src = <SRC>;
       close(SRC);
       $src =~ s/\r\n/\n/g; #normalise newlines
    }

    require Text::Patch;
    my $out = eval { Text::Patch::patch( $src, $p, { STYLE => "Unified" } ) };
    if ($out) {
      open(OUT, ">", $k) or die "###ERROR### Cannot open file for writing: '$k'\n";
      print(OUT $out);
      close(OUT);
    }
    else {
      warn "###WARN### Patching '$k' failed: $@";
    }
  }
}

sub _update_config_H_gc {
    my ($self, $fname, $update_hash) = @_;

    die "update hash arg is not a hash ref"
      if not ref($update_hash) =~ /HASH/;

    open my $fh, $fname or die "Unable to open $fname, $!";

    my $output;
    while (defined (my $line = <$fh>)) {
        $line =~ s/[\r\n]+$//;
        if ($line =~ /#define\s+(\w+)/ and exists $update_hash->{$1}) {
            my $key = $1;
            $line
              = !defined $update_hash->{$key}    ? "/*#define $key\t\t/ **/"
              : $update_hash->{$key} eq 'define' ? "#define $key\t\t/* */"
              : "$update_hash->{$key}";
        }
        $output .= "$line\n";
    }

    $fh->close;


    #  long name but otherwise we interfere with patch backups
    rename $fname, "$fname.orig.before_hash_update" or die $!;
    open my $ofh, '>', $fname or die "Unable to open $fname to write to, $!";
    print {$ofh} $output;
    $ofh->close;

}

sub _update_config_gc {
    my ($self, $fname, $update_hash) = @_;

    die "update hash arg is not a hash ref"
      if not ref($update_hash) =~ /HASH/;

    open my $fh, $fname or die "Unable to open $fname, $!";

    my @lines = (<$fh>);
    close $fh;

    my %data;
    my @output;
    my @perl_lines; #  lines starting with PERL

    while (defined(my $line = shift @lines)) {
        $line =~ s/[\r\n]+$//;
        if ($line =~ /^#/) {
            #  headers stay as they are
            push @output, $line;
        }
        elsif ($line =~ /^PERL/) {
            push @perl_lines, $line;
        }
        else {
            $line =~ m/^([\w]+)=(.+)$/;
            $data{$1} = $2;
        }
    }

    my $default_config_hash = $self->_get_default_config_hash;
    @data{keys %$default_config_hash} = values %$default_config_hash;

    #  fix up quoting of values
    foreach my $val (values %$update_hash) {
        next if $val =~ /^'/;  # assumes symmetry, i.e. opening and closing
        $val = "'$val'";
    }

    @data{keys %$update_hash} = values %$update_hash;
#foreach my $key (sort keys %$update_hash) {
#
  #$self->boss->message(3, "Setting config, $key => $update_hash->{$key}");
  #$data{$key} = $update_hash->{$key};
#}

    my (@ucfirst_lines, @lcfirst_lines);
    foreach my $key (grep {/^[A-Z]/} keys %data) {
        push @ucfirst_lines, "$key=$data{$key}";
    }
    foreach my $key (grep {/^[_a-z]/} keys %data) {
        push @lcfirst_lines, "$key=$data{$key}";
    }
    push @output, (sort @ucfirst_lines), (sort @lcfirst_lines), @perl_lines;

    #  long name but otherwise we interfere with patch backups
    rename $fname, "$fname.orig.before_hash_update" or die $!;
    open my $ofh, '>', $fname or die "Unable to open $fname to write to, $!";
    say {$ofh} join "\n", @output;
    $ofh->close;

}

sub _get_default_config_hash {
    my $self = shift;

    my $h = {
        archlib    => '~INST_TOP~\lib',
        archlibexp => '~INST_TOP~\lib',
        bin        => '~INST_TOP~\bin',
        binexp     => '~INST_TOP~\bin',
        d_vendorarch   => 'define',
        d_vendorbin    => 'define',
        d_vendorlib    => 'define',
        d_vendorscript => 'define',
        dlext          => 'xs.dll',
        installarchlib      => '~INST_TOP~\lib',
        installbin          => '~INST_TOP~\bin',
        installhtmldir      => '',
        installhtmlhelpdir  => '',
        installman1dir      => '',
        installman3dir      => '',
        installprefix       => '~INST_TOP~',
        installprefixexp    => '~INST_TOP~',
        installprivlib      => '~INST_TOP~\lib',
        installscript       => '~INST_TOP~\bin',
        installsitearch     => '~INST_TOP~\site\lib',
        installsitebin      => '~INST_TOP~\site\bin',
        installsitelib      => '~INST_TOP~\site\lib',
        installsitescript   => '~INST_TOP~\site\bin',
        installvendorarch   => '~INST_TOP~\vendor\lib',
        installvendorbin    => '~INST_TOP~\bin',
        installvendorlib    => '~INST_TOP~\vendor\lib',
        installvendorscript => '~INST_TOP~\bin',
        man1dir         => '',
        man1direxp      => '',
        man3dir         => '',
        man3direxp      => '',
        perlpath        => '~INST_TOP~\bin\perl.exe',
        privlib         => '~INST_TOP~\lib',
        privlibexp      => '~INST_TOP~\lib',
        scriptdir       => '~INST_TOP~\bin',
        scriptdirexp    => '~INST_TOP~\bin',
        sitearch        => '~INST_TOP~\site\lib',
        sitearchexp     => '~INST_TOP~\site\lib',
        sitebin         => '~INST_TOP~\site\bin',
        sitebinexp      => '~INST_TOP~\site\bin',
        sitelib         => '~INST_TOP~\site\lib',
        sitelibexp      => '~INST_TOP~\site\lib',
        siteprefix      => '~INST_TOP~\site',
        siteprefixexp   => '~INST_TOP~\site',
        sitescript      => '~INST_TOP~\site\bin',
        sitescriptexp   => '~INST_TOP~\site\bin',
        usevendorprefix => 'define',
        usrinc          => 'C:\strawberry\c\include',
        vendorarch      => '~INST_TOP~\vendor\lib',
        vendorarchexp   => '~INST_TOP~\vendor\lib',
        vendorbin       => '~INST_TOP~\bin',
        vendorbinexp    => '~INST_TOP~\bin',
        vendorlib       => '~INST_TOP~\vendor\lib',
        vendorlibexp    => '~INST_TOP~\vendor\lib',
        vendorprefix    => '~INST_TOP~\vendor',
        vendorprefixexp => '~INST_TOP~\vendor',
        vendorscript    => '~INST_TOP~\bin',
        vendorscriptexp => '~INST_TOP~\bin',
    };

    use POSIX qw(strftime);
    my $time        = strftime "%a %b %e %H:%M:%S %Y", gmtime();
    my $bits        = $self->global->{bits};
    my $app_version = $self->global->{app_version};
    $h->{myuname}   = "Win32 strawberry-perl $app_version # $time x${bits}";

    #  fix up quoting of values - saves a heap of editing
    foreach my $val (values %$h) {
        next if $val =~ /^'/;  # assumes symmetry, i.e. opening and closing
        $val = "'$val'";
    }

    return $h;
}

1;

