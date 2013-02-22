package Perl::Dist::Strawberry::Step::CreateReleaseNotes;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catdir catfile);
use File::Slurp           qw(write_file read_file);
use Data::Dump            qw(pp);
use Template;
use File::Find::Rule;
use HTML::Entities;

sub run {
  my $self = shift;
  
  $self->boss->message(2, "Creating Release Notes");
  
  my $html_file = catfile($self->global->{output_dir}, $self->global->{output_basename} .".html");
  my $tt_file = catfile($self->global->{dist_sharedir}, qw/extra-files release_notes.html.tt/);
  
  # get release date
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  $year += 1900;
  
  # backup already existing html_file;  
  $self->backup_file($html_file);
  
  my @computed_distributions;
  my %src = map { $_=>1 } @{$self->global->{output}->{distributions}};
  for my $i (keys %src) {
    my ($d, $v) = ($i =~ m/^(.*?)-(v?[0-9].*)$/);
    my $excluded;
    for (@{$self->global->{output}->{distributions_removed}}) {
      $excluded = 1 if $d eq $_;
    }
    push @computed_distributions, { dist=>$d, ver=>$v } unless $excluded;
  }
  @computed_distributions = sort { lc($a->{dist}) cmp lc($b->{dist}) } @computed_distributions;

  my %vars = (
    # global info taken from 'boss'
    %{$self->global},
    # OutputMSM_MSI config info    
    %{$self->{config}},
    # the following items are computed
    release_date => "$abbr[$mon] $mday $year",
    distributions => \@computed_distributions,
    packages => $self->_get_dist_pkgs(),
    version => {},
  );
  
  $self->execute_special([catfile($self->global->{image_dir}, qw/perl bin perl.exe/), '-V'], \$vars{version}->{perl}); 
  $self->execute_special([catfile($self->global->{image_dir}, qw/c bin gcc.exe/), '-v'], \$vars{version}->{gcc}); 
  $self->execute_special([catfile($self->global->{image_dir}, qw/c bin openssl.exe/), qw/version -v -b -o -f -p/], \$vars{version}->{openssl}); 
  $vars{version}->{perl}    = $self->_preproc_string($vars{version}->{perl});
  $vars{version}->{gcc}     = $self->_preproc_string($vars{version}->{gcc});
  $vars{version}->{openssl} = $self->_preproc_string($vars{version}->{openssl});
  
  #die pp $vars{version};
  
  my $t = Template->new(ABSOLUTE=>1);
  write_file(catfile($self->global->{debug_dir}, 'TTvars_CreateReleaseNotes_'.time.'.txt'), pp(\%vars)); #debug dump
  $t->process($tt_file, \%vars, $html_file) || die $t->error();
  
  $self->boss->message(2, "Created '$html_file' (size=".(-s $html_file).")");
}

sub _preproc_string {
  my ($shift, $data) = @_;
  #my @l = split(/\n/, $data);
  #$data =~ s/\r\n/\n/sg;
  $data =~ s/[^\n]{100}/$&\n/sg; 
  return encode_entities($data);
}

sub _get_dist_pkgs {
  my $self = shift;
  my $dir = $self->global->{image_dir} . "/licenses";
  my $results = {};  
  my @files = File::Find::Rule->file->name('_INFO_')->in($dir);
  for my $file (@files) {
    my @lines = read_file($file);
    my ($pkg, $src, $home, $comment) = ('','','','');
    for my $l (@lines) {
      my ($label, $txt) = $l =~ /^([^: ]+): *(.*)$/;                  
      if (!$label) {
        $results->{$pkg} = { pkg=>$pkg, sources=>$src, homepage=>$home, comment=>$comment } if $pkg;
        ($pkg, $src, $home, $comment) = ('','','','');
        next;
      }  
      $label = lc($label);
      $pkg  = $txt if $label eq 'package';
      $src  = $txt if $label eq 'sources';
      $home = $txt if $label eq 'homepage';
      $comment .= ($comment ? "\n" : "") . $txt if $label eq 'comment';
    }
    $results->{$pkg} = { pkg=>$pkg, sources=>$src, homepage=>$home, comment=>$comment } if $pkg;
  }
  
  my @rv;
  for my $p (sort keys(%$results)) {
    push @rv, $results->{$p};
  }
  return \@rv;
}

1;