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

Perl 5.8.9, Perl 5.10.0 or 5.10.1

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

use 5.010;
use strict;
use parent                           qw( Perl::Dist::WiX 
                                         Perl::Dist::Strawberry::Libraries );
use File::Spec::Functions            qw( catfile catdir  );
use URI::file                        qw();
use File::ShareDir                   qw();
use Perl::Dist::WiX::Util::Machine   qw();
use File::List::Object               qw();

our $VERSION = '2.02_05';
$VERSION =~ s/_//ms;

#####################################################################
# Build Machine Generator

=pod

=head2 default_machine

  Perl::Dist::Strawberry->default_machine(...)->run();
  
The C<default_machine> class method is used to setup the most common
machine for building Strawberry Perl.

The machine provided creates a standard 5.8.9 distribution (.zip and .msi),
a standard 5.10.1 distribution (.zip and .msi) and a Portable-enabled 5.10.1 
distribution (.zip only).

Returns a L<Perl::Dist::WiX::Util::Machine> object.

=cut

sub default_machine {
	my $class = shift;

	# Create the machine
	my $machine = Perl::Dist::WiX::Util::Machine->new(
		class => $class,
		@_,
	);

	# Set the different versions
	$machine->add_dimension('version');
	$machine->add_option('version',
		perl_version => '589',
	    build_number => 5,
	);
	$machine->add_option('version',
		perl_version => '5101',
	);
	$machine->add_option('version',
		perl_version => '5101',
		image_dir => 'D:\strawberry',
		msi       => 1,
		zip       => 0,
	);
	$machine->add_option('version',
		perl_version => '5101',
		portable     => 1,
	);

	return $machine;
}





#####################################################################
# Configuration

# Apply default paths
sub new {
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $class = shift;
	
	if ($Perl::Dist::WiX::VERSION < '1.102102') {
		PDWiX->throw('Perl::Dist::WiX version is not high enough.')
	}

	$class->SUPER::new(
		app_id               => 'strawberryperl',
		app_name             => 'Strawberry Perl',
		app_publisher        => 'Vanilla Perl Project',
		app_publisher_url    => 'http://www.strawberryperl.com/',
		image_dir            => 'C:\strawberry',

		# Perl version
		perl_version         => '5101',
		
		# Program version.
		build_number         => 2,
		beta_number          => 1,
		
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

		# Tasks to complete to create Strawberry
		tasklist => [
			'final_initialization',
			'install_c_toolchain',
			'install_strawberry_c_toolchain',
			'install_strawberry_c_libraries',
			'install_perl',
			'install_perl_toolchain',
			'install_cpan_upgrades',
			'install_strawberry_modules_1',
			'install_strawberry_modules_2',
			'install_strawberry_modules_3',
			'install_strawberry_modules_4',
			'install_strawberry_modules_5',
			'install_strawberry_files',
			'add_forgotten_files',
			'install_relocatable',
			'regenerate_fragments',
			'find_relocatable_fields',
			'write_merge_module',
			'install_win32_extras',
			'install_strawberry_extras',
			'install_portable',
			'remove_waste',
			'create_distribution_list',
			'regenerate_fragments',
			'write',
			'create_release_notes',
		],
		
		@_,
	);
}

sub dist_dir {
	return File::ShareDir::dist_dir('Perl-Dist-Strawberry');
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

sub add_forgotten_files {
	my $self = shift;

	return 1;
}

# Lazily default the file name.
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl'
		. '-' . $_[0]->perl_version_human()
		. '.' . $_[0]->build_number()
		. ($_[0]->image_dir() =~ /^d:/i ? '-ddrive' : q{})
		. ($_[0]->portable() ? '-portable' : q{})
		. (( 64 == $_[0]->bits() ) ? q{-64bit} : q{})
		. ($_[0]->beta_number() ? '-beta-' . $_[0]->beta_number() : q{})
}




#####################################################################
# Customisations for C assets

sub install_strawberry_c_toolchain {
	my $self = shift;

	# Extra Binary Tools
	$self->install_patch();

	return 1;
}

sub install_strawberry_c_libraries {
	my $self = shift;

	# XML Libraries
	$self->install_zlib();
	$self->install_libiconv();
	$self->install_libxml();
	$self->install_expat();
	$self->install_libxslt();

	# Math Libraries
	$self->install_gmp();

	# Graphics libraries
	$self->install_libjpeg();
	$self->install_libgif();
	$self->install_libtiff();
	$self->install_libpng();
	$self->install_libgd();
	$self->install_libfreetype();
	$self->install_libxpm();	
	
	# Database Libraries
	$self->install_libdb();
	$self->install_libgdbm();
 	if (32 == $self->bits()) {
		$self->install_libpostgresql();
	}

	# Crypto libraries
	$self->install_libopenssl();
	
	return 1;
}






#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	
	# Verify the subdirectories we need exist.
	my $path  = File::Spec->catdir( $share, 'strawberry' );
	my $portable  = File::Spec->catdir( $share, 'portable' );
	unless ( -d $path ) {
		die("Directory $path does not exist");
	}

	if ( $self->portable() ) {
		unless ( -d $portable ) {
			die("Directory $portable does not exist");
		}
		# Prepend to the default include path
		return [ $portable, $path,
			@{ $self->SUPER::patch_include_path() },
		];
	} else {
		# Prepend to the default include path
		return [ $path,
			@{ $self->SUPER::patch_include_path() },
		];
	}
}

sub install_perl_bin {
	my $self   = shift;
	my %params = @_;
	my $patch  = delete($params{patch}) || [];
	return $self->SUPER::install_perl_bin(
		patch => [ qw{
			win32/FindExt.pm
			ext/GDBM_File/GDBM_File.xs
			ext/GDBM_File/GDBM_File.pm
		}, @$patch ],
		%params,
	);
}

sub install_strawberry_modules_1 {
	my $self = shift;

	# Install LWP::Online so our custom minicpan code works
	if ($self->portable()) {
		$self->install_distribution(
			name     => 'ADAMK/LWP-Online-1.07.tar.gz',
			mod_name => 'LWP::Online',
			makefilepl_param => ['INSTALLDIRS=site'],
		);
	} else {
		$self->install_distribution(
			name     => 'ADAMK/LWP-Online-1.07.tar.gz',
			mod_name => 'LWP::Online',
			makefilepl_param => ['INSTALLDIRS=vendor'],
		);
	}

	# Win32 Modules
	$self->install_modules( qw{
		Win32::File
		File::Remove
		Win32::File::Object
		Parse::Binary
		Win32::Exe
		Win32::EventLog
	} );
	$self->install_modules('Win32::API') if not 64 == $self->bits();

	# Install additional math modules
	$self->install_pari() if not 64 == $self->bits();
	$self->install_modules( qw{
		Math::BigInt::GMP
	} );
	
	# XML Modules
	if ($self->portable()) {
		$self->install_distribution(
			name             => 'MSERGEANT/XML-Parser-2.36.tar.gz',
			mod_name         => 'XML::Parser',
			makefilepl_param => [
				'INSTALLDIRS=site',
				'EXPATLIBPATH=' . $self->_dir(qw{ c lib     }),
				'EXPATINCPATH=' . $self->_dir(qw{ c include }),
			],
		);
	} else {
		$self->install_distribution(
			name             => 'MSERGEANT/XML-Parser-2.36.tar.gz',
			mod_name         => 'XML::Parser',
			makefilepl_param => [
				'INSTALLDIRS=vendor',
				'EXPATLIBPATH=' . $self->_dir(qw{ c lib     }),
				'EXPATINCPATH=' . $self->_dir(qw{ c include }),
			],
		);
	}

	$self->install_modules( qw{
		XML::NamespaceSupport
		XML::SAX
		XML::LibXML
		XML::LibXSLT
	} );
	
	unless ($self->portable()) {
		# Insert ParserDetails.ini
		my $ini_file = catfile($self->image_dir(), qw(perl vendor lib XML SAX ParserDetails.ini));
		$self->add_to_fragment('XML_SAX', [ $ini_file ]);
	}
	
	return 1;
}

sub install_strawberry_modules_2 {
	my $self = shift;
	
	# Networking Enhancements
	# All the Bundle::LWP modules are
	# included in the toolchain or in the upgrades.
	
	# Binary Package Support
	$self->install_modules( qw{
		PAR::Dist
		PAR::Dist::FromPPD
		PAR::Dist::InstallPPD
		Tree::DAG_Node
		Sub::Uplevel
		Test::Warn
		Test::Tester
		Test::NoWarnings
		Test::Deep
		IO::Stringy
	} );
	
	if ($self->portable()) {
		$self->install_distribution(
			name             => 'RKINYON/DBM-Deep-1.0013.tar.gz',
			mod_name         => 'DBM::Deep',
			makefilepl_param => ['INSTALLDIRS=site'],
			buildpl_param    => ['--installdirs', 'site'],
			force            => 1,
		);
	} else {
		$self->install_distribution(
			name             => 'RKINYON/DBM-Deep-1.0013.tar.gz',
			mod_name         => 'DBM::Deep',
			makefilepl_param => ['INSTALLDIRS=vendor'],
			buildpl_param    => ['--installdirs', 'vendor'],
			force            => 1,
		);
	}
	
	$self->install_modules( qw{
		YAML::Tiny
		PAR
		PAR::Repository::Query
		PAR::Repository::Client
	} );
	$self->install_ppm();

	my $cpan_sources = catdir($self->image_dir, 'cpan', 'sources');
	unless (-d $cpan_sources) {
		require File::Path;
		File::Path::mkpath($cpan_sources);
	}
	
	# Console Utilities
	$self->install_modules( qw{
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
	
	return 1;
}

sub install_strawberry_modules_3 {
	my $self = shift;

	# CPAN::SQLite Modules
	$self->install_modules( qw{
		DBI
		DBD::SQLite
		CPAN::DistnameInfo
		CPAN::SQLite
	} );
	
	# CPANPLUS::Internals::Source::SQLite 
	# needs this module, so adding it.
	$self->install_modules( qw{
		DBIx::Simple
	} ) if ($self->perl_version() >= 5100);
	
	# Support for other databases.
	# DB_File had a "Permission denied" on 64-bit Win7 machine on the last test. 
	# Could be artifact of build environment... 
	$self->install_module(
		name  => 'DB_File',
		force => 1,
	); 
	$self->install_modules( qw{
		BerkeleyDB
		DBD::ODBC
	} );

	if (3 == $self->gcc_version()) {
		$self->install_dbd_mysql();
		
		my $install_location = $self->portable() ? q{perl\site\lib} : q{perl\vendor\lib};	
		my $mysql_url = $self->get_library_file('mysqllib');
		
		my $filelist = $self->install_binary(
			name       => 'db_libraries',
			url        => $self->_binary_url($mysql_url),
			install_to => $install_location
		);
		$self->insert_fragment( 'db_libraries', $filelist );
	}
	
	if (32 == $self->bits()) {
		$self->install_module(
			name  => 'DBD::Pg',
			force => 1,
		);
	}
	
	# JSON and local library installation
	$self->install_modules( qw{
		common::sense
		JSON::XS
		JSON
		local::lib
	} );	

	# Graphics module installation.
	$self->_remake_path(catdir($self->image_dir(), qw(cpan build))); 
	$self->install_module( name => 'Imager' );
	$self->install_module( name => 'GD' );
	
	return 1;
}

sub install_strawberry_modules_4 {
	my $self = shift;

	# This is due to RT #52408.
	return 1 if 64 == $self->bits();
	
	# Required for Net::SSLeay.
	local $ENV{'OPENSSL_PREFIX'} = catdir($self->image_dir, 'c');
	# This is required for IO::Socket::SSL.
	local $ENV{'SKIP_RNG_TEST'} = 1;

	# We have to tell the Makefile.PL where the OpenSSL 
	# libraries are by passing a parameter for Crypt::SSLeay.
	if ($self->portable()) {
		$self->install_distribution( 
			mod_name => 'Crypt::SSLeay',
			name     => 'DLAND/Crypt-SSLeay-0.57.tar.gz',
			makefilepl_param => [
				'--lib', $ENV{'OPENSSL_PREFIX'} ,
			],
		);
	} else {
		$self->install_distribution( 
			mod_name => 'Crypt::SSLeay',
			name     => 'DLAND/Crypt-SSLeay-0.57.tar.gz',
			makefilepl_param => [
				'INSTALLDIRS=vendor', '--lib', $ENV{'OPENSSL_PREFIX'} ,
			],
		);
	}
	
	$self->install_modules( qw{
		Net::SSLeay
		Digest::HMAC
		IO::Socket::SSL
		Net::SMTP::TLS
	});

	# The rest of the Net::SSH::Perl toolchain.
	$self->install_module(
		name  => 'Data::Random',
		force => 1, # Timing-dependent test.
	);
	$self->install_modules( qw{
		Math::GMP
		Data::Buffer
		Crypt::DSA
		Class::ErrorHandler
		Convert::ASN1
		Crypt::CBC
		Crypt::DES
		Crypt::DES_EDE3
	});
	# Has what appears to be a timing-dependent test.
	$self->install_module(
		name => 'Convert::PEM',
		force => 1,
	);
	$self->install_modules( qw{
		Crypt::DH
		Crypt::Blowfish
		Tie::EncryptedHash
		Class::Loader
		Crypt::Random
		Convert::ASCII::Armour
		Digest::MD2
		Sort::Versions
		Crypt::Primes
		Crypt::RSA
		Digest::BubbleBabble
		Crypt::IDEA
		String::CRC32
	});

	# Since	Net::SSH::Perl does not work under Win32 yet, it
	# is not being installed.  When it does, add it to the end
	# of the previous install_modules call.

	# Module::Signature toolchain.
	$self->install_modules( qw{
		Test::Manifest
		Crypt::Rijndael
		Crypt::CAST5_PP
		Crypt::RIPEMD160
		Crypt::Twofish
		Test::Exception
		Crypt::OpenPGP
		Algorithm::Diff
		Text::Diff
		Module::Signature
	});
	
	return 1;
}

sub install_strawberry_modules_5 {
	my $self = shift;

	# These are common requests.
	$self->install_modules( qw{
		File::Slurp
		Task::Weaken
	});
	# This is fixed by a distropref.
	$self->install_modules( qw{
		SOAP::Lite
	});

	# Clear things out.
	$self->_remake_path(catdir($self->image_dir(), qw(cpan build))); 

	return 1;
}

sub install_strawberry_files {
	my $self = shift;
	
	## Now let's copy individual files in.
	
	# Copy the module-version script in, and use the runperl.bat trick on it.
	$self->_copy(catfile($self->dist_dir(), 'module-version'), catdir($self->image_dir(), qw(perl bin)));
	$self->_copy(catfile($self->image_dir(), qw(perl bin runperl.bat)), catfile($self->image_dir(), qw(perl bin module-version.bat)));
	
	# Make sure it gets installed.
	$self->insert_fragment('module_version',
		File::List::Object->new()->add_files(
			catfile($self->image_dir(), qw(perl bin module-version)),
			catfile($self->image_dir(), qw(perl bin module-version.bat)),				
		),
	);

	if ($self->relocatable()) {
		# Copy the relocation information in.
		$self->patch_file('strawberry-merge-module.reloc.txt', $self->image_dir());
		
		# Make sure it gets installed.
		$self->insert_fragment('relocation_info',
			File::List::Object->new()->add_file(
				catfile($self->image_dir(), 'strawberry-merge-module.reloc.txt'),				
			),
		);
	}

	return 1;
}



#####################################################################
# Customisations to Windows assets

sub install_strawberry_extras {
	my $self = shift;

	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');

	# Links to the Strawberry Perl website.
	# Don't include this for non-Strawberry sub-classes
	if ( ref($self) eq 'Perl::Dist::Strawberry' ) {
		if (not $self->portable()) {
			$self->install_launcher(
				name => 'Check installed versions of modules',
				bin  => 'module-version',
			);
			$self->install_website(
				name       => 'Strawberry Perl Website',
				url        => $self->strawberry_url(),
				icon_file  => catfile($dist_dir, 'strawberry.ico')
			);
			$self->install_website(
				name       => 'Strawberry Perl Release Notes',
				url        => $self->strawberry_release_notes_url(),
				icon_file  => catfile($dist_dir, 'strawberry.ico')
			);
			# Link to IRC.
			$self->install_website(
				name       => 'Live Support',
				url        => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23win32',
				icon_file  => catfile($dist_dir, 'onion.ico')
			);
		}
		$self->patch_file( 'README.txt' => $self->image_dir(), { dist => $self } );
	}

	my $license_file_from = catfile($dist_dir, 'License.rtf');
	my $license_file_to = catfile($self->license_dir(), 'License.rtf');
	my $readme_file = catfile($self->image_dir(), 'README.txt');

	my $onion_ico_file = catfile($self->image_dir(), qw(win32 onion.ico));
	my $strawberry_ico_file = catfile($self->image_dir(), qw(win32 strawberry.ico));
	
	$self->_copy($license_file_from, $license_file_to);	
	if (not $self->portable()) {
		$self->add_to_fragment( 'Win32Extras',
			[ $license_file_to, $readme_file, $onion_ico_file, $strawberry_ico_file ] );
	}

	if ($self->relocatable()) {
		# Copy the relocation information in.
		$self->patch_file('strawberry-ui.reloc.txt', $self->image_dir());
		
		# Make sure it gets installed.
		$self->insert_fragment('relocation_ui_info',
			File::List::Object->new()->add_file(
				catfile($self->image_dir(), 'strawberry-ui.reloc.txt'),				
			),
		);
	}

	
	return 1;
}

sub strawberry_url {
	my $self = shift;
	my $path = $self->output_base_filename();

	# Strip off anything post-version
	unless ( $path =~ s/^(strawberry-perl-\d+(?:\.\d+)+).*$/$1/ ) {
		PDWiX->throw("Failed to generate the strawberry subpath");
	}

	return "http://strawberryperl.com/$path";
}

sub strawberry_release_notes_url {
	my $self = shift;
	my $path = $self->perl_version_human()
		. q{.} . $self->build_number()
		. ($self->beta_number() ? '.beta-' . $self->beta_number() : '');

	return "http://strawberryperl.com/release-notes/$path.html";
}

sub msi_relocation_commandline_files {
	my $self = shift;
	
	return('relocation_ui_info', catfile($self->image_dir(), 'strawberry-ui.reloc.txt'));
}

sub msm_relocation_commandline_files {
	my $self = shift;
	
	return('relocation_info', catfile($self->image_dir(), 'strawberry-merge-module.reloc.txt'));
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
Strawberry Perl Support page L<http://strawberryperl.com/support.html>.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.  

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
