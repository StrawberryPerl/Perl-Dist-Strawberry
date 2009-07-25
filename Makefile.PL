use inc::Module::Install::DSL 0.91;

all_from       lib/Perl/Dist/Strawberry.pm
requires       Perl::Dist      1.16
requires       Perl::Dist::WiX 1.000
test_requires  Test::More      0.42
test_requires  File::Spec      3.2701
test_requires  File::Path      2.04
test_requires  File::Remove    1.42
test_requires  URI::file       4.20
test_requires  LWP::Online     1.07
install_script perldist_strawberry
install_share
