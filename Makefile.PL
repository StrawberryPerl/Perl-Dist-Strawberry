# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Strawberry';
author      'David A Golden <dagolden@cpan.org>';
license     'perl';
all_from    'lib/Perl/Dist/Strawberry.pm';

requires    'Perl::Dist::Builder'      => '0.000001'; 

no_index    directory => 'extra';
no_index    directory => 'bin';

auto_install;
WriteAll;
