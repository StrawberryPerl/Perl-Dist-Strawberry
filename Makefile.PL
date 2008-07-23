use inc::Module::Install 0.76;

name           'Perl-Dist-Strawberry';
author         'Adam Kennedy <adamk@cpan.org>';
license        'perl';
all_from       'lib/Perl/Dist/Strawberry.pm';
requires       'Perl::Dist' => '1.03';
test_requires  'Test::More' => '0.42';
install_script 'perldist_strawberry';
install_share;

WriteAll;
