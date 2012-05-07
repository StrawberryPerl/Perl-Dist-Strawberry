package Perl::Dist::Strawberry::Step::CreateRelocationFile;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Find::Rule;
use File::Spec::Functions qw(catfile catdir);
use File::Slurp           qw(read_file write_file);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  return $self;
}

sub check {
  my $self = shift;
}

sub run {
  my $self = shift;
  my $in1  = $self->boss->resolve_name($self->{config}->{reloc1_in});
  my $out1 = $self->boss->resolve_name($self->{config}->{reloc1_out});
  my $in2  = $self->boss->resolve_name($self->{config}->{reloc2_in});
  my $out2 = $self->boss->resolve_name($self->{config}->{reloc2_out});
  $self->_make_relocation_file1($in1, $out1); # .packlist + *.bat
  $self->_make_relocation_file2($in2, $out2); # win32/*.url
}

sub test {
  my $self = shift;
}

#XXX-TODO implementation is ugly (but works for now)

sub _make_relocation_file2 {
  my ($self, $file_in, $file_out) = @_;
  
  $self->boss->message(2, "gonna make reloc2 '$file_out'");
  
  # Find all the .url files in win32 subdir
  my @url_files_list = File::Find::Rule->file()->name('*.url')->relative()->in( catdir($self->global->{image_dir}, 'win32') );
  my %url_files = map { s{/}{\\}msg; "win32\\$_" => 1 } @url_files_list;
  
  # Print the first line of the relocation file.
  my $file_out_handle;
  open $file_out_handle, '>', $file_out or die "open fail";
  print {$file_out_handle} $self->global->{image_dir}, "\\\n";

  # Read the source file, writing out the files that actually exist.
  my @filelist = read_file($file_in);
  foreach my $filelist_entry (@filelist) {
    $filelist_entry =~ m/\A([^:]*):.*\z/msx;
    if (defined $1 and -f catfile($self->global->{image_dir}, $1) ) {
      print {$file_out_handle} $filelist_entry;
    }
  }
  
  # Print out the rest of the .url files.
  foreach my $pl ( sort { $a cmp $b } keys %url_files ) {
    print {$file_out_handle} "$pl:backslash\n";
  }
  
}
  
sub _make_relocation_file1 {
  my ($self, $file_in, $file_out, @files_already_processed) = @_;

  $self->boss->message(2, "gonna make reloc1 '$file_out'");

  # Find files we're already assigned for relocation.
  my @filelist;
  my %files_already_relocating;

  foreach my $file_already_processed (@files_already_processed) {
    @filelist = read_file( catfile($self->global->{image_dir}, $file_already_processed) );
    shift @filelist; # the first line is 'image_dir'
    %files_already_relocating = ( %files_already_relocating, map { m/\A([^:]*):.*\z/msx; $1 => 1 } @filelist );
  }

  # Find all the .packlist files.
  my @packlists_list = File::Find::Rule->file()->name('.packlist')->relative()->in( $self->global->{image_dir} );
  my %packlists = map { s{/}{\\}msg; $_ => 1 } @packlists_list;

  # Find all the .bat files.
  my @batch_files_list = File::Find::Rule->file()->name('*.bat')->relative()->in( $self->global->{image_dir} );
  my %batch_files = map { s{/}{\\}msg; $_ => 1 } @batch_files_list;

  # Get rid of the .packlist and *.bat files we're already relocating.
  delete @packlists{ keys %files_already_relocating };
  delete @batch_files{ keys %files_already_relocating };

  # Print the first line of the relocation file.
  my $file_out_handle;
  open $file_out_handle, '>', $file_out or die "open fail";
  print {$file_out_handle} $self->global->{image_dir}, "\\\n";

  # Read the source file, writing out the files that actually exist.
  @filelist = read_file($file_in);
  foreach my $filelist_entry (@filelist) {
    $filelist_entry =~ m/\A([^:]*):.*\z/msx;
    if ( defined $1 and -f catfile($self->global->{image_dir}, $1) ) {
      print {$file_out_handle} $filelist_entry;
    }
  }

  # Print out the rest of the .packlist files.
  foreach my $pl ( sort { $a cmp $b } keys %packlists ) {
    print {$file_out_handle} "$pl:backslash\n";
  }

  # Print out the batch files that need relocated.
  my $batch_contents;
  #XXX-FIXME this was original: my $match_string = q(eval [ ] 'exec [ ] ) . quotemeta catfile($self->global->{image_dir}, qw(perl bin perl.exe));
  my $match_string = quotemeta catfile($self->global->{image_dir}, qw(perl bin perl.exe));
  foreach my $batch_file ( sort { $a cmp $b } keys %batch_files ) {
    #$self->boss->message(3, "Checking to see if '$batch_file' needs relocated");
    $batch_contents = read_file( catfile($self->global->{image_dir}, $batch_file) );
    print {$file_out_handle} "$batch_file:backslash\n" if $batch_contents =~ m/$match_string/msgx;
  }

  # Finish up by closing the handle.
  close $file_out_handle or die "close failed";

  return 1;
}

1;