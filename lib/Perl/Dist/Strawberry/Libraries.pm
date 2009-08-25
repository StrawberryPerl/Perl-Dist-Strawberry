package Perl::Dist::Strawberry::Libraries;

=pod

=head1 NAME

Perl::Dist::Strawberry - Library installation routines for Strawberry Perl

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

This class  L<Perl::Dist::WiX> methods,
Strawberry Perl adds some additional methods that provide installation
support for miscellaneous tools that have not yet been promoted to the
core.

=cut

use 5.010;
use strict;
use warnings;
use File::Spec::Functions       qw( catfile catdir  );
#use URI::file                   qw();
#use Perl::Dist::Machine         qw();
#use Perl::Dist::Util::Toolchain qw();
#use File::ShareDir              qw();

our $VERSION = '2.00_01';
$VERSION = eval { return $VERSION };


=pod

=head2 install_libdb

  $dist->install_libdb;

The C<install_libdb> method can be used to install a copy of the 
Berkeley DB library.

Returns true or throws an exception on error.

=cut

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
	my $ppmdir = catdir( $self->image_dir, 'ppm', );
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

	given ($self->perl_version) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible.
			$filelist = $self->install_par(
			  name => 'DBD_mysql', 
			  url => $self->binary_url('DBD-mysql-4.012-MSWin32-x86-multi-thread-5.10.0.par')
			);
			$self->insert_fragment( 'DBD_mysql', $filelist->files );
		}
		
		when ('589') {
			$filelist = $self->install_par(
			  name => 'DBD_mysql', 
			  url => $self->binary_url('DBD-mysql-4.012-MSWin32-x86-multi-thread-5.8.9.par')
			);
			$self->insert_fragment( 'DBD_mysql', $filelist->files );
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
	
	given ($self->perl_version) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible.
			$filelist = $self->install_par(
			  name => 'DBD_Pg', 
			  url => $self->binary_url('DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.10-5.10.0.par')
			);
			$self->insert_fragment( 'DBD_Pg', $filelist->files );
		}
		
		when ('589') {
			$filelist = $self->install_par(
			  name => 'DBD_Pg', 
			  url => $self->binary_url('DBD-Pg-2.13.1-MSWin32-x86-multi-thread-5.8-5.8.9.par')
			);
			$self->insert_fragment( 'DBD_Pg', $filelist->files );
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
	
	given ($self->perl_version) {
		when (m{\A510}) { # 5.10.0 and 5.10.1 are binary-compatible.
			$filelist = $self->install_par(
			  name => 'pari', 
			  url => $self->binary_url('Math-Pari-2.010801-MSWin32-x86-multi-thread-5.10.0.par')
			);
			$self->insert_fragment( 'pari', $filelist->files );
		}
		
		when ('589') {
			$filelist = $self->install_par(
			  name => 'pari', 
			  url => $self->binary_url('Math-Pari-2.010801-MSWin32-x86-multi-thread-5.8.9.par')
			);
			$self->insert_fragment( 'pari', $filelist->files );
		}
		
		default {
			PDWiX->throw('Could not install Math::Pari - invalid version of perl');
		}
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
