use inc::Module::Install::DSL 0.83;

all_from       lib/Perl/Dist/Strawberry.pm
requires       Object::Tiny 1.06
requires       Archive::Zip 1.26
requires       Perl::Dist   1.13
test_requires  Test::More   0.42
test_requires  File::Spec   3.2701
test_requires  File::Path   2.04
test_requires  File::Remove 1.42
test_requires  URI::file    1.37
test_requires  LWP::Online  1.07
install_script perldist_strawberry
install_share
