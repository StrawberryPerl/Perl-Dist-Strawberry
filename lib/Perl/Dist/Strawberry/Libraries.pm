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
use Readonly;

our $VERSION = '2.10_10';
$VERSION =~ s/_//ms;

Readonly my %LIBRARIES_S => {
	'32bit-gcc3' => { # The 32bit-gcc4 libraries can be used, but not par files.
		'patch'         => '32bit-gcc3/patch-2.5.9-7-bin_20100110_20100303.zip',
		'mysql589'      => 'DBD-mysql-4.012-MSWin32-x86-multi-thread-5.8.9.par',
		'mysql5100'     => 'DBD-mysql-4.012-MSWin32-x86-multi-thread-5.10.0.par',
		'mysql5101'     => 'DBD-mysql-4.012-MSWin32-x86-multi-thread-5.10.0.par',
		'mysql5115'     => undef,
		'mysql5120'     => undef,
		'mysql5121'     => undef,
		'mysqllib'      => '32bit-gcc3/MySQLLibraries-20100121.zip',
		'pari589'       => 'Math-Pari-2.010801-MSWin32-x86-multi-thread-5.8.9.par',
		'pari5100'      => '32bit-gcc3/Math-Pari-2.01080603-MSWin32-x86-multi-thread-5.10.1.par',
		'pari5101'      => '32bit-gcc3/Math-Pari-2.01080603-MSWin32-x86-multi-thread-5.10.1.par',
		'pari5115'      => '32bit-gcc3/Math-Pari-2.01080603-MSWin32-x86-multi-thread-5.11.5.par',
		'pari5120'      => undef,
		'pari5121'      => undef,
		'zlib'          => '32bit-gcc4/zlib-1.2.3-bin_20091126.zip',
		'libiconv'      => '32bit-gcc4/libiconv-1.13.1-bin_20091126.zip',
		'libxml2'       => '32bit-gcc4/libxml2-2.7.3-bin_20091126.zip',
		'libexpat'      => '32bit-gcc4/expat-2.0.1-bin_20091126.zip',
		'gmp'           => '32bit-gcc4/gmp-5.0.1-419f6a4cc606-bin_20100306.zip',
		'libxslt'       => '32bit-gcc4/libxslt-1.1.26-bin_20091126.zip',
		'libjpeg'       => '32bit-gcc4/jpeg-6b-gnuwin32-bin_20091126.zip',
		'libgif'        => '32bit-gcc4/giflib-4.1.6-bin_20091126.zip',
		'libpng'        => '32bit-gcc4/libpng-1.2.40-bin_20091126.zip',
		'libtiff'       => '32bit-gcc4/tiff-3.9.1-bin_20091126.zip',
		'libgd'         => '32bit-gcc4/gd-2.0.35-bin_20091126.zip',
		'libfreetype'   => '32bit-gcc4/freetype-2.3.11-bin_20091126.zip',
		'libopenssl'    => '32bit-gcc4/openssl-0.9.8l-bin_20091126.zip',
		'libpostgresql' => '32bit-gcc4/postgresql-8.4.1-bin_20091126.zip',
		'libdb'         => '32bit-gcc4/db-4.8.24-bin_20091126.zip',
		'libgdbm'       => '32bit-gcc4/gdbm-1.8.3-bin_20100112.zip',
		'libxpm'        => '32bit-gcc4/libXpm-3.5.8-bin_20091126.zip',
		'libxz'         => '32bit-gcc4/liblzma-xz-4.999.9beta-bin_20100308.zip',
		'mpc'           => '32bit-gcc4/mpc-0.8.1-bin_20100306.zip',
		'mpfr'          => '32bit-gcc4/mpfr-2.4.2-bin_20100306.zip',
		'libmysql'      => '32bit-gcc4/mysql-5.1.44-bin_20100304.zip',
		'freeglut'      => '32bit-gcc4/freeglut-2.6.0-bin_20100213.zip',
		'libssh2'       => '32bit-gcc4/libssh2-1.2.5-bin_20100520.zip',
	},
	'32bit-gcc4' => {
		'patch'         => '32bit-gcc4/patch-2.5.9-7-bin_20100110_20100303.zip',
		'mysql589'      => undef,
		'mysql5100'     => undef,
		'mysql5101'     => undef,
		'mysql5115'     => undef,
		'mysql5120'     => undef,
		'mysql5121'     => undef,
		'mysqllib'      => '32bit-gcc4/mysql-5.1.44-bin_20100304.zip',
		'pari589'       => undef,
		'pari5100'      => undef,
		'pari5101'      => undef,
		'pari5115'      => '32bit-gcc4/Math-Pari-2.01080604-MSWin32-x86-multi-thread-5.11.5.par',
		'pari5120'      => '32bit-gcc4/Math-Pari-2.01080604-MSWin32-x86-multi-thread-5.12.0.par',
		'pari5121'      => '32bit-gcc4/Math-Pari-2.01080604-MSWin32-x86-multi-thread-5.12.0.par',
		'zlib'          => '32bit-gcc4/zlib-1.2.3-bin_20091126.zip',
		'libiconv'      => '32bit-gcc4/libiconv-1.13.1-bin_20091126.zip',
		'libxml2'       => '32bit-gcc4/libxml2-2.7.3-bin_20091126.zip',
		'libexpat'      => '32bit-gcc4/expat-2.0.1-bin_20091126.zip',
		'gmp'           => '32bit-gcc4/gmp-5.0.1-419f6a4cc606-bin_20100306.zip',
		'libxslt'       => '32bit-gcc4/libxslt-1.1.26-bin_20091126.zip',
		'libjpeg'       => '32bit-gcc4/jpeg-6b-gnuwin32-bin_20091126.zip',
		'libgif'        => '32bit-gcc4/giflib-4.1.6-bin_20091126.zip',
		'libpng'        => '32bit-gcc4/libpng-1.2.40-bin_20091126.zip',
		'libtiff'       => '32bit-gcc4/tiff-3.9.1-bin_20091126.zip',
		'libgd'         => '32bit-gcc4/gd-2.0.35-bin_20091126.zip',
		'libfreetype'   => '32bit-gcc4/freetype-2.3.11-bin_20091126.zip',
		'libopenssl'    => '32bit-gcc4/openssl-0.9.8l-bin_20091126.zip',
		'libpostgresql' => '32bit-gcc4/postgresql-8.4.1-bin_20091126.zip',
		'libdb'         => '32bit-gcc4/db-4.8.24-bin_20091126.zip',
		'libgdbm'       => '32bit-gcc4/gdbm-1.8.3-bin_20100112.zip',
		'libxpm'        => '32bit-gcc4/libXpm-3.5.8-bin_20091126.zip',
		'libxz'         => '32bit-gcc4/liblzma-xz-4.999.9beta-bin_20100308.zip',
		'mpc'           => '32bit-gcc4/mpc-0.8.1-bin_20100306.zip',
		'mpfr'          => '32bit-gcc4/mpfr-2.4.2-bin_20100306.zip',
		'libmysql'      => '32bit-gcc4/mysql-5.1.44-bin_20100304.zip',
		'freeglut'      => '32bit-gcc4/freeglut-2.6.0-bin_20100213.zip',
		'libssh2'       => '32bit-gcc4/libssh2-1.2.5-bin_20100520.zip',
	},
	'64bit-gcc4' => {
		'patch'         => '64bit-gcc4/patch-2.5.9-7-bin_20100110_20100303.zip',
		'mysql589'      => undef,
		'mysql5100'     => undef,
		'mysql5101'     => undef,
		'mysql5115'     => undef,
		'mysql5120'     => undef,
		'mysql5121'     => undef,
		'mysqllib'      => undef,
		'pari589'       => undef,
		'pari5100'      => undef,
		'pari5101'      => undef,
		'pari5115'      => undef,
		'pari5120'      => undef,
		'pari5121'      => undef,
		'zlib'          => '64bit-gcc4/zlib-1.2.3-bin_20100110.zip',
		'libiconv'      => '64bit-gcc4/libiconv-1.13.1-bin_20100110.zip',
		'libxml2'       => '64bit-gcc4/libxml2-2.7.3-bin_20100110.zip',
		'libexpat'      => '64bit-gcc4/expat-2.0.1-bin_20100110.zip',
		'gmp'           => '64bit-gcc4/gmp-5.0.1-419f6a4cc606-bin_20100306.zip',
		'libxslt'       => '64bit-gcc4/libxslt-1.1.26-bin_20100111.zip',
		'libjpeg'       => '64bit-gcc4/jpeg-6b-gnuwin32-bin_20100110.zip',
		'libgif'        => '64bit-gcc4/giflib-4.1.6-bin_20100110.zip',
		'libpng'        => '64bit-gcc4/libpng-1.2.40-bin_20100110.zip',
		'libtiff'       => '64bit-gcc4/tiff-3.9.1-bin_20100110.zip',
		'libgd'         => '64bit-gcc4/gd-2.0.35-bin_20100110.zip',
		'libfreetype'   => '64bit-gcc4/freetype-2.3.11-bin_20100110.zip',
		'libopenssl'    => '64bit-gcc4/openssl-1.0.0-beta4-bin_20100110.zip',
		'libpostgresql' => '64bit-gcc4/postgresql-8.4.1-bin_20100110.zip',
		'libdb'         => '64bit-gcc4/db-4.8.24-bin_20100110.zip',
		'libgdbm'       => '64bit-gcc4/gdbm-1.8.3-bin_20100112.zip',
		'libxpm'        => '64bit-gcc4/libXpm-3.5.8-bin_20100110.zip',
		'libxz'         => '64bit-gcc4/liblzma-xz-4.999.9beta-bin_20100308.zip',
		'mpc'           => '64bit-gcc4/mpc-0.8.1-bin_20100306.zip',
		'mpfr'          => '64bit-gcc4/mpfr-2.4.2-bin_20100306.zip',
		'libmysql'      => '64bit-gcc4/mysql-5.1.44-bin_20100304.zip',
		'freeglut'      => '64bit-gcc4/freeglut-2.6.0-bin_20100213.zip',
		'libssh2'       => '64bit-gcc4/libssh2-1.2.5-bin_20100520.zip',
	},
};

sub get_library_file {
	my $self = shift;
	my $package = shift;

	my $toolchain = $self->library_directory();

	$self->trace_line( 3, "Searching for $package in $toolchain\n" );

	if ( not exists $LIBRARIES_S{$toolchain} ) {
		PDWiX->throw('Can only build 32 or 64-bit versions of perl');
	}

	if ( not exists $LIBRARIES_S{$toolchain}{$package} ) {
		PDWiX->throw(
			'get_library_file was called on a package that was not defined.'
		);
	}

	my $package_file = $LIBRARIES_S{$toolchain}{$package};
	if (defined $package_file) {
		$self->trace_line( 3, "Pachage $package is in $package_file\n" );
	} else {
		$self->trace_line( 1, "Pachage $package does not exist for this toolchain.\n" );
	}
	
	return $package_file;
}

sub get_library_file_versioned {
	my $self = shift;
	my $package = shift;

	my $toolchain = $self->library_directory();
	my $package_v = $package . $self->perl_version();
	
	$self->trace_line( 3, "Searching for $package in $toolchain\n" );

	if ( not exists $LIBRARIES_S{$toolchain} ) {
		PDWiX->throw('Can only build 32 or 64-bit versions of perl');
	}

	if ( not exists $LIBRARIES_S{$toolchain}{$package_v} ) {
		PDWiX->throw(
			'get_library_file was called on a package that was not defined.'
		);
	}

	my $package_file = $LIBRARIES_S{$toolchain}{$package_v};
	if (defined $package_file) {
		$self->trace_line( 3, "Pachage $package is in $package_file\n" );
	} else {
		$self->trace_line( 1, "Pachage $package does not exist for this toolchain.\n" );
	}
	
	return $package_file;
}



=pod

=head2 install_patch

  $dist->install_patch();

The C<install_patch> method can be used to install a copy of the Unix
patch program into the distribution.

Returns true or throws an exception on error.

=cut

sub install_patch {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'patch',
		install_to => q{.},
		url        => $self->_binary_url($self->get_library_file('patch')),
	);
	$self->{bin_patch} = $self->file(qw(c bin patch.exe));

	unless ( -x $self->bin_patch() ) {
		die "Can't execute patch";
	}

	$self->insert_fragment('patch', $filelist);

	return 1;
}

=pod

=head2 bin_patch

  $dist->bin_patch();

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
	my $ppmdir = $self->dir('ppm');
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
		my $share = $self->dist_dir();
		if ($self->portable() && (12 < $self->perl_major_version()) ) {
			$self->install_distribution_from_file(
				mod_name      => 'PPM',
				file          => catfile($share, 'modules', 'PPM-0.01_03.tar.gz'),
				makefilepl_param => ['INSTALLDIRS=site'],
			);		
		} else {
			$self->install_distribution_from_file(
				mod_name      => 'PPM',
				file          => catfile($share, 'modules', 'PPM-0.01_03.tar.gz'),
				makefilepl_param => ['INSTALLDIRS=vendor'],
			);		
		}
	}

	unless ($self->portable()) {
		# Add the readme file.
		$self->add_to_fragment('PPM', $filelist->files());
	}
	
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
	my $file = $self->file(@_);
	unless ( -f $file ) {
		die "Program $file does not exist";
	}

	my $manifest_file;
	open $manifest_file, '>', "$file.manifest" or die "open: $!";
	print { $manifest_file } $manifest         or die "print: $!";
	close $manifest_file                       or die "close: $!";

	return 1;	
}



=pod

=head2 install_pari

  $dist->install_pari()

The C<install_pari> method install (via a PAR package) libpari and the
L<Math::Pari> module into the distribution.

This method should only be called at during the install_modules phase.

=cut

sub install_pari {
	my $self = shift;
	
	my $url = $self->get_library_file_versioned('pari');
	
	my $filelist = $self->install_par(
	  name => 'Math::Pari', 
	  url => $self->_binary_url($url)
	);

	return 1;
} ## end sub install_pari



=pod

=head2 install_librarypack

  $dist->install_librarypack('zlib')

The C<install_librarypack> method installs a library defined in 
C<%Perl::Dist::Strawberry::LIBRARIES_S>.

=cut

sub install_librarypack {
	my $self = shift;
	my $library = shift;
	
	my $filelist = $self->install_binary(
		name       => $library,
		url        => $self->_binary_url($self->get_library_file($library)),
		install_to => q{.}
	);
	$self->insert_fragment($library, $filelist);


	return 1;
}



=pod

=head2 install_librarypacks

  $dist->install_librarypacks(qw{zlib libiconv})

The C<install_librarypacks> method installs a list of libraries defined 
in C<%Perl::Dist::Strawberry::LIBRARIES_S>.

=cut

sub install_librarypacks {
	my $self = shift;

	foreach my $library (@_) {
		$self->install_librarypack( $library );
	}

	return $1;
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
