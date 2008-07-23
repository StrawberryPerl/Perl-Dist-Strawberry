package Perl::Dist::Strawberry;

=pod

=head1 NAME

Perl::Dist::Strawberry - Strawberry Perl for win32

=head1 DESCRIPTION

Strawberry Perl is a binary distribution of Perl for the Windows operating
system.  It includes a bundled compiler and pre-installed modules that offer
the ability to install XS CPAN modules directly from CPAN.

The purpose of the Strawberry Perl series is to provide a practical Win32 Perl
environment for experienced Perl developers to experiment with and test the
installation of various CPAN modules under Win32 conditions, and to provide a
useful platform for doing real work.

Strawberry Perl includes:

=over

=item *

Perl 5.8.8 or Perl 5.10.0

=item *

Mingw GCC C/C++ compiler

=item *

Dmake "make" tool

=item *

L<Updates for many toolchain modules>

=item *

L<Bundle::CPAN> (including Perl modules that eliminate the need for
external helper programs like C<gzip> and C<tar>)

=item *

L<Bundle::LWP> (providing more reliable http CPAN repository support)

=item *

Additional Perl modules that enhance the stability of core Perl for the
Win32 platform

=item *

Other modules that improve the toolchain, or enhance the ability to
install packages.

=back

The B<Perl::Dist::Strawberry> modules on CPAN contains programs and
instructions for downloading component sources and assembling them into the
executable installer for Strawberry Perl.  It B<does not> include the
resulting Strawberry Perl installer.  

See the Strawberry Perl website at L<http://strawberryperl.com/> to download
the Strawberry Perl installer.

See L<Perl::Dist::Build> at L<http://search.cpan.org> for details on 
the builder used to create Strawberry Perl from source.

=head1 CHANGES FROM CORE PERL

Strawberry Perl is and will continue to be based on the latest "stable" release
of Perl, currently version 5.8.8.  Some additional modifications are included
that improve general compatibility with the Win32 platform or improve
"turnkey" operation on Win32.  

Whenever possible, these modifications will be made only by preinstalling
additional CPAN modules within Strawberry Perl, particularly modules that have
been newly included as core Perl modules in the "development" branch of perl
to address Win32 compatibility issues.

Modules or distributions currently included are:

=over

=item *

ExtUtils::MakeMaker 6.30_01 -- fixes a Win32 perl path bug

=item *

CPAN 1.87_57 -- many small fixes for numerous annoyances on Win32

=item * 

Win32API::File -- to allow for deletion of in-use files at next reboot;
required for CPAN.pm to be able to upgrade itself

=item *

IO -- to address Win32 Socket bugs
    
=item *

Compress::Zlib, IO::Zlib and Archive::Tar -- to eliminate the CPAN.pm
dependency on external, binary programs to handle .tar.gz files

=item *

Archive::Zip (and its dependency, Time::Local) -- to eliminate the CPAN.pm
dependency on external, binary programs to handle .zip files

=item *

libnet -- provides Net::FTP to eliminate the CPAN.pm dependency on an external,
binary ftp program; installed configured for FTP passive mode

=back

Additionally, a stub CPAN Config.pm file is installed.  It provides defaults
to the path for dmake, to automatically follow dependencies and to use the
Windows temporary directory for the CPAN working directory. 

=head1 CONFIGURATION

At present, Strawberry Perl must be installed in C:\strawberry.  The
executable installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\strawberry\perl\bin  
        - C:\strawberry\c\bin  

Users installing Strawberry Perl without the installer will need to
change the environment manually.

=head1 METHODS

In addition to extending various underlying L<Perl::Dist::Inno> methods,
Strawberry Perl adds some additional methods that provide installation
support for miscellaneous tools that have not yet been promoted to the
core.

=cut

use 5.006;
use strict;
use Perl::Dist ();
use Perl::Dist::Util::Toolchain ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.03';
	@ISA     = 'Perl::Dist';
}

use Object::Tiny qw{
	bin_patch
};





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'strawberryperl',
		app_name          => 'Strawberry Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\strawberry',

		# Build both exe and zip versions
		exe               => 1,
		zip               => 1,

		@_,
	);
}

# Lazily default the full name.
# Supports building multiple versions of Perl.
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name
		. ($_[0]->portable ? ' Portable' : '')
		. ' ' . $_[0]->perl_version_human
		. '.1';
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl-'
		. ($_[0]->portable ? '-portable' : '')
		. $_[0]->perl_version_human
		. '.1-1';
}





#####################################################################
# Customisations for C assets

sub install_c_toolchain {
	my $self = shift;
	$self->SUPER::install_c_toolchain(@_);

	# Extra Binary Tools
	$self->install_patch;

	return 1;
}

sub install_c_libraries {
	my $self = shift;
	$self->SUPER::install_c_libraries(@_);

	# XML Libraries
	$self->install_zlib;
	$self->install_libiconv;
	$self->install_libxml;
	$self->install_expat;

	# Math Libraries
	$self->install_gmp;

	return 1;
}

=pod

=head2 install_patch

The C<install_path> method can be used to install a copy of the Unix
patch program into the distribution.

Returns true or throws an exception on error.

=cut

sub install_patch {
	my $self = shift;

	$self->install_binary(
		name       => 'patch',
		url        => $self->binary_url('patch-2.5.9-7-bin.zip'),
		install_to => {
			'bin/patch.exe' => 'c/bin/patch.exe',
		},
	);
	$self->{bin_patch} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'patch.exe',
	);
	unless ( -x $self->bin_patch ) {
		die "Can't execute patch";
	}

	return 1;
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	$self->SUPER::install_perl_588(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Strawberry CPAN_Config_588.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_5100 {
	my $self = shift;
	$self->SUPER::install_perl_5100(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Strawberry CPAN_Config_5100.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;

	# Install LWP::Online, so our custom minicpan code works
	$self->install_distribution(
		name => 'ADAMK/LWP-Online-0.04.tar.gz'
	);

	# Win32 Modules
	$self->install_modules( qw{
		Win32::File
		Win32::File::Object
		Win32::API
		Win32::Env::Path
		Win32::Exe
	} );

	# Install additional math modules
	$self->install_pari;
	$self->install_modules(qw{
		Math::BigInt
		Math::BigInt::FastCalc
		Math::BigRat
	});
	$self->install_distribution(
		name => 'TELS/math/Math-BigInt-GMP-1.24.tar.gz',
	);

	# XML Modules
	$self->install_distribution(
		name             => 'MSERGEANT/XML-Parser-2.36.tar.gz',
		makefilepl_param => [
			'EXPATLIBPATH=' . $self->dir(qw{ c lib     }),
			'EXPATINCPATH=' . $self->dir(qw{ c include }),
		],
	);
	$self->install_module(
		name => 'XML::LibXML',
	);

	# Networking Enhancements
	$self->install_modules( qw{
		Bundle::LWP
		LWP::Online
	} );

	# Binary Package Support
	$self->install_modules( qw{
		PAR::Dist::InstallPPD
		PAR::Repository::Client
	} );
	$self->install_distribution(
		name => 'RKOBES/PPM-0.01_01.tar.gz',
		url  => 'http://strawberryperl.com/package/PPM-0.01_01.tar.gz',
	);

	# Console Utilities
	$self->install_modules( qw{
		pler
		pip
	} );

	# CPAN::SQLite Modules
	$self->install_module(
		name => 'DBI',
	);
	$self->install_distribution(
		name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
		force => 1,
	);
	$self->install_module(
		name => 'CPAN::SQLite',
	);

	return 1;
}





#####################################################################
# Customisations to Windows assets

sub install_win32_extras {
	my $self = shift;

	# Link to the Strawberry Perl website.
	# Don't include this for non-Strawberry sub-classes
        if ( ref($self) eq 'Perl::Dist::Strawberry' ) {
		$self->install_file(
			name       => 'Strawberry Perl Website Icon',
			url        => 'http://strawberryperl.com/favicon.ico',
			install_to => 'Strawberry Perl Website.ico',
		);
		$self->install_website(
			name       => 'Strawberry Perl Website',
			url        => 'http://strawberryperl.com/' . $self->output_base_filename,
			icon_file  => 'Strawberry Perl Website.ico',
		);
	}

	# Add the rest of the extras
	$self->SUPER::install_win32_extras(@_);

	return 1;
}

1;

=pod

=head1 SUPPORT

Please report bugs or feature requests using the CPAN Request Tracker.

Bugs can be sent by email to E<lt>bug-Perl-Dist-Strawberry@rt.cpan.orgE<gt>
or submitted using the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Perl-Dist-Strawberry>

For more support information and places for discussion, see the
Strawberry Perl Support page L<http://strawberryperl.com/support.html>.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
