package Perl::Dist::Strawberry::Step::FilesAndDirs;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Slurp           qw(read_file write_file);
use File::Copy::Recursive qw(dircopy);
use File::Spec::Functions qw(splitpath catpath catfile);
use File::Path            qw(make_path remove_tree);
use File::Copy            qw(copy);
use Data::Dump            qw(pp);
use File::Find::Rule;
use Text::Patch;
use Text::Diff;
use Template;

### public methods - new(), check(), run(), test()

sub check {
  my $self = shift;
  $self->SUPER::check(@_);
  die "no 'commands' found in config" unless $self->{config}->{commands};
  die "invalid 'commands' - expected arrayref" unless ref $self->{config}->{commands} eq 'ARRAY';
}

sub run {
  my $self = shift;
  my $success = 1;
  my $i = 0;
  for (@{$self->{config}->{commands}}) {
    my ($cmd, $args) = ($_->{do}, $_->{args});
    $i++;
    eval { $self->_do_job($cmd, $args) };
    if ($@) {
      $self->boss->message(1, "ERROR: failure while processing item [$i:$cmd]: $@");
      $success = 0;
    }
    else {
      $self->boss->message(1, "item [$i:$cmd] installed successfully");
    }
  }
  die "FAILED\n" unless $success;
}

sub test {
  my $self = shift;
  $self->SUPER::test(@_);
}

### private methods

sub _do_job {
  my ($self, $cmd, $args) = @_;
  # die on failure
  if (defined $cmd && defined $args) {
    if ($cmd eq 'copyfile') {
      my ($src, $dst, $no_backup) = ($self->boss->resolve_name($args->[0]), $self->boss->resolve_name($args->[1]), $args->[2]);
      $self->boss->message(4, "copying '$src' >> '$dst'");
      $self->_create_dir_for_file($dst);
      die "non-existing file '$src'" unless -f $src;
      copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
      copy($src, $dst) or die "copy failed: $!";
    }
    elsif ($cmd eq 'apply_tt') {
      my ($tt_file, $dst, $tt_vars, $no_backup) = ($self->boss->resolve_name($args->[0]), $self->boss->resolve_name($args->[1]), $args->[2], $args->[3]);
      $self->boss->message(4, "applying template on '$dst'");
      $self->_create_dir_for_file($dst);
      $tt_vars = {} unless defined $tt_vars;
      my %tt = ( 
        %{$self->global},
        %$tt_vars,
      );

      copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
      my $indata = read_file($tt_file);
      my $outdata = '';

      my $template = Template->new();
      write_file(catfile($self->global->{debug_dir}, 'TTvars_FileAndDirs_'.time.'.txt'), pp(\%tt)); #debug dump
      $template->process(\$indata, \%tt, \$outdata) || die $template->error();
      my $r = $self->_unset_ro($dst);
      write_file($dst, $outdata);
      $self->_restore_ro($dst, $r);
      write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
    }
    elsif ($cmd eq 'apply_patch') {
      my ($diff_file, $dst, $no_backup) = ($self->boss->resolve_name($args->[0]), $self->boss->resolve_name($args->[1]), $args->[2]);
      $self->boss->message(4, "applying DIFF on '$dst'");
      $self->_create_dir_for_file($dst);
      copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
      my $diff = read_file($diff_file);
      my $indata = read_file($dst);
      my $outdata = patch($indata, $diff, STYLE=>"Unified");
      my $r = $self->_unset_ro($dst);
      write_file($dst, $outdata);
      $self->_restore_ro($dst, $r);
      write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
    }
    elsif ($cmd eq 'removefile') {
      for (@$args) {
        my $n = $self->boss->resolve_name($_);
        $self->boss->message(4, "gonna removefile '$n'");
        unlink($n) if -f $n; 
      }
    }
    elsif ($cmd eq 'removefile_recursive') {
      my ($rootdir, $name) = ($self->boss->resolve_name($args->[0]), $args->[1]);
      die "non-existing '$rootdir'" unless -d $rootdir;
      my @files = File::Find::Rule->file()->name($name)->in($rootdir);
      for my $n (@files) {
        $self->boss->message(4, "gonna removefile '$n'");
        unlink($n) if -f $n; 
      }
    }
    elsif ($cmd eq 'removedir') {
      for (@$args) {
        my $n = $self->boss->resolve_name($_);
        $self->boss->message(4, "gonna removedir '$n'");
        remove_tree($n) if -d $n;
      }
    }
    elsif ($cmd eq 'createdir') {
      for (@$args) {
        my $n = $self->boss->resolve_name($_);
        $self->boss->message(4, "gonna createdir '$n'");
        make_path($n) if !-d $n;
      }
    }
    elsif ($cmd eq 'copydir') {
      my ($src, $dst) = ($self->boss->resolve_name($args->[0]), $self->boss->resolve_name($args->[1]));
      $self->boss->message(4, "gonna dircopy '$src' >> '$dst'");
      dircopy($src, $dst) or die "dircopy failed";
    }
    else {
      #XXX-TODO
      #die "FATAL: '$cmd' not implemented";
    }
  }
}

sub _create_dir_for_file {
  my ($self, $filename) = @_;
  my ($volume, $directories, $file) = splitpath($filename);
  my $d = catpath($volume,$directories);
  make_path($d) unless -d $d;
}

sub _check_valid_prefix {
  #XXX-TODO implement or remove
}

1;