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

Perl 5.8.9 or Perl 5.10.0

=item *

MingW GCC C/C++ compiler

=item *

Dmake "make" tool

=item *

Every bundled and dual-life module upgraded to the latest version.

=item *

L<Bundle::CPAN>, L<Bundle::LWP> and L<CPAN::SQLite> to enhance the
functionality of the CPAN client.

=item *

Additional Perl modules that enhance the stability of core Perl for
the Win32 platform

=item *

Modules that enhance the ability to install non-CPAN packages such as
L<PAR::Dist>, L<PPM> and L<pip>.

=item *

Prebuilt and known-good C libraries for math, crypto and XML support.

=item *

Additions that provide L<Portable> support.

=back

The B<Perl::Dist::Strawberry> module available on CPAN contains the modules
and L<perldist_strawberry> script that are used to generate the
Strawberry Perl installers.

Please note that B<Perl::Dist::Strawberry> B<does not> include the
resulting Strawberry Perl installer. See the Strawberry Perl website at
L<http://strawberryperl.com/> to download the Strawberry Perl installer.

See L<Perl::Dist::WiX> for details on how the underlying distribution
construction toolkit works.

=head1 CHANGES FROM CORE PERL

Strawberry Perl is and will continue to be based on the latest "stable"
releases of Perl, currently 5.8.9, and 5.10.0.

Some additional modifications are included that improve general
compatibility with the Win32 platform or improve "turnkey" operation on
Win32.

Whenever possible, these modifications will be made only by preinstalling
additional or updated CPAN modules within Strawberry Perl, particularly
modules that have been newly included as core Perl modules in the
"development" branch of perl to address Win32 compatibility issues.

Additionally, a stub CPAN Config.pm file is added.  This provides a
complete zero-conf preconfiguration for CPAN, using a stable
L<http://cpan.strawberryperl.com/> redirector to bounce to a
known-reliable mirrors.

A more-thorough network-aware zero-conf capability is currently being
developed and will be included at a later time.

Strawberry has B<never> patched the Perl source code or modified the
perl.exe binary.

=head1 CONFIGURATION

At present, Strawberry Perl must be installed in C:\strawberry.  The
executable installer adds the following environment variable changes:

  * Adds directories to PATH
    - C:\strawberry\perl\bin  
    - C:\strawberry\c\bin  

Users installing Strawberry Perl without the installer will need to
add the environment entries manually.

=head1 METHODS

In addition to extending various underlying L<Perl::Dist::WiX> methods,
Strawberry Perl adds some additional methods that provide installation
support for miscellaneous tools that have not yet been promoted to the
core.

=cut

use 5.006;
use strict;
use base                        qw( Perl::Dist::WiX );
use File::Spec::Functions       qw( catfile catdir  );
use URI::file                   qw();
use Perl::Dist::Machine         qw();
use Perl::Dist::Util::Toolchain qw();
use File::ShareDir              qw();

use vars qw($VERSION);
BEGIN {
	$VERSION = '2.00';
}

use Object::Tiny qw{
	bin_patch
};





#####################################################################
# Build Machine Generator

=pod

=head2 default_machine

  Perl::Dist::Strawberry->default_machine->run;
  
The C<default_machine> class method is used to setup the most common
machine for building Strawberry Perl.

The machine provided creates a standard 5.8.8 distribution (.zip and .exe),
a standard 5.8.9 distribution (.zip and .exe), a standard 5.10.0 
distribution (.zip and .exe) and a Portable-enabled 5.10.0 distribution 
(.zip only).

Returns a L<Perl::Dist::Machine> object.

=cut

sub default_machine {
	my $class = shift;

	# Create the machine
	my $machine = Perl::Dist::Machine->new(
		class => $class,
		@_,
	);

	# Set the different versions
	$machine->add_dimension('version');
	$machine->add_option('version',
		perl_version => '589',
	    build_number => 2,
	);
	$machine->add_option('version',
		perl_version => '5100',
	);
	$machine->add_option('version',
		perl_version => '5100',
		portable     => 1,
	);

	# Set the different paths
	$machine->add_dimension('drive');
	$machine->add_option('drive',
		image_dir => 'C:\strawberry',
	);
	$machine->add_option('drive',
		image_dir => 'D:\strawberry',
		msi       => 1,
		zip       => 0,
	);

	return $machine;
}





#####################################################################
# Configuration

# Apply default paths
sub new {
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');

	# This is so msi_directory_tree_additions is additive, and doesn't
	# get replaced by the subclass' parameter of that name.
	my $self = shift;
	my $params = {@_};
	my $additions = $params->{msi_directory_tree_additions} || [];
	$params->{perl_version} ||= '5100';
	my @additions = @{$additions};
	unshift @additions, qw(
		perl\lib\ExtUtils\CBuilder
		perl\lib\ExtUtils\CBuilder\Platform
		perl\lib\IO\Compress\Adapter
		perl\lib\IO\Compress\Base
		perl\lib\IO\Compress\Gzip
		perl\lib\IO\Compress\Zip
		perl\lib\IO\Uncompress\Adapter
		perl\lib\Math\BigInt\FastCalc
		perl\lib\auto\Cwd
		perl\site\lib\Bundle
		perl\site\lib\Bundle\DBD
		perl\site\lib\CPAN
		perl\site\lib\DBD
		perl\site\lib\IPC
		perl\site\lib\JSON
		perl\site\lib\LWP
		perl\site\lib\Math
		perl\site\lib\PAR
		perl\site\lib\PAR\Dist
		perl\site\lib\PAR\Repository
		perl\site\lib\Parse
		perl\site\lib\Pod
		perl\site\lib\Test
		perl\site\lib\XML
		perl\site\lib\XML\LibXML
		perl\site\lib\auto\CPAN
		perl\site\lib\auto\DBD
		perl\site\lib\auto\DBD\mysql
		perl\site\lib\auto\IPC
		perl\site\lib\auto\JSON
		perl\site\lib\auto\LWP
		perl\site\lib\auto\Math
		perl\site\lib\auto\PAR
		perl\site\lib\auto\PAR\Dist
		perl\site\lib\auto\PAR\Repository
		perl\site\lib\auto\Parse
		perl\site\lib\auto\Pod
		perl\site\lib\auto\Test
		perl\site\lib\auto\Win32\File
		perl\site\lib\auto\XML
		perl\site\lib\auto\XML\LibXML
	);
	if (substr ($params->{perl_version}, 0, 2) eq '58') {
		unshift @additions, qw(
			perl\site\lib\Module
		);
	}
	@additions = sort @additions;
	$params->{msi_directory_tree_additions} = \@additions;

	$self->SUPER::new(
		app_id               => 'strawberryperl',
		app_name             => 'Strawberry Perl',
		app_publisher        => 'Vanilla Perl Project',
		app_publisher_url    => 'http://www.strawberryperl.com/',
		image_dir            => 'C:\strawberry',

		# Program version.
		build_number         => 6,

		# New options for msi building...
		msi_license_file     => catfile($dist_dir, 'License-short.rtf'),
		msi_product_icon     => catfile(File::ShareDir::dist_dir('Perl-Dist-WiX'), 'win32.ico'),
		msi_help_url         => 'http://www.strawberryperl.com/support.html',
		msi_banner_top       => catfile($dist_dir, 'StrawberryBanner.bmp'),
		msi_banner_side      => catfile($dist_dir, 'StrawberryDialog.bmp'),

		# Set e-mail to something Strawberry-specific.
		perl_config_cf_email => 'win32-vanilla@perl.org',

		# Build both msi and zip versions
		msi                  => 1,
		zip                  => 1,

		%{$params},
	);
}

# Lazily default the full name.
# Supports building multiple versions of Perl.
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name
		. ($_[0]->portable ? ' Portable' : '')
		. ' ' . $_[0]->perl_version_human
		. '.' . $_[0]->build_number
		. ($_[0]->beta_number ? ' Beta ' . $_[0]->beta_number : '');
}

# Lazily default the file name.
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl'
		. '-' . $_[0]->perl_version_human
		. '.' . $_[0]->build_number
		. ($_[0]->image_dir =~ /^d:/i ? '-ddrive' : '')
		. ($_[0]->portable ? '-portable' : '')
		. ($_[0]->beta_number ? '-beta-' . $_[0]->beta_number : '')
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

	# Database Libraries
	# $self->install_libdb;

	return 1;
}

sub install_libdb {
	my $self = shift;

	$self->install_binary(
		name       => 'libdb',
		url        => $self->binary_url('db-4.7.25-vanilla.tar.gz'),
		install_to => {
			'bin'     => 'c/bin',
			'include' => 'c/include',
			'lib'     => 'c/lib',
		},
		license    => {
			'LICENSE' => 'libdb/LICENSE',
		},
	);

	return 1;
}





#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $path  = File::Spec->catdir( $share, 'strawberry' );
	unless ( -d $path ) {
		die("Directory $path does not exist");
	}

	# Prepend to the default include path
	return [ $path,
		@{ $self->SUPER::patch_include_path },
	];
}

sub install_perl_588_bin {
	my $self   = shift;
	my %params = @_;
	my $patch  = delete($params{patch}) || [];
	return $self->SUPER::install_perl_588_bin(
		patch => [ qw{
			win32/config.gc
		}, @$patch ],
		%params,
	);
}

sub install_perl_5100_bin {
	my $self   = shift;
	my %params = @_;
	my $patch  = delete($params{patch}) || [];
	return $self->SUPER::install_perl_5100_bin(
		patch => [ qw{
			win32/config.gc
		}, @$patch ],
		%params,
	);
}

sub install_perl_modules {
	my $self = shift;

	$self->install_cpan_upgrades;
	
	# Install LWP::Online so our custom minicpan code works
	$self->install_distribution(
		name => 'ADAMK/LWP-Online-1.07.tar.gz'
	);

	# Win32 Modules
	$self->install_modules( qw{
		Win32::File
		File::Remove
		Win32::File::Object
		Win32::API
		Parse::Binary
		Win32::Exe
	} );

	# Install additional math modules
	$self->install_pari;
	$self->install_modules( qw{
		Math::BigInt::GMP
	} );

	# XML Modules
	$self->install_distribution(
		name             => 'MSERGEANT/XML-Parser-2.36.tar.gz',
		makefilepl_param => [
			'EXPATLIBPATH=' . $self->dir(qw{ c lib     }),
			'EXPATINCPATH=' . $self->dir(qw{ c include }),
		],
	);

	$self->install_modules( qw{
		XML::NamespaceSupport
		XML::SAX
		XML::LibXML::Common
	} );

	$self->install_module(
		name => 'XML::LibXML',
	);

	# Networking Enhancements
	# All the Bundle::LWP modules are
	# included in the toolchain or in the upgrades.

	# Binary Package Support
	$self->install_modules( qw{
		PAR::Dist
		PAR::Dist::FromPPD
		PAR::Dist::InstallPPD
		Sub::Uplevel
		Test::Exception
		Array::Compare
		Tree::DAG_Node
		Test::Warn
		Test::Tester
		Test::NoWarnings
		Test::Deep
		IO::Scalar
	} );
	$self->install_distribution(
		name  => 'RKINYON/DBM-Deep-1.0013.tar.gz',
		force => 1,
	);
	$self->install_modules( qw{
		YAML::Tiny
		PAR
		PAR::Repository::Query
		PAR::Repository::Client
	} );
	$self->install_ppm;

	my $cpan_sources = catdir($self->image_dir, 'cpan', 'sources');
	unless (-d $cpan_sources) {
		require File::Path;
		File::Path::mkpath($cpan_sources);
	}
	
	# Console Utilities
	$self->install_modules( qw{
		IPC::Run3
		Test::Script
		Probe::Perl
		Number::Compare
		File::Find::Rule
		Data::Compare
		File::chmod
		Params::Util
		CPAN::Checksums
		CPAN::Inject
		File::pushd
		pler
		pip
	} );

	# BerkelyDB Support
	#$self->install_distribution(
	#	name => 'DB_File',
	#	url  => 'http://strawberryperl.com/package/DB_File-1.1817-vanilla.tar.gz',
	#);
	#$self->install_distribution(
	#	name => 'BerkeleyDB',
	#	url  => 'http://strawberryperl.com/package/BerkeleyDB-0.34-vanilla.tar.gz',
	#);

	# CPAN::SQLite Modules
	$self->install_modules( qw{
		DBI
		DBD::SQLite
		CPAN::DistnameInfo
		CPAN::SQLite
	} );

	# Copy the files that CPAN::SQLite needs.
	# $self->copy_cpan_sqlite_files();
	
	# CPANPLUS::Internals::Source::SQLite 
	# needs this module, so adding it.
	$self->install_modules( qw{
		DBIx::Simple
	} ) if ($self->perl_version eq '5100');
	
	# Support for other databases.
	$self->install_modules( qw{
		DBD::ODBC
	} );
	$self->install_dbd_mysql;
#	$self->install_dbd_pg;

	my $filelist = $self->install_binary(
		name       => 'db_libraries',
		url        => $self->binary_url('DatabaseLibraries-07292009.zip'),
		install_to => q{.}
	);
	$self->insert_fragment( 'db_libraries', $filelist->files );

	# JSON installation
	$self->install_modules( qw{
		JSON::XS
		JSON
	} );	

	# Local library installation.
	$self->install_module(    # Fails its test because of a packaging problem in 1.004002 only.
		name => 'local::lib',
		force => 1,
	);
	
#	$self->trace_line(0, "Loading extra Strawberry packlists\n");

	# Insert ParserDetails.ini
	$self->add_to_fragment('XML_SAX', [ catfile($self->image_dir, qw(perl site lib XML SAX ParserDetails.ini)) ]);

	return 1;
}





#####################################################################
# Customisations to Windows assets

sub install_win32_extras {
	my $self = shift;

	# Add the rest of the extras
	$self->SUPER::install_win32_extras(@_);

	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	
	# Link to the Strawberry Perl website.
	# Don't include this for non-Strawberry sub-classes
	if ( ref($self) eq 'Perl::Dist::Strawberry' ) {
		$self->install_website(
			name       => 'Strawberry Perl Website',
			url        => $self->strawberry_url,
			icon_file  => catfile($dist_dir, 'strawberry.ico')
		);
		$self->install_website(
			name       => 'Live Support',
			url        => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23win32',
			icon_file  => catfile($dist_dir, 'onion.ico')
		);
	}

	my $license_file_from = catfile($dist_dir, 'License.rtf');
	my $license_file_to = catfile($self->license_dir, 'License.rtf');
	
	$self->_copy($license_file_from, $license_file_to);
	$self->add_to_fragment('perl_licenses', [ $license_file_to ]);
	
	return 1;
}

sub strawberry_url {
	my $self = shift;
	my $path = $self->output_base_filename;

	# Strip off anything post-version
	unless ( $path =~ s/^(strawberry-perl-\d+(?:\.\d+)+).*$/$1/ ) {
		die "Failed to generate the strawberry subpath";
	}

	return "http://strawberryperl.com/$path";
}





#####################################################################
# Custom Installation Methods

=pod

=head2 install_patch

  $dist->install_patch;

The C<install_path> method can be used to install a copy of the Unix
patch program into the distribution.

Returns true or throws an exception on error.

=cut

sub install_patch {
	my $self = shift;

	my $filelist = $self->install_binary(
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

	$self->insert_fragment('patch', $filelist->files);

	return 1;
}

=pod

=head2 install_ppm

  $dist->install_ppm;

Installs the PPM module, and then customises the temp path to live
underneath the strawberry dist.

=cut

sub install_ppm {
	my $self = shift;

	# Where should the ppm build directory be
	my $ppmdir = File::Spec->catdir(
		$self->image_dir,
		'ppm',
	);
	if ( -d $ppmdir ) {
		die("PPM build direcotry '$ppmdir' already exists");
	}

	# Add the ppm directory to the build.
	$self->directories->add_root_directory(
		'PPM',       'ppm'
	);

	# To make sure it's seeable outside of the scope.
	my $filelist;

	SCOPE: {
		# The build path in ppm.xml is derived from $ENV{TMP}.
		# So set TMP to a dedicated location inside of the
		# distribution root to prevent it being locked to the
		# temp directory of the build machine.
		local $ENV{TMP} = $ppmdir;

		# Create the ppm temp directory so it exists when
		# the PPM build needs it.
		$filelist = $self->install_file(
			share      => 'Perl-Dist-Strawberry ppm/README.txt',
			install_to => 'ppm/README.txt',
		);
		unless ( -d $ppmdir ) {
			die("Failed to create '$ppmdir' directory");
		}

		# Install PPM itself
		$self->install_distribution(
			name => 'RKOBES/PPM-0.01_01.tar.gz',
			url  => 'http://strawberryperl.com/package/PPM-0.01_01.tar.gz',
		);
	}

	# Add the readme file.
	$self->add_to_fragment('PPM', $filelist->files);

	# Add the ppm.xml file.
	$self->add_to_fragment('PPM', [ catfile($self->image_dir, qw(perl site lib ppm.xml)) ]);

	return 1;
}

=pod

=head2 install_win32_manifest

  $dist->install_win32_manifest( 'WX Perl' => 'perl', 'bin', 'wxperl.exe' );

Installs a manifest file to make an executable binary look like a "real"
Win32 program.

=cut

sub install_win32_manifest {
	my $self = shift;
	my $name = shift;

	# Generate the file contents
	my $manifest = <<"END_MANIFEST";
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
 <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
     <assemblyIdentity
         processorArchitecture="x86"
         version="5.1.0.0"
         type="win32"
         name="Controls"
     />
     <description>$name</description>
     <dependency>
         <dependentAssembly>
             <assemblyIdentity
                 type="win32"
                 name="Microsoft.Windows.Common-Controls"        
                 version="6.0.0.0"
                 publicKeyToken="6595b64144ccf1df"
                 language="*"
                 processorArchitecture="x86"
         />
     </dependentAssembly>
     </dependency>
 </assembly>
END_MANIFEST

	# Write the manifest
	my $file = File::Spec->catfile( $self->image_dir, @_ );
	unless ( -f $file ) {
		die "Program $file does not exist";
	}

	SCOPE: {
		local *FILE;
		open( FILE, '>', "$file.manifest" ) or die "open: $!";
		print FILE $manifest                or die "print: $!";
		close( FILE )                       or die "close: $!";
	}

	return 1;	
}

=pod

=head2 install_dbd_mysql

  $dist->install_dbd_mysql;

Installs DBD::mysql from the PAR files on the Strawberry Perl web site.

=cut

sub install_dbd_mysql {
	my $self = shift;
	my $filelist;

	if ($self->perl_version eq '5100') {
		$filelist = $self->install_par(
		  name => 'DBD_mysql', 
		  url => 'http://strawberryperl.com/package/DBD-mysql-4.012-MSWin32-x86-multi-thread-5.10.0.par'
		);
		$self->insert_fragment( 'DBD_mysql', $filelist->files );
	} elsif ($self->perl_version eq '589') {
		$self->trace_line(0, "Installing DBD::mysql is untested in 5.8.9.\n");
		$filelist = $self->install_par(
		  name => 'DBD_mysql', 
		  url => 'http://strawberryperl.com/package/DBD-mysql-4.012-MSWin32-x86-multi-thread-5.8.9.par'
		);
		$self->insert_fragment( 'DBD_mysql', $filelist->files );
	} else {
		PDWiX->throw('Could not install DBD::mysql - invalid version of perl');
	}
}

=pod

=head2 install_dbd_pg

  $dist->install_dbd_pg;

Installs DBD::Pg from the PAR files on the Strawberry Perl web site.

=cut

sub install_dbd_pg {
	my $self = shift;
	my $filelist;
	
	if ($self->perl_version eq '5100') {
		$filelist = $self->install_par(
		  name => 'DBD_Pg', 
		  url => 'http://strawberryperl.com/package/DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.10-5.10.0.par'
		);
		$self->insert_fragment( 'DBD_Pg', $filelist->files );
	} elsif ($self->perl_version eq '589') {
		$self->trace_line(0, "Installing DBD::Pg is untested in 5.8.9.\n");
		$filelist = $self->install_par(
		  name => 'DBD_Pg', 
		  url => 'http://strawberryperl.com/package/DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.8-5.8.9.par'
		);
		$self->insert_fragment( 'DBD_Pg', $filelist->files );
	} else {
		PDWiX->throw('Could not install DBD::Pg - invalid version of perl');
	}
}

=pod

=head3 install_pari

  $dist->install_pari

The C<install_pari> method install (via a PAR package) libpari and the
L<Math::Pari> module into the distribution.

This method should only be called at during the install_modules phase.

=cut

sub install_pari {
	my $self = shift;
	my $filelist;
	
	if ($self->perl_version eq '5100') {
		$filelist = $self->install_par(
		  name => 'pari', 
		  url => 'http://strawberryperl.com/package/Math-Pari-2.010801-MSWin32-x86-multi-thread-5.10.0.par'
		);
		$self->insert_fragment( 'pari', $filelist->files );
	} elsif ($self->perl_version eq '589') {
		$self->trace_line(0, "Installing DBD::Pg is untested in 5.8.9.\n");
		$filelist = $self->install_par(
		  name => 'pari', 
		  url => 'http://strawberryperl.com/package/Math-Pari-2.010801-MSWin32-x86-multi-thread-5.8.9.par'
		);
		$self->insert_fragment( 'pari', $filelist->files );
	} else {
		PDWiX->throw('Could not install DBD::Pg - invalid version of perl');
	}

	return 1;
} ## end sub install_pari


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

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.  Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
