use strict;
use inc::Module::Install;

name          'Perl-Dist-Strawberry';
author        'Adam Kennedy <adamk@cpan.org>';
license       'perl';
version       '1.00';
all_from      'lib/Perl/Dist/Strawberry.pm';
requires      'Perl::Dist' => '0.90'; 

WriteAll;
