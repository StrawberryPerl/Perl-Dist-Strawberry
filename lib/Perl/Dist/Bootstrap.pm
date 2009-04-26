package Perl::Dist::Bootstrap;

=pod

=head1 NAME

Perl::Dist::Bootstrap - A Perl distribution for building Perl distributions

=head1 DESCRIPTION

Bootstrap Perl is a subclass and variant of Strawberry Perl that installs
into a different directory (C:\bootstrap) than Strawberry Perl so that
it won't be "in the way" when building Strawberry and other Perls.

It also comes prepackaged with a number of additional modules that are
dependencies of Perl::Dist.

=cut

use 5.006;
use strict;
use Perl::Dist::Strawberry      ();
use Perl::Dist::Util::Toolchain ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.11';
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
	my $path  = File::Spec->catdir( $share, 'bootstrap' );
	unless ( -d $path ) {
		die("Directory $path does not exist");
	}

	# Prepend it to the default include path
	return [ $path,
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
		File::HomeDir
		IPC::Run3
		LWP::UserAgent::WithCache
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
		Perl::Dist
	} );

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Strawberry>

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

For more support information and places for discussion, see the
Strawberry Perl Support page L<http://strawberryperl.com/support.html>.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
