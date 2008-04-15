use inc::Module::Install;

name           'Perl-Dist-Strawberry';
author         'Adam Kennedy <adamk@cpan.org>';
license        'perl';
all_from       'lib/Perl/Dist/Strawberry.pm';
requires       'Perl::Dist' => '1.01';
test_requires  'Test::More' => '0.42';
install_script 'perldist_strawberry';
install_share;

WriteAll;
