package Perl::Dist::Bootstrap;

use 5.005;
use strict;
use base 'Perl::Dist::Strawberry';
use Perl::Dist::Util::Toolchain ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'bootstrapperl',
		app_name          => 'Bootstrap Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\bootperl',

		# Build both exe and zip versions
		exe               => 1,

		@_,
	);
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'boostrap-perl-' . $_[0]->perl_version_human . '.1';
}

sub install_perl_5100 {
	my $self = shift;
	$self->SUPER::install_perl_5100(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Strawberry bootperl_CPAN_Config_5100.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	# Install Perl::Dist itself
	$self->install_modules( qw{
		File::Copy::Recursive
		File::Find::Rule
		File::pushd
		File::Remove
		File::ShareDir
		File::Temp
		IPC::Run3
		LWP::UserAgent::Determined
		LWP::Online
		Object::Tiny
		Tie::File
		YAML::Tiny
		Module::CoreList
		Params::Util
		PAR::Dist
		Process
		Process::Storable
		Process::Delegatable
		IO::Capture
		Win32::File::Object
		Test::More
		Test::Script
		Test::LongString
		Probe::Perl
		Module::Install
	} );

	return 1;
}

1;
