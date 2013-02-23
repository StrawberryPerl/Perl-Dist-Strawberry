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
  my $success = 1;
  my %distlist_initial = map { $_=>1 } @{$self->workaround_get_dist_list()};

  $self->boss->message(1, "NOTE: global option test_modules=0 (all tests will be skipped") unless $self->global->{test_modules};

  my @list = @{$self->{config}->{modules}};
  my $count = scalar(@list);
  my $i = 0;
  for my $item (@list) {
    $i++;
    $item = { module=>$item } unless ref $item; # if item is scalar we assume module name
    my $name = $item->{module};
    if ($name) {
      my @msg;
      push @msg, 'IGNORE_TESTFAILURE' if $item->{ignore_testfailure};
      push @msg, 'SKIPTEST' if $item->{skiptest};
      $self->boss->message(1, sprintf("installing %2d/%d '%s' \t".join(' ',@msg), $i, $count, $name));
      my $rv = $self->_install_module(%$item);
      unless(defined $rv && $rv == 0) {
        $self->boss->message(1, "WARNING: non-zero exit code '$rv' - gonna continue but overall result of this task will be 'FAILED'");
        $success = 0;
      }
    }
    else {
      $self->boss->message(1, sprintf("SKIPPING!! %2d/%d ERROR: invalid item", $i, $count));
      $success = 0;
    }
  }
  
  my @distlist_final = grep { !$distlist_initial{$_} } @{$self->workaround_get_dist_list()};
  $self->boss->message(3, "INFO: distribution_list size=", scalar(@distlist_final));
  $self->boss->message(2, "WARNING: empty distribution_list (that's not good)") unless scalar(@distlist_final)>0;
  
  # store some output data
  $self->{data}->{output}->{distributions} = \@distlist_final;

  die "FAILED\n" unless $success;
}

sub _install_module {
  my ($self, %args) = @_;

  my $now = time;
  my $shortname = $args{module};
  $shortname =~ s|^.*[\\/]||;
  $shortname =~ s|:+|_|g;
  $shortname =~ s|[\\/]+|_|g;
  $shortname =~ s/\.(tar\.gz|tar\.bz2|zip|tar|gz)$//;

  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANPLUS_install_module.pl");
  my $log = catfile($self->global->{debug_dir}, "mod_install_".$now."_".$shortname.".log.txt");
  #my $dumper_file = catfile($self->global->{debug_dir}, "cpan_install.dumper.txt");
  #my $nstore_file = catfile($self->global->{debug_dir}, "cpan_install.nstore.txt");

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
  my %params = ( '-url' => $self->global->{cpan_url}, '-install_to' => 'vendor', '-module' => $args{module} ); #XXX-TODO multiple modules?
  $params{'-install_to'}         = $args{install_to}         if defined $args{install_to};
  $params{'-verbose'}            = $args{verbose}            if defined $args{verbose};
  $params{'-skiptest'}           = $args{skiptest}           if defined $args{skiptest};
  $params{'-ignore_testfailure'} = $args{ignore_testfailure} if defined $args{ignore_testfailure};
  $params{'-ignore_uptodate'}    = $args{ignore_uptodate}    if defined $args{ignore_uptodate};
  $params{'-prereqs'}            = $args{prereqs}            if defined $args{prereqs};
  $params{'-interactivity'}      = $args{interactivity}      if defined $args{interactivity};
  $params{'-makefilepl_param'}   = $args{makefilepl_param}   if defined $args{makefilepl_param}; #XXX-TODO multiple args?
  $params{'-buildpl_param'}      = $args{buildpl_param}      if defined $args{buildpl_param};    #XXX-TODO multiple args?
  # handle global test skip
  $params{'-skiptest'} = 1 unless $self->global->{test_modules};
  # Execute the module install script
  my $rv = $self->execute_special(['perl', $script_pl, %params], $log, $log, $env);
  unless(defined $rv && $rv == 0) {
    rename $log, catfile($self->global->{debug_dir}, "mod_install_FAIL_".$now."_".$shortname.".log.txt");
  }
  return $rv;
}

1;