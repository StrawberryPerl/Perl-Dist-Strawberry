package Perl::Dist::Strawberry::Step::UpgradeCpanModules;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use Data::Dump            qw(pp);
use Storable              qw(retrieve);
use File::Spec::Functions qw(catfile);

sub check {
#xxx-todo $self->{config}->{exceptions}
}

sub run {
  my $self = shift;
  my $success = 1;
  
  $self->boss->message(1, "getting upgrade module list");
  my $data = $self->_get_cpan_upgrades_list();
  my @list = @{$data->{to_upgrade}};
  my @toinstall = ();
  
  my $count = scalar(@list);
  if ($count>0) {
    $self->boss->message(1, "gonna upgrade $count modules");
    $self->boss->message(3, "* $_->{cpan_file}") for (@list);

    # Now go through the loop for each module.
    my $i = 0;
    for my $module (@list) {
      my $item = { module=> $module->{cpan_file}, install_to=>'perl' };
      my $extra = $self->_get_extra_install_options($module);
      if (!defined $extra) {
        $self->boss->message(2, sprintf("SKIPPING! %2d/%d '%s'", $i, $count, $module));
        next;
      }
      $item->{ignore_testfailure} = 1 if $extra->{"-ignore_testfailure"};
      $item->{skiptest}           = 1 if $extra->{"-skiptest"};
      push @toinstall, $item;
    }
    if (@toinstall) {
      $success = $self->install_modlist(@toinstall);      
    }
    $self->boss->message(1, "upgrade finished [success=$success]");
  }
  else {
    $self->boss->message(1, "all modules up to date");
  }
  
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

  my $script_pl = $self->boss->resolve_name("<dist_sharedir>/utils/CPAN_get_upgrade_list.pl");
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