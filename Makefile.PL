# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Strawberry';
author      'David A Golden <dagolden@cpan.org>';
license     'perl';
version     '0.1.2';
all_from    'lib/Perl/Dist/Strawberry.pm';

requires    'Perl::Dist::Builder'      => '0.0.4'; 

no_index    directory => 'extra';
no_index    directory => 'bin';

WriteAll;
