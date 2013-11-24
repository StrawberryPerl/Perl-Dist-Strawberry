use strict;
use warnings;

use Win32;
use File::Basename;

my $name = 'c:\strawberry\perl\bin\perlthanks.bat';
my $s = Win32::GetShortPathName($name);
my $r = basename($s);;

warn "s='$s'\n";
warn "r='$r'\n";

