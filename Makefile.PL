use inc::Module::Install::DSL 1.00;

all_from       lib/Perl/Dist/Strawberry.pm
requires       Perl::Dist::WiX  1.250
test_requires  Test::More       0.42
test_requires  File::Spec       3.2701
test_requires  File::Path       2.04
test_requires  File::Remove     1.42
test_requires  URI::file        4.20
test_requires  LWP::Online      1.07
test_requires  Test::Perl::Dist 0.300
install_script perldist_strawberry
recursive_author_tests xt
install_share
use_ptar
