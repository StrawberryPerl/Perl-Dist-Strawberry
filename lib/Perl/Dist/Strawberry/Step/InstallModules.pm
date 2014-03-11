package Perl::Dist::Strawberry::Step::InstallModules;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use Data::Dump            qw(pp);
use Storable              qw(retrieve);
use File::Spec::Functions qw(catfile);

sub check {
  my $self = shift;
  $self->SUPER::check(@_);
  my $m = $self->{config}->{modules};
  die "param 'modules' not defined" unless defined $m;
  die "param 'modules' has to be ARRAYREF" unless ref $m eq 'ARRAY';
}

sub run {
  my $self = shift;
  my @list = @{$self->{config}->{modules}};
  $self->install_modlist(@list) or die "FAILED";
}

1;