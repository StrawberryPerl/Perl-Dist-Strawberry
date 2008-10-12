use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/Strawberry.pm';
requires       'Object::Tiny' => '1.06';
requires       'Perl::Dist'   => '1.05';
test_requires  'Test::More'   => '0.42';
test_requires  'File::Spec'   => '0.80';
test_requires  'File::Path'   => 0;
test_requires  'File::Remove' => 0;
test_requires  'URI::file'    => 0;
test_requires  'LWP::Online'  => 0;
install_script 'perldist_strawberry';
install_share;

WriteAll;
