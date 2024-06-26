package Perl::Dist::Strawberry::Step::OutputLogZIP;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile);

sub run {
  my $self = shift;
    
  my $output_basename = $self->global->{output_basename} // 'perl-output';
  my $zip_file = catfile($self->global->{output_dir}, "$output_basename.LOG.zip");
  
  $self->boss->message(2, "gonna create '$zip_file'"); 
  # backup already existing zip_file;  
  $self->backup_file($zip_file);
  # do zip
  $self->boss->zip_dir($self->global->{debug_dir}, $zip_file, 9); # 9 = max. compression  
  #store results
  $self->{data}->{output}->{log_zip} = $zip_file;
  $self->{data}->{output}->{log_zip_sha1} = $self->sha1_file($zip_file);
  $self->{data}->{output}->{log_zip_sha256} = $self->sha256_file($zip_file);
}

1;