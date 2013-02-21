package Perl::Dist::Strawberry::Step::FixShebang;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Slurp;
use File::Spec;
use File::Glob 'bsd_glob';

sub check {
  my $self = shift;
  $self->SUPER::check(@_);
  die "param 'shebang' not defined" unless defined $self->{config}->{shebang};
}

sub run {
  my $self = shift;
  my $image_dir = $self->global->{image_dir};
  my $sb = $self->{config}->{shebang};

  $self->boss->message(2, "Gonna fix shebang to '$sb'");

  for my $full (bsd_glob("$image_dir/perl/bin/*")) {
    my ($v, $d, $f) = File::Spec->splitpath($full);
    if ($f !~ /\./ || $f =~ /\.pl$/i) {
      my $data = read_file($full, binmode => ':raw' );
      my $orig = $data;
      $data =~ s{^(#!.*?)( -|\r|\n)}{$sb$2}sgi;
      if ($orig ne $data) {
        $self->boss->message(3, "Patching '$full'");
        my $r = $self->_unset_ro($full);
        write_file($full, {binmode => ':raw'}, $data);
        $self->_restore_ro($full, $r);
      }
    }
  }

}

1;