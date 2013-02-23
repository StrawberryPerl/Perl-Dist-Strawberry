package Perl::Dist::Strawberry::Step::UninstallModules;

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
  
  my $success = 1;
  my @list = @{$self->{config}->{modules}};
  my $count = scalar(@list);
  my $i = 0;
  $self->{data}->{output}->{distributions_removed} = [];
  for my $item (@list) {
    $i++;
    $item = { module=>$item } unless ref $item; # if item is scalar we assume module name
    my $name = $item->{module};
    if ($name) {
      my @msg;
      $self->boss->message(1, sprintf("uninstalling %2d/%d '%s' \t".join(' ',@msg), $i, $count, $name));
      my $rv = $self->_uninstall_module(%$item);
      unless(defined $rv && $rv == 0) {
        $self->boss->message(1, "WARNING: non-zero exit code '$rv' - gonna continue but overall result of this task will be 'FAILED'");
        $success = 0;
      }
      else {
        push @{$self->{data}->{output}->{distributions_removed}}, $name;
      }
    }
    else {
      $self->boss->message(1, sprintf("SKIPPING!! %2d/%d ERROR: invalid item", $i, $count));
      $success = 0;
    }
  }

  die "FAILED\n" unless $success;
}

sub _uninstall_module {
  my ($self, %args) = @_;

  my $now = time;
  my $shortname = $args{module};
  $shortname =~ s|^.*[\\/]||;
  $shortname =~ s|:+|_|g;
  $shortname =~ s|[\\/]+|_|g;
  $shortname =~ s/\.(tar\.gz|tar\.bz2|zip|tar|gz)$//;

  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANPLUS_uninstall_module.pl");
  my $log = catfile($self->global->{debug_dir}, "mod_uninstall_".$now."_".$shortname.".log.txt");
  #my $dumper_file = catfile($self->global->{debug_dir}, "cpan_uninstall.dumper.txt");
  #my $nstore_file = catfile($self->global->{debug_dir}, "cpan_uninstall.nstore.txt");

  my $env = {
    PERL_MM_USE_DEFAULT=>1, AUTOMATED_TESTING=>undef, RELEASE_TESTING=>undef,
    PERL5_CPANPLUS_HOME=>$self->global->{build_ENV}->{APPDATA}, #workaround for CPANPLUS
  };
  # resolve macros in env{}
  if (defined $args{env} && ref $args{env} eq 'HASH') {
    for my $var (keys %{$args{env}}) { 
      $env->{$var} = $self->boss->resolve_name($args{env}->{$var});
    }
  }
  # resolve macros in module name
  $args{module} = $self->boss->resolve_name($args{module});
  my %params;
  $params{-url}     = $self->global->{cpan_url};
  $params{-module}  = $args{module}; #XXX-TODO multiple modules?
  $params{-verbose} = $args{verbose} if defined $args{verbose};
  # Execute the module uninstall script
  my $rv = $self->execute_special(['perl', $script_pl, %params], $log, $log, $env);
  unless(defined $rv && $rv == 0) {
    rename $log, catfile($self->global->{debug_dir}, "mod_uninstall_FAIL_".$now."_".$shortname.".log.txt");
  }
  return $rv;
}

1;