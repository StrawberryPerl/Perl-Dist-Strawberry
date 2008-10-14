package Perl::Dist::Bootstrap;

use 5.006;
use strict;
use Perl::Dist::Strawberry      ();
use Perl::Dist::Util::Toolchain ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.05_01';
	@ISA     = 'Perl::Dist::Strawberry';
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'bootperl',
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
	'bootstrap-perl-' . $_[0]->perl_version_human . '.3';
}






#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $path  = File::Spec->catdir(
		$share, 'bootstrap',
	);
	unless ( -d $path ) {
		die("Directory $path does not exist");
	}

	# Prepend it to the default include path
	return [
		$path,
		@{ $self->SUPER::patch_include_path },
	];
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
