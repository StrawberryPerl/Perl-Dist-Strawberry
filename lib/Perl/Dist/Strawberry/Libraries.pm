package Perl::Dist::Strawberry::Libraries;

=pod

=head1 NAME

Perl::Dist::Strawberry::Libraries - Library installation routines for Strawberry Perl

=head1 SYNOPSIS

	# This is used as an 'additive base" class for 
	# Perl::Dist::Strawberry and is not intended for use outside of 
	# Perl::Dist::Strawberry subclasses.

=head1 DESCRIPTION

Strawberry Perl is a binary distribution of Perl for the Windows operating
system.  It includes a bundled compiler and pre-installed modules that offer
the ability to install XS CPAN modules directly from CPAN.

The purpose of the Strawberry Perl series is to provide a practical Win32 Perl
environment for experienced Perl developers to experiment with and test the
installation of various CPAN modules under Win32 conditions, and to provide a
useful platform for doing real work.

=head1 INTERFACE

This class adds additional methods that provide installation
support for tools that are included in Strawberry Perl.

=cut

use 5.010;
use strict;
use warnings;
use File::Spec::Functions qw( catfile catdir );

our $VERSION = '2.02';
$VERSION =~ s/_//ms;


=pod

=head2 install_patch

  $dist->install_patch;

The C<install_patch> method can be used to install a copy of the Unix
patch program into the distribution.

Returns true or throws an exception on error.

=cut

sub install_patch {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'patch',
		url        => $self->_binary_url('patch-2.5.9-7-bin.zip'),
		install_to => {
			'bin/patch.exe' => 'c/bin/patch.exe',
		},
	);
	$self->{bin_patch} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'patch.exe',
	);
	unless ( -x $self->bin_patch() ) {
		die "Can't execute patch";
	}

	$self->insert_fragment('patch', $filelist);

	return 1;
}

=pod

=head2 bin_patch

  $dist->bin_patch;

The C<bin_patch> method returns the location of the patch.exe file 
installed by L</install_patch>.

=cut

sub bin_patch {
	return $_[0]->{bin_patch};
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
	my $ppmdir = catdir( $self->image_dir(), 'ppm', );
	if ( -d $ppmdir ) {
		die("PPM build directory '$ppmdir' already exists");
	}

	# Add the ppm directory to the build.
	$self->get_directory_tree()->add_root_directory(
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
		if ($self->portable()) {
			$self->install_distribution(
				mod_name         => 'PPM',
				name             => 'RKOBES/PPM-0.01_01.tar.gz',
				makefilepl_param => ['INSTALLDIRS=site'],
			);
		} else {
			$self->install_distribution(
				mod_name         => 'PPM',
				name             => 'RKOBES/PPM-0.01_01.tar.gz',
				makefilepl_param => ['INSTALLDIRS=vendor'],
			);
		}
	}

	unless ($self->portable()) {
		# Unfortunately, PPM.pm does not check in vendor/lib for ppm.xml
		my $xml_file_old = catfile($self->image_dir, qw(perl vendor lib ppm.xml));
		my $xml_file_new = catfile($self->image_dir, qw(perl site lib ppm.xml));
	
		$self->_copy($xml_file_old, $xml_file_new);

		# Add the readme file.
		$self->add_to_fragment('PPM', $filelist->files());

		# Add the ppm.xml file.
		$self->add_to_fragment('PPM', [ $xml_file_new ]);
	}
	
	# This is because the UWinnipeg repository is insane atm.
	$self->_run3("ppm.bat", qw(set repository --remove UWinnipeg));
	
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
	my $file = File::Spec->catfile( $self->image_dir(), @_ );
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

	given ($self->perl_version()) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible, supposedly.
			$filelist = $self->install_par(
			  name => 'DBD::mysql', 
			  url => $self->_binary_url('DBD-mysql-4.012-MSWin32-x86-multi-thread-5.10.0.par')
			);
		}
		
		when ('589') {
			$filelist = $self->install_par(
			  name => 'DBD::mysql', 
			  url => $self->_binary_url('DBD-mysql-4.012-MSWin32-x86-multi-thread-5.8.9.par')
			);
		}
		
		default {
			PDWiX->throw('Could not install DBD::mysql - invalid version of perl');
		}
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
	
	given ($self->perl_version()) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible.
			$filelist = $self->install_par(
			  name => 'DBD::Pg', 
			  url => $self->_binary_url('DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.10-5.10.0.par')
			);
		}
		
		when ('589') {
			$filelist = $self->install_par(
			  name => 'DBD::Pg', 
			  url => $self->_binary_url('DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.8-5.8.9.par')
			);
		}
		
		default {
			PDWiX->throw('Could not install DBD::Pg - invalid version of perl');
		}
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
	
	given ($self->perl_version()) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible.
			$self->install_par(
			  name => 'Math::Pari', 
			  url => $self->_binary_url('Math-Pari-2.010801-MSWin32-x86-multi-thread-5.10.0.par')
			);
		}
		
		when ('589') {
			$self->install_par(
			  name => 'Math::Pari', 
			  url => $self->_binary_url('Math-Pari-2.010801-MSWin32-x86-multi-thread-5.8.9.par')
			);
		}
		
		default {
			PDWiX->throw('Could not install Math::Pari - invalid version of perl');
		}
	}

	return 1;
} ## end sub install_pari

=pod

=head2 install_zlib

  $dist->install_zlib

The C<install_zlib> method installs the B<GNU zlib> compression library
into the distribution, and is typically installed during "C toolchain"
build phase.

It provides the appropriate arguments to a C<install_library> call that
will extract the standard zlib win32 package, and generate the additional
files that Perl needs.

Returns true or throws an exception on error.

=cut

sub install_zlib {
	my $self = shift;

	my $filelist = $self->install_binary(
		name      => 'zlib',
		install_to => q{.},
		url       => $self->_binary_url('libzlib-1.2.3-bin_20090819.zip'),
	);

	$self->insert_fragment( 'zlib', $filelist );

	return 1;
} ## end sub install_zlib

=pod

=head2 install_libiconv

  $dist->install_libiconv

The C<install_libiconv> method installs the C<GNU libiconv> library,
which is used for various character encoding tasks, and is needed for
other libraries such as C<libxml>.

Returns true or throws an exception on error.

=cut

sub install_libiconv {
	my $self     = shift;

	my $filelist = $self->install_binary( 
		name => 'libiconv', 
		install_to => q{.},
		url  => $self->_binary_url('libiconv-1.9.2-1-bin_20090831.zip'),
	);

	$self->insert_fragment( 'libiconv', $filelist );

	return 1;
} ## end sub install_libiconv


=pod

=head2 install_libxml

  $dist->install_libxml

The C<install_libxml> method installs the C<Gnome libxml> library,
which is a fast, reliable, XML parsing library, and the new standard
library for XML parsing.

Returns true or throws an exception on error.

=cut

sub install_libxml {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libxml2',
		install_to => q{.},
		url        => $self->_binary_url('libxml2-2.7.3-bin_20090819.zip'),
	);

	$self->insert_fragment( 'libxml', $filelist );

	return 1;
} ## end sub install_libxml

=pod

=head2 install_expat

  $dist->install_expat

The C<install_expat> method installs the C<Expat> XML library,
which was the first popular C XML parser. Many Perl XML libraries
are based on Expat.

Returns true or throws an exception on error.

=cut

sub install_expat {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libexpat',
		install_to => q{.},
		url        => $self->_binary_url('libexpat-2.0.1-vanilla.zip'),
	);

	$self->insert_fragment( 'libexpat', $filelist );

	return 1;
} ## end sub install_expat

=pod

=head2 install_gmp

  $dist->install_gmp

The C<install_gmp> method installs the C<GNU Multiple Precision Arithmetic
Library>, which is used for fast and robust bignum support.

Returns true or throws an exception on error.

=cut

sub install_gmp {
	my $self = shift;

	# Comes as a single prepackaged vanilla-specific zip file
	my $filelist = $self->install_binary( 
		name => 'gmp', 
		url  => $self->_binary_url('gmp-4.2.1-vanilla.zip'),
	);

	$self->insert_fragment( 'gmp', $filelist );

	return 1;
}

sub install_libxslt {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libxslt',
		install_to => q{.},
		url        => $self->_binary_url('libxslt-1.1.24-bin_20090819.zip'),
	);

	$self->insert_fragment( 'libxslt', $filelist );

	return 1;

}



sub install_libjpeg {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libjpeg',
		url        => $self->_binary_url('libjpeg-6b-4-bin_20090821.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libjpeg', $filelist);

	return 1;
}


sub install_libgif {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libgif',
		url        => $self->_binary_url('libgif-4.1.4-1-bin_20090821.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libgif', $filelist);

	return 1;
}


sub install_libpng {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libpng',
		url        => $self->_binary_url('libpng-1.2.38-bin_20090828.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libpng', $filelist);


	return 1;
}


sub install_libtiff {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libtiff',
		url        => $self->_binary_url('libtiff-3.8.2-1-bin_20090821.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libtiff', $filelist);


	return 1;
}


sub install_libgd {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libgd',
		url        => $self->_binary_url('libgd-2.0.33-1-bin_20090828.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libgd', $filelist);


	return 1;
}

sub install_libfreetype {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libfreetype',
		url        => $self->_binary_url('libfreetype-2.3.5-1-bin_20090828.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libfreetype', $filelist);

	return 1;
}

sub install_libopenssl {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libopenssl',
		url        => $self->_binary_url('libopenssl-0.9.8k-bin_20090820.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libopenssl', $filelist);


	return 1;
}

sub install_libpostgresql {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libpostgresql',
		url        => $self->_binary_url('libpostgresql-8.4.0-bin_20090821.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libpostgresql', $filelist);

	return 1;
}

=pod

=head2 install_libdb

  $dist->install_libdb;

The C<install_libdb> method can be used to install a copy of the 
Berkeley DB library.

Returns true or throws an exception on error.

=cut


sub install_libdb {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libdb',
		url        => $self->_binary_url('libdb-4.8.24-bin_20091019.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libdb', $filelist);

	return 1;
}

sub install_libgdbm {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libgdbm',
		url        => $self->_binary_url('libgdbm-1.8.3_20091105.zip'),
		install_to => q{.}
	);
	$self->insert_fragment('libgdbm', $filelist);

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

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.  

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
