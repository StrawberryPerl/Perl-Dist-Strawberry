@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
%~dp0perl\bin\perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
%~dp0perl\bin\perl -x -S %0 %*
goto endofperl
@rem ';
#!perl

use 5.010;
use strict;
use warnings;
use Win32::TieRegistry qw(:KEY_);
use File::Spec::Functions qw(catdir splitpath);
use English qw(-no_match_vars);
use Carp qw(carp);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use FindBin;
use Win32::API;
use Config;

### global variables

my $directory;
my $quiet = 0;
my $system = 1;

### main

GetOptions('help'        => sub { pod2usage(-exitstatus => 0, -verbose => 2); },
           'directory=s' => \$directory,
           'quiet'       => \$quiet,
           'system!'     => \$system,
          ) or pod2usage(-verbose => 2);

if (not defined $directory) {
    $directory = $FindBin::Bin;
    $directory =~ s{/}{\\}g;
}

if (not defined $directory) {
    carp q{Could not get the script's directory, and no --directory option was given};
}

# Get the appropriate environment entries.
my ($hklm_env, $hklm_env_ro, $hkcu_env);
if ($system) {
    $hklm_env = Win32::TieRegistry->new(
        'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment',
        {
            Access => KEY_READ() | KEY_WRITE() | 256,
            Delimiter => '/',
        }
    ); # returns undef if SYSTEM ENV not writable
}

$hklm_env_ro = Win32::TieRegistry->new(
    'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment',
    {
        Access => KEY_READ() | 256,
        Delimiter => '/',
    }
); # read only SYSTEM ENV - for checking existing PATH items

$hkcu_env = Win32::TieRegistry->new(
    'HKEY_CURRENT_USER/Environment',
    {
        Access => KEY_READ() | KEY_WRITE() | 256,
        Delimiter => '/',
    }
);

# If system environment is not writable (or not requested) try the user environment.
my ($env, $location);
if (defined($hklm_env)) {
    $env = $hklm_env;
    $location = 'system';
} else {
    $env = $hkcu_env;
    $location = 'user';
}

my @existing_path_items;
push(@existing_path_items, split(/;/,$hklm_env_ro->GetValue('Path'))) if $hklm_env_ro;
push(@existing_path_items, split(/;/,$hkcu_env->GetValue('Path'))) if $hkcu_env;
for (@existing_path_items) { $_ =~ s/[\\]*$// }; #remove trailing backslahes

my @items_to_add = map { catdir($directory, $_); } qw{c\bin perl\site\bin perl\bin};
my $changed = 0;

if (defined $env) {
    my $path = $env->GetValue('Path');
    foreach my $i (@items_to_add) {
        my @found = grep(/^\Q$i\E$/i, @existing_path_items);
        if (scalar(@found) == 0) {
          $path = "$path;$i";
          say "Adding $i to the $location path." unless $quiet;
          $changed = 1;
        }
    }
    $env->SetValue('Path', $path, 'REG_EXPAND_SZ') if $changed;
    if( !defined($env->GetValue('TERM')) || $env->GetValue('TERM') ne 'dumb') {
      $env->SetValue('TERM', 'dumb');
      say "Adding TERM=dumb to the $location environment." unless $quiet;
      $changed = 1;
    }
}
else {
    if ($system) {
        carp "Cannot open either the system or the user environment registry entries for read and write access";
    } else {
        carp "Cannot open the user environment registry entries for read and write access";
    }
}

if ($changed) {
  #gonna send WM_SETTINGCHANGE broadcast - to avoid the need for logout/login
  my $HWND_BROADCAST   = 0xFFFF;
  my $WM_SETTINGCHANGE = 0x001A;
  my $SMTO_ABORTIFHUNG = 0x0002;
  my $null = pack('xxxxxxxx'); # 8 x zero byte

  my $SendMessageTimeout = Win32::API->new("user32", "SendMessageTimeout", 'NNNPNNP', 'N') or die "Can't import SendMessageTimeout: $!\n";
  $SendMessageTimeout->Call($HWND_BROADCAST,$WM_SETTINGCHANGE,0,'Environment',$SMTO_ABORTIFHUNG,5000,$null);
}

__END__

=head1 DESCRIPTION

update_env.pl.bat - Updates the environment to add Strawberry Perl to the PATH
permanently, and adds other environment variables that portions of
Strawberry Perl uses.

=head1 SYNOPSIS

 update_path.pl.bat [ --help ] [--directory path] [--[no]system] [--quiet]

 Options:
   --help          Gives aid and comfort.
   --directory     The location the script is in. (used to set the path
                   to update to.) Defaults to $FindBin::Bin.
   --[no]system    Specifies whether to attempt to update the system
                   environment first. Defaults to --system.
   --quiet         Print nothing.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>, KMX E<lt>kmx@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis Jewell

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

:endofperl
