package Perl::Dist::Strawberry;

use 5.005;
use strict;
use base 'Perl::Dist';
use Perl::Dist::Util::Toolchain ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.51';
}





#####################################################################
# Configuration

sub app_name             { 'Strawberry Perl'               }
sub app_ver_name         { 'Strawberry Perl 5.10.0 Beta 1' }
sub app_publisher        { 'Vanilla Perl Project'          }
sub app_publisher_url    { 'http://vanillaperl.org/'       }
sub app_id               { 'strawberryperl'                }
sub output_base_filename { 'strawberry-perl-5.10.0-beta-1' }

# Apply some default paths
sub new {
	shift->SUPER::new(
		image_dir => 'C:\\strawberry',
		temp_dir  => 'C:\\tmp\\sp',
		@_,
	);
}





#####################################################################
# Installation Script

# Vanilla never has any additional libraries.
# Just install the C toolchain and Perl core.
sub run {
	my $self = shift;
	my $t    = undef;

	# Install the C toolchain
	my $t = time;
	$self->install_c_toolchain;
	$self->trace("Completed install_c_toolchain in " . (time - $t) . " seconds\n");

	# Install the additional C libraries
	$t = time;
	$self->install_c_libraries;
	$self->trace("Completed install_c_libraries in " . (time - $t) . " seconds\n");

	# Install the Perl 5.10.0 binary
	$t = time;
	$self->install_perl_5100;
	$self->trace("Complete install_perl_5100 in " . (time - $t) . " seconds\n");

	# Install modules
	$t = time;
	$self->install_perl_modules;
	$self->trace("Complete install_perl_modules in " . (time - $t) . " seconds\n");

	# Write out the exe
	$t = time;
	$self->remove_waste;
	my $exe = $self->write_exe;
	$self->trace("Completed write_exe in " . (time - $t) . " seconds\n");

	# Finished
	$self->trace("Distribution exe file created as $exe\n");
	return 1;
}

# Resolve the distribution list at startup time
my $toolchain5100 = Perl::Dist::Util::Toolchain->new( qw{
	Compress::Raw::Bzip2
	IO::Compress::Bzip2
	Compress::Bzip2
	Win32API::Registry
	Win32::TieRegistry
	File::HomeDir
	File::Which
	Archive::Zip
	YAML
	Digest::SHA1
	Term::ReadLine::Perl
} );

# Get the regular Perl to generate the list.
# Run it in a separate process so we don't hold
# any permanent CPAN.pm locks (for now).
$toolchain5100->delegate;
if ( $toolchain5100->{errstr} ) {
	die "Failed to generate toolchain distributions";
}

sub install_perl_5100_toolchain {
	my $self = shift;
	$self->SUPER::install_perl_5100_toolchain(@_);

	foreach my $dist ( @{$toolchain5100->{dists}} ) {
		my $force             = 0;
		my $automated_testing = 0;
		if ( $dist =~ /Scalar-List-Util/ ) {
			# Does something weird with tainting
			$force = 1;
		}
		if ( $dist =~ /File-Temp/ ) {
			# Lock tests break
			$force = 1;
		}
		if ( $dist =~ /Term-ReadLine-Perl/ ) {
			# Does evil things when testing, and
			# so testing cannot be automated.
			$automated_testing = 1;
		}
		$self->install_distribution(
			name              => $dist,
			force             => $force,
			automated_testing => $automated_testing,
		);
	}

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Strawberry CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;

	# Install the companion Perl modules for the
	# various libs we installed.
	$self->install_module(
		name => 'XML::LibXML',
	);

	# Install the basics
	$self->install_module(
		name => 'Params::Util',
	);
	$self->install_module(
		name => 'Bundle::LWP',
	);

	# Install various developer tools
	$self->install_module(
		name => 'Bundle::CPAN',
	);
	$self->install_module(
		name => 'pler',
	);
	$self->install_module(
		name => 'pip',
	);
	$self->install_module(
		name => 'PAR::Dist',
	);
	$self->install_module(
		name => 'DBI',
	);

	# Install SQLite
	$self->install_distribution(
		name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
		force => 1,
	);

	# Now we have SQLite, install the CPAN::SQLite upgrade
	$self->install_module(
		name => 'CPAN::SQLite',
	);

	return 1;
}

1;

__END__

=head1 NAME

Perl::Dist::Strawberry - Strawberry Perl for win32

=head1 VERSION

This is 0.30, corresponding to Strawberry Perl 5.8.8 Beta 1

=head1 DESCRIPTION

I<Strawberry Perl is currently an alpha release and is not recommended 
for production purposes.>

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

Perl 5.8.8

=item *

Mingw GCC C/C++ compiler

=item *

Dmake "make" tool

=item *

L<ExtUtils::CBuilder> and L<ExtUtils::ParseXS>

=item *

L<Bundle::CPAN> (including Perl modules that largely eliminate the need for
external helper programs like C<gzip> and C<tar>)

=item *

L<Bundle::LWP> (providing more reliable http CPAN repository support)

=item *

Additional Perl modules that enhance the stability of core Perl for the
Win32 platform

=back

The Perl::Dist::Strawberry distribution on CPAN contains programs and
instructions for downloading component sources and assembling them into the
executable installer for Strawberry Perl.  It B<does not> include the resulting
Strawberry Perl installer itself.  

See L</"DOWNLOADING THE INSTALLER"> for instructions on where to download and
how to install Strawberry Perl.  

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

=head1 DOWNLOADING THE INSTALLER

Strawberry Perl is available from L<http://vanillaperl.com/>.

=head1 CONFIGURATION

At present, Strawberry Perl must be installed in C:\strawberry-perl.  The
executable installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\strawberry-perl\perl\bin  
        - C:\strawberry-perl\dmake\bin
        - C:\strawberry-perl\mingw
        - C:\strawberry-perl\mingw\bin

    * adds directories to LIB
        - C:\strawberry-perl\mingw\lib
        - C:\strawberry-perl\perl\bin

    * adds directories to INCLUDE 
        - C:\strawberry-perl\mingw\include 
        - C:\strawberry-perl\perl\lib\CORE 
        - C:\strawberry-perl\perl\lib\encode

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl.

Users installing Strawberry Perl without the installer will need to
change their environment variables manually.

The first time that the "cpan" program is run, users will be prompted for
configuration settings.  With the defaults provided in Strawberry Perl, users
may answer "no" to manual configuration and the installation should still work.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 VERSION HISTORY AND ROADMAP

Perl::Dist::Strawberry version numbers map to Strawberry Perl release
versions as follows:

 Pre-release series (0.x.y)
   0.0.1 -- Strawberry Perl 5.8.8 Alpha 1 (July 9, 2006)
   0.1.2 -- Strawberry Perl 5.8.8 Alpha 2 (August 27, 2006)
   0.1.y -- Alpha series
   0.3.y -- Beta series
   0.5.y -- Release candidate series

 Perl 5.8 series (1.x.y) -- 'x' will be odd for test releases 
 
 Perl 5.10 series (2.x.y) -- 'x' will be odd for test releases 

Strawberry Perl is targeting release 1.0.0 to correspond to the next 
maintenance release of Perl (5.8.9), which should include most of the 
"changes from core Perl" listed above.  Strawberry Perl will be declared
Beta when the pre-release candidate for Perl 5.8.9 is available.

=head1 CONTACTS AND BUGS REPORTING

Currently, Strawberry Perl discussion is centered at win32.perl.org.  New 
venues for discussion may be listed there.

Please report bugs or feature requests using the CPAN Request Tracker.
Bugs can be sent by email to C<<< bug-Perl-Dist-Strawberry@rt.cpan.org >>> or
submitted using the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Perl-Dist-Strawberry>

=head1 LICENSE AND COPYRIGHT

Strawberry Perl is open source and may be licensed under the same terms as
Perl.  Open source software included with Strawberry Perl installations are
governed by their respective licenses.  See LICENSE.txt for details.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
