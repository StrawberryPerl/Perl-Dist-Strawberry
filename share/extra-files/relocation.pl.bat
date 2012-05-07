@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
%~dp0perl\bin\perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
%~dp0perl\bin\perl -x -S %0 %*
goto endofperl
@rem ';
#!perl

use 5.008009;
use strict;
use warnings;
use File::Slurp qw(read_file write_file);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use English qw( -no_match_vars );
use File::Spec::Functions qw(splitpath catfile);
use Carp qw(carp);
use Win32::File::Object qw();
use FindBin;

sub usage;
sub version;
sub relocate_file;

our $STRING_VERSION = our $VERSION = '1.002';
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
	@files = glob catfile($FindBin::Bin, '*.reloc.txt');
}

if (not defined $new_location) {
	$new_location = $FindBin::Bin;
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

	my $full_file = catfile($new_location, $file);
	
	my $contents = read_file($full_file);

	my ($old, $new) = 
		('backslash'       eq $type) ? get_replacements_backslash($old_location, $new_location)
	  : ('slash'           eq $type) ? get_replacements_slash($old_location, $new_location)
	  : ('doublebackslash' eq $type) ? get_replacements_doublebackslash($old_location, $new_location)
	  : ('url'             eq $type) ? get_replacements_url($old_location, $new_location)
	  : ();

	if (defined $old) {
		$contents =~ s{$old}{$new}gi;
	} else {
		carp "Can't do a $type relocation\n" if not $quiet;
		exit(1);
	}

	if ( not -f $full_file ) {
		carp "Can't relocate a file $file that isn't a file\n" if not $quiet;
		exit(1);
	}
	
	my $ok;
	if ( not -w $full_file ) {
		# Make sure it isn't readonly
		my $fileobj = Win32::File::Object->new( $full_file, 1 );
		my $readonly = $fileobj->readonly();
		$fileobj->readonly(0);
	
		# Do the actual write
		$ok = write_file($full_file, $contents);

		# Set it back to what it was
		$fileobj->readonly($readonly);
	} else {
		$ok = write_file($full_file, $contents);
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
    [--file relocationfile] [--location path] [--quiet]

For more assistance, run perl $script --help.
EOF

	exit(1);	
}

__END__

=head1 NAME

relocation.pl.bat - Relocates Strawberry Perl.

=head1 VERSION

This document describes relocation.pl.bat version 1.002.

=head1 DESCRIPTION

This script updates all of Strawberry Perl's files to a new location.

=head1 SYNOPSIS

  relocation.pl.bat [ --help ] [ --usage ] [ --man ] [ --version ] [ -?] 
                    [--file relocationfile] [--location path] [--quiet]

  Options:
    --usage         Gives a minimum amount of aid and comfort.
    --help          Gives aid and comfort.
    -?              Gives aid and comfort.
    --man           Gives maximum aid and comfort.
	
    --version       Gives the name, version and copyright of the script.

    --file          Gives the location of the file of hints to use to 
                    relocate Perl. Defaults to all *.reloc.txt files in
                    the current directory.
    --location      The location to relocate to. Defaults to $FindBin::Bin.
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

:endofperl
