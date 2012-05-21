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
use Text::Patch;
use Text::Diff;
use Win32;
use Win32::File::Object;
use IPC::Run3;
use Digest::SHA1;

##### manatory methods for all Step-like classess - new(), check(), run(), test()

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

sub _insert_fragment {
#XXX-FIXME remove this method
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
  $self->boss->message(4, "execute_standard stdout='$out' stderr='$err'\n");
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
  %ENV = (%original_env, %{$self->global->{build_ENV}}, %$env);

  $self->boss->message(4, "execute_special PATH='$ENV{PATH}'\n");

  my $output_dir = $self->global->{output_dir};
  make_path($output_dir) unless -d $output_dir;

  # Execute the child process
  $self->boss->message(4, "execute_special stdout='$out' stderr='$err'\n");
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
  my ($self, $new, $dst, $tt_vars, $no_backup) = @_;

  if (!-f $new) {
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
  elsif ($new =~ /\.diff$/) {
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

sub workaround_get_dist_list {
# XXX-FIXME ugly workaround for getting the list of distributions installed  via CPANPLUS
# used by UpgradeCpanModules and InstallModules
# implement something more clever in the future
  my $self = shift;
  my $env = { PERL5_CPANPLUS_HOME=>$self->global->{build_ENV}->{APPDATA} }; #workaround for CPANPLUS
  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANPLUS_list_build_cache.pl");
  my $prefix = "cpan_dist_list.".time;
  my $log = catfile($self->global->{debug_dir}, "$prefix.log.txt");
  my $dumper = catfile($self->global->{debug_dir}, "$prefix.dumper.txt");
  my $nstore = catfile($self->global->{debug_dir}, "$prefix.nstore.txt");
  my $rv = $self->execute_special(['perl', $script_pl, '-out_nstore', $nstore, '-out_dumper', $dumper ], $log, $log, $env);
  die "ERROR: exec '$script_pl' failed" unless defined $rv && $rv == 0;
  die "ERROR: missing file '$nstore'" unless -f $nstore;
  my $data = retrieve($nstore) or die "ERROR: retrieve failed, probably error while executing '$script_pl'";
  die "ERROR: invalid data" unless defined $data && ref $data eq 'ARRAY';
  return $data;
}

1;