package Perl::Dist::Strawberry::Step::SetupPortablePerl;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catdir);
use Portable::Dist;

sub run {
  my $self = shift;
  
  $self->boss->message(2, "Creating Portable::Dist");
  my $portable_dist = Portable::Dist->new( perl_root => catdir($self->global->{image_dir}, 'perl') ) or die "FATAL: Portable::Dist->new() failed";
  
  $self->boss->message(2, "Running Portable::Dist");
  $portable_dist->run() or die "FATAL: Portable::Dist->run() failed";
  
  $self->boss->message(2, "Completed Portable::Dist");
}

1;