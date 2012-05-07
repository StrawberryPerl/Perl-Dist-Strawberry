package Perl::Dist::Strawberry::Step::UpgradeCpanModules;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use Data::Dump            qw(pp);
use Storable              qw(retrieve);
use File::Spec::Functions qw(catfile);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  return $self;
}

sub check {
#xxx-todo $self->{config}->{exceptions}
}

sub run {
  my $self = shift;
  my $success = 1;
  my %distlist_initial = map { $_=>1 } @{$self->workaround_get_dist_list()};
  
  $self->boss->message(1, "getting upgrade module list");
  my $data = $self->_get_cpan_upgrades_list();
  my @list = @{$data->{to_upgrade}};

  #XXX-FIXME warn about $data->{trouble_makers}
  
  my $count = scalar(@list);
  if ($count>0) {
    $self->boss->message(1, "gonna upgrade $count modules");
    $self->boss->message(3, "* [$_->{module}] $_->{cpan_file}") for (@list);
    
    # Now go through the loop for each module.
    my $i = 0;
    for my $module (@list) {
      my $now = time;
      my $f = $module->{cpan_file};
      my $m = $module->{module};
      my $shortname = $module->{distribution};
      $i++;

      my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANPLUS_install_module.pl");
      my $log = catfile($self->global->{debug_dir}, "mod_upgrade_".$now."_".$shortname.".log.txt");
      my $skiptest = $self->global->{test_modules} ? 0 : 1;
      my $extra = $self->_get_extra_install_options($module);
      if (!defined $extra) {
        $self->boss->message(2, sprintf("SKIPPING! %2d/%d '%s'", $i, $count, $f));
        next;
      }
      my @msg;
      push @msg, 'IGNORE_TESTFAILURE' if $extra->{"-ignore_testfailure"};
      push @msg, 'SKIPTEST' if $extra->{"-skiptest"};
      $self->boss->message(2, sprintf("upgrading %2d/%d '%s' \t".join(' ',@msg), $i, $count, $f));

      # Execute the module install script
      my $env = { PERL_MM_USE_DEFAULT=>1, AUTOMATED_TESTING=>undef, RELEASE_TESTING=>undef };
      my $rv = $self->execute_special(['perl', $script_pl, '-url', $self->global->{cpan_url},
                                                       '-module', $module->{cpan_file},
                                                       '-install_to', 'perl', 
                                                       %{$extra},
                                                       '-skiptest', $skiptest ], $log, $log, $env);
      unless (defined $rv && $rv == 0) {
        $self->boss->message(1, "WARNING: non-zero exit code '$rv' - gonna continue but overall result of this task will be 'FAILED'");
        $success = 0;
        rename $log, catfile($self->global->{debug_dir}, "mod_upgrade_FAIL_".$now."_".$shortname.".log.txt");
      }
    }
    $self->boss->message(1, "upgrade finished");
  }
  else {
    $self->boss->message(1, "all modules up to date");
  }
  
  my @distlist_final = grep { !$distlist_initial{$_} } @{$self->workaround_get_dist_list()};
  $self->boss->message(2, "WARNING: empty distribution_list (that's not good)") unless scalar(@distlist_final)>0;
  
  # store some output data
  $self->{data}->{output}->{distributions} = \@distlist_final;

  die "FAILED\n" unless $success;
}

sub _get_extra_install_options {
  my ($self, $modinfo) = @_;
  for my $ex (@{$self->{config}->{exceptions}}) {
    my $do = $ex->{do};
    for my $k (keys %$ex) {
      if ($k eq 'distribution') {
        if ( (ref $ex->{$k} eq 'Regexp' && $modinfo->{distribution} =~ $ex->{$k}) || $modinfo->{distribution} eq $ex->{$k} ) {
          return undef if $do eq 'skip';
          return { "-$do" => 1 };
        }
      }
      elsif ($k eq 'version') {
        if ( (ref $ex->{$k} eq 'Regexp' && $modinfo->{cpan_version} =~ $ex->{$k}) || $modinfo->{cpan_version} eq $ex->{$k} ) {
          return undef if $do eq 'skip';
          return { "-$do" => 1 };
        }
      }
      elsif ($k eq 'cpan_file') {
        if ( (ref $ex->{$k} eq 'Regexp' && $modinfo->{cpan_file} =~ $ex->{$k}) || $modinfo->{cpan_file} eq $ex->{$k} ) {
          return undef if $do eq 'skip';
          return { "-$do" => 1 };
        }
      }
    }
  }
  return {};
}

sub _get_cpan_upgrades_list {
  my $self = shift;

  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPANPLUS_get_upgrade_list.pl");
  my $log = catfile($self->global->{debug_dir}, "cpan_upgrade.log.txt");
  my $dumper_file = catfile($self->global->{debug_dir}, "cpan_upgrade.dumper.txt");
  my $nstore_file = catfile($self->global->{debug_dir}, "cpan_upgrade.nstore.txt");

  # Execute the CPAN upgrade script.
  my $rv = $self->execute_special(['perl', $script_pl, '-url', $self->global->{cpan_url},
                                                   '-out_nstore', $nstore_file,
                                                   '-out_dumper', $dumper_file ], $log);

  die "ERROR: exec '$script_pl' failed" unless defined $rv && $rv == 0;
  die "ERROR: missing file '$nstore_file'" unless -f $nstore_file;
  my $data = retrieve($nstore_file) or die "ERROR: retrieve failed, probably error while executing '$script_pl'";
  die "ERROR: invalid upgrade list" unless defined $data && ref $data eq 'HASH' && exists $data->{to_upgrade};
  return $data;
}


1;