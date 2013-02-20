package Perl::Dist::Strawberry::Step::FixShebang;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catdir);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  return $self;
}

sub run {
  my $self = shift;
  
  $self->boss->message(2, "Gonna fix shebang to '" . $self->{config}->{shebang} . "'");
  $self->boss->message(2, "XXX-TODO");
}

1;