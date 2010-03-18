#!perl

use 5.008009;
use strict;
use warnings;
use File::Slurp qw(read_file write_file);
use Getopt::Long qw(GetOptions);
use English qw( -no_match_vars );
use File::Spec::Functions qw(splitpath);
use Carp qw(carp);
use Win32::File::Object qw();

sub usage;
sub version;
sub relocate_file;

our $STRING_VERSION = our $VERSION = '1.000';
$VERSION  =~ s/_//;

my @files;
my $quiet = 0;
my $new_location = undef;

GetOptions('help|?'     => sub { pod2usage(-exitstatus => 0, -verbose => 0); }, 
		   'man'        => sub { pod2usage(-exitstatus => 0, -verbose => 2); },
		   'usage'      => sub { usage(); },
		   'version'    => sub { version(); exit(1); },
		   'file=s'     => \@files,
		   'location=s' => \$new_location,
		   'quiet'      => \$quiet,
		  ) or pod2usage(-verbose => 2);

if (0 == scalar @files) {
	usage() if not $quiet;
	exit(1);
}

if (not defined $new_location) {
	require Cwd;
	$new_location = Cwd::cwd();
	$new_location =~ s{/}{\\}g;
}

if ("\\" ne substr $new_location, -1, 1) {
	$new_location .= "\\";
}

if ($new_location =~ m/ /) {
	carp "New location cannot have spaces in it" if not $quiet;
	exit(1);
}

if ($OSNAME eq 'MSWin32') {
	my $long_name = Win32::GetLongPathName($new_location);
	if ((defined $long_name) and ($long_name =~ m/ /)) {
		carp "New location cannot have spaces in it" if not $quiet;
		exit(1);
	}
}

my @lines;
my $ok = 1;
foreach my $file (@files) {
	@lines = read_file($file);
	my $old_location = shift @lines;
	chomp $old_location;
	
	print "\nRelocating files from $old_location to $new_location\n" if not $quiet;
	
  LINE:
	foreach my $line (@lines) {
		next LINE if $line eq "\n";
		$ok = relocate_file($old_location, $new_location, $quiet, split /:/, $line);
		if (not $ok) {
			carp "Could not relocate $file.\n" if not $quiet;
			exit(1);
		}
	}
	unshift @lines, "$new_location\n";
	write_file($file, @lines); 
}

print "Relocation completed\n" if not $quiet;
exit(0);



sub get_replacements_backslash {
	my ($old_location, $new_location) = @_;

	$old_location =~ s{/}{\\}gmx;
	$new_location =~ s{/}{\\}gmx;

	return ("\Q$old_location\E", $new_location);	
}



sub get_replacements_doublebackslash {
	my ($old_location, $new_location) = @_;

	$old_location =~ s{\\}{/}gmx;
	$new_location =~ s{\\}{/}gmx;
	$old_location =~ s{/}{\\\\}gmx;
	$new_location =~ s{/}{\\\\}gmx;

	return ("\Q$old_location\E", $new_location);	
}



sub get_replacements_slash {
	my ($old_location, $new_location) = @_;

	$old_location =~ s{\\}{/}gmx;
	$new_location =~ s{\\}{/}gmx;

	return ("\Q$old_location\E", $new_location);	
}



sub get_replacements_url {
	my ($old_location, $new_location) = @_;

	$old_location =~ s{\\}{/}gmx;
	$new_location =~ s{\\}{/}gmx;

	return ("file:///$old_location", "file:///$new_location");
}



sub relocate_file {
	my ($old_location, $new_location, $quiet, $file, $type) = @_;
	
	chomp $type;
	print "Relocating file $file using $type relocation\n" if not $quiet;

	my $contents = read_file($file);

	my ($old, $new) = 
		('backslash'       eq $type) ? get_replacements_backslash($old_location, $new_location)
	  : ('slash'           eq $type) ? get_replacements_slash($old_location, $new_location)
	  : ('doublebackslash' eq $type) ? get_replacements_doublebackslash($old_location, $new_location)
	  : ('url'             eq $type) ? get_replacements_url($old_location, $new_location)
	  : ();

	if (defined $old) {
		$contents =~ s{$old}{$new}g;
	} else {
		carp "Can't do a $type relocation\n" if not $quiet;
		exit(1);
	}

	if ( not -f $file ) {
		carp "Can't relocate a file $file that isn't a file\n" if not $quiet;
		exit(1);
	}
	
	my $ok;
	if ( not -w $file ) {
		# Make sure it isn't readonly
		my $fileobj = Win32::File::Object->new( $file, 1 );
		my $readonly = $fileobj->readonly();
		$fileobj->readonly(0);
	
		# Do the actual write
		$ok = write_file($file, $contents);

		# Set it back to what it was
		$fileobj->readonly($readonly);
	} else {
		$ok = write_file($file, $contents);
	}
	
	return $ok;
}



sub version {
	my (undef, undef, $script) = splitpath( $PROGRAM_NAME );

	print <<"EOF";
This is $script, version $STRING_VERSION, which relocates
Strawberry Perl to a new location.

Copyright 2010 Curtis Jewell.

This script may be copied only under the terms of either the Artistic License
or the GNU General Public License, which may be found in the Perl 5 
distribution or the distribution containing this script.
EOF

	return;
}



sub usage {
	my $error = shift;

	print "Error: $error\n\n" if (defined $error);
	my (undef, undef, $script) = splitpath( $PROGRAM_NAME );

	print <<"EOF";
This is $script, version $STRING_VERSION, which relocates
Strawberry Perl to a new location.

Usage: perl $script 
    [ --help ] [ --usage ] [ --man ] [ --version ] [ -? ]
    --file relocationfile

For more assistance, run perl $script --help.
EOF

	exit(1);	
}

__END__

=head1 NAME

relocation.pl - Relocates Strawberry Perl.

=head1 VERSION

This document describes relocation.pl version 1.000.

=head1 DESCRIPTION

This script updates all of Strawberry Perl's files to a new location.

=head1 SYNOPSIS

  module-version [ --help ] [ --usage ] [ --man ] [ --version ] [ -?] 
                 --file relocationfile [--location path] [--quiet]

  Options:
    --usage         Gives a minimum amount of aid and comfort.
    --help          Gives aid and comfort.
    -?              Gives aid and comfort.
    --man           Gives maximum aid and comfort.
	
    --version       Gives the name, version and copyright of the script.

    --file          Gives the location of the file of hints to use to 
                    relocate Perl.
    --location      The location to relocate to. Defaults to Cwd::cwd().
    --quiet         Print nothing.
	
=head1 DEPENDENCIES

Perl 5.8.9 is the mimimum version of perl that this script will run on.

Other modules that this script depends on are 
L<Getopt::Long|Getopt::Long>, L<Pod::Usage|Pod::Usage>, 
L<File::Slurp|File::Slurp>, and L<Win32::File::Object|Win32::File::Object>

=head1 SUPPORT

Support is provided for this script on the same basis as Strawberry Perl.
See L<http://strawberryperl.com/support.html> for details.

=head1 AUTHOR

Curtis Jewell, E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut

