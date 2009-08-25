package Perl::Dist::Bootstrap;

=pod

=head1 NAME

Perl::Dist::Bootstrap - A Perl distribution for building Perl distributions

=head1 DESCRIPTION

Bootstrap Perl is a subclass and variant of Strawberry Perl that installs
into a different directory (C:\bootperl) than Strawberry Perl so that
it won't be "in the way" when building Strawberry and other Perls.

It also comes prepackaged with a number of additional modules that are
dependencies of Perl::Dist and Perl::Dist::WiX.

=cut

use 5.006;
use strict;
use base                    qw( Perl::Dist::Strawberry );
use vars                    qw( $VERSION               );
use File::Spec::Functions   qw( catfile catdir         );
use File::ShareDir          qw();

BEGIN {
	$VERSION = '2.00';
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

		msi_directory_tree_additions => [qw (
			perl\site\lib\Class
			perl\site\lib\Data
			perl\site\lib\Devel
			perl\site\lib\Module
			perl\site\lib\Object
			perl\site\lib\Perl
			perl\site\lib\Perl\Dist
			perl\site\lib\Process
			perl\site\lib\Readonly
			perl\site\lib\Sub
			perl\site\lib\Tie
			perl\site\lib\auto\Class
			perl\site\lib\auto\Data
			perl\site\lib\auto\Devel
			perl\site\lib\auto\Module
			perl\site\lib\auto\Object
			perl\site\lib\auto\Perl
			perl\site\lib\auto\Perl\Dist
			perl\site\lib\auto\Process
			perl\site\lib\auto\Readonly
			perl\site\lib\auto\share\dist
			perl\site\lib\auto\share\dist\Perl-Dist
			perl\site\lib\auto\share\dist\Perl-Dist\default
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.10.0
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.10.0\lib
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.8.8
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.8.8\lib
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.8.9
			perl\site\lib\auto\share\dist\Perl-Dist\default\perl-5.8.9\lib
			perl\site\lib\auto\Sub
		)],

		# Build both msi and zip versions
		msi               => 1,
		zip               => 1,

		@_,
	);
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'bootstrap-perl-' . $_[0]->perl_version_human 
	. '.' . $_[0]->build_number
	. ($_[0]->beta_number ? '-beta-' . $_[0]->beta_number : '');
}






#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $path  = catdir( $share, 'bootstrap' );
	unless ( -d $path ) {
		PDWiX->throw("Directory $path does not exist");
	}

	# Prepend it to the default include path
	return [ $path,
		@{ $self->SUPER::patch_include_path },
	];
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	my $share = File::ShareDir::dist_dir('Perl-Dist-Strawberry');

	$self->install_distribution_from_file(
	    file => catfile($share, 'modules', 'Alien-WiX-0.300000.tar.gz'),
	);

	# Install Perl::Dist and everything required for Perl::Dist::WiX itself
	$self->install_modules( qw(
		File::Copy::Recursive
		Class::Inspector
		File::ShareDir
		File::PathList
		Error
		Cache::Cache
		LWP::UserAgent::WithCache
		Object::Tiny
		Process
		IO::Capture
		Test::LongString
		Module::ScanDeps
		Module::Install
		Tie::Slurp
		File::Slurp
		File::IgnoreReadonly
		Portable::Dist
		List::MoreUtils
		AppConfig
	) );

	$self->install_distribution( 
		name     => 'ABW/Template-Toolkit-2.21_02.tar.gz', 
		mod_name => 'Template',
		force    => $self->force(),
	);
	
	# Perl::Dist does not pass tests if offline.
	$self->install_module( name => 'Perl::Dist', force => !! $self->offline );

	# Data::UUID needs to have a temp directory set.
	{
		local $ENV{'TMPDIR'} = $self->image_dir;
		$self->install_module( name => 'Data::UUID', );
	}

	$self->install_modules( qw(
		Sub::Install
		Data::OptList
		Sub::Exporter
		Test::Output
		Devel::StackTrace
		Class::Data::Inheritable
		Exception::Class
		Test::UseAllModules
		Object::InsideOut
		B::Utils
		PadWalker
		Data::Dump::Streamer
		Readonly
		Readonly::XS
		Regexp::Common
		Pod::Readme
		Algorithm::C3
		Class::C3
		MRO::Compat
		Task::Weaken
		Scope::Guard
		Devel::GlobalDestruction
		Sub::Name
		Class::MOP
		Moose
		MooseX::AttributeHelpers
		File::List::Object
	) );
	$self->install_module(
		name => 'Perl::Dist::WiX',
		force => 1,
	);

#	$self->trace_line(0, "Loading extra Bootstrap packlists\n");

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

Copyright 2007 - 2009 Adam Kennedy.  Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
