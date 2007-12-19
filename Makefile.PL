use strict;
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Strawberry';
all_from    'lib/Perl/Dist/Strawberry.pm';
author      'Adam Kennedy <adamk@cpan.org>';
license     'perl';
version     '0.51';
all_from    'lib/Perl/Dist/Strawberry.pm';
requires    'Perl::Dist' => '0.51'; 
no_index    directory => 'extra';

WriteAll;
