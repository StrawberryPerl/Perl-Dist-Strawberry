use strict;
use warnings;

use Test::More tests => 1;

diag( "Testing Perl::Dist::Strawberry $Perl::Dist::Strawberry::VERSION, Perl $], $^X" );

my $ok;
END { BAIL_OUT "Could not load all modules" unless $ok }

use Perl::Dist::Strawberry;
use Perl::Dist::Strawberry::Step;
use Perl::Dist::Strawberry::Step::BinaryToolsAndLibs;
use Perl::Dist::Strawberry::Step::CreateRelocationFile;
use Perl::Dist::Strawberry::Step::FilesAndDirs;
use Perl::Dist::Strawberry::Step::InstallModules;
use Perl::Dist::Strawberry::Step::InstallPerlCore;
use Perl::Dist::Strawberry::Step::OutputMSM_MSI;
use Perl::Dist::Strawberry::Step::OutputPortableZIP;
use Perl::Dist::Strawberry::Step::OutputZIP;
use Perl::Dist::Strawberry::Step::SetupPortablePerl;
use Perl::Dist::Strawberry::Step::UpgradeCpanModules;

ok 1, 'All modules loaded successfully';
$ok = 1;

