use inc::Module::Install;

all_from	'lib/Perl/Dist/Strawberry.pm';

# Perl::Dist 1.14 does not load its requirements.
# Delete when we can require a version that does.
requires	'Archive::Tar'              => '1.42';
requires	'Archive::Zip'              => '1.26';
requires	'File::Spec'                => '3.29';
requires	'File::Copy::Recursive'     => '0.38';
requires	'File::Find::Rule'          => '0.30';
requires	'File::Path'                => '2.07';
requires	'File::pushd'               => '1.00';
requires	'File::Remove'              => '1.42';
requires	'File::HomeDir'             => '0.82';
requires	'File::ShareDir'            => '1.00';
requires	'File::PathList'            => '1.04';
requires	'File::Temp'                => '0.21';
requires	'HTTP::Status'              => '5.817';
requires	'IPC::Run3'                 => '0.042';
requires	'LWP::UserAgent'            => '5.823';
requires	'LWP::UserAgent::WithCache' => '0.06';
requires	'LWP::Online'               => '1.07';
requires	'Object::Tiny'              => '1.06';
requires	'YAML::Tiny'                => '1.36';
requires	'Module::CoreList'          => '2.17';
requires	'Params::Util'              => '0.35';
requires	'Template'                  => '2.20';
requires	'CPAN'                      => '1.9301';
requires	'PAR::Dist'                 => '0.42';
requires	'Process'                   => '0.25';
requires	'Process::Storable'         => '0.25';
requires	'Process::Delegatable'      => '0.25';
requires	'IO::Capture'               => '0.05';
requires	'Win32::File::Object'       => '0.01' if winlike;
requires	'Portable::Dist'            => '0.02';
requires	'Probe::Perl'               => '0.01';

requires	'Perl::Dist'      => '1.14';
requires	'Perl::Dist::WiX' => '0.183';
test_requires	'Test::More'      => '0.42';
test_requires	'File::Spec'      => '3.2701';
test_requires	'File::Path'      => '2.04';
test_requires	'File::Remove'    => '1.42';
test_requires	'URI::file'       => '1.37';
test_requires	'LWP::Online'     => '1.07';
install_script	'perldist_strawberry';
install_share;

WriteAll;
