#!perl
use warnings;
use strict;
use Test::More 0.88;
use Config;

# Include a cut-down version of YAML::Tiny so we don't introduce unnecessary
# dependencies ourselves.

package Local::YAML::Tiny;

use strict;
use Carp 'croak';

# UTF Support?
sub HAVE_UTF8 () { $] >= 5.007003 }

BEGIN {
	if (HAVE_UTF8) {

		# The string eval helps hide this from Test::MinimumVersion
		eval "require utf8;";
		die "Failed to load UTF-8 support" if $@;
	}

	# Class structure
	require 5.004;
	$YAML::Tiny::VERSION = '1.40';

	# Error storage
	$YAML::Tiny::errstr = '';
} ## end BEGIN

# Printable characters for escapes
my %UNESCAPES = (
	z    => "\x00",
	a    => "\x07",
	t    => "\x09",
	n    => "\x0a",
	v    => "\x0b",
	f    => "\x0c",
	r    => "\x0d",
	e    => "\x1b",
	'\\' => '\\',
);


#####################################################################
# Implementation

# Create an empty YAML::Tiny object
sub new {
	my $class = shift;
	bless [@_], $class;
}

# Create an object from a file
sub read {
	my $class = ref $_[0] ? ref shift : shift;

	# Check the file
	my $file = shift
	  or return $class->_error('You did not specify a file name');
	return $class->_error("File '$file' does not exist") unless -e $file;
	return $class->_error("'$file' is a directory, not a file") unless -f _;
	return $class->_error("Insufficient permissions to read '$file'")
	  unless -r _;

	# Slurp in the file
	local $/ = undef;
	local *CFG;
	unless ( open( CFG, $file ) ) {
		return $class->_error("Failed to open file '$file': $!");
	}
	my $contents = <CFG>;
	unless ( close(CFG) ) {
		return $class->_error("Failed to close file '$file': $!");
	}

	$class->read_string($contents);
} ## end sub read

# Create an object from a string
sub read_string {
	my $class = ref $_[0] ? ref shift : shift;
	my $self = bless [], $class;
	my $string = $_[0];
	unless ( defined $string ) {
		return $self->_error("Did not provide a string to load");
	}

	# Byte order marks
	# NOTE: Keeping this here to educate maintainers
	# my %BOM = (
	#     "\357\273\277" => 'UTF-8',
	#     "\376\377"     => 'UTF-16BE',
	#     "\377\376"     => 'UTF-16LE',
	#     "\377\376\0\0" => 'UTF-32LE'
	#     "\0\0\376\377" => 'UTF-32BE',
	# );
	if ( $string =~ /^(?:\376\377|\377\376|\377\376\0\0|\0\0\376\377)/ ) {
		return $self->_error("Stream has a non UTF-8 BOM");
	} else {

		# Strip UTF-8 bom if found, we'll just ignore it
		$string =~ s/^\357\273\277//;
	}

	# Try to decode as utf8
	utf8::decode($string) if HAVE_UTF8;

	# Check for some special cases
	return $self unless length $string;
	unless ( $string =~ /[\012\015]+\z/ ) {
		return $self->_error("Stream does not end with newline character");
	}

	# Split the file into lines
	my @lines = grep { !/^\s*(?:\#.*)?\z/ }
	  split /(?:\015{1,2}\012|\015|\012)/, $string;

	# Strip the initial YAML header
	@lines and $lines[0] =~ /^\%YAML[: ][\d\.]+.*\z/ and shift @lines;

	# A nibbling parser
	while (@lines) {

		# Do we have a document header?
		if ( $lines[0] =~ /^---\s*(?:(.+)\s*)?\z/ ) {

			# Handle scalar documents
			shift @lines;
			if ( defined $1 and $1 !~ /^(?:\#.+|\%YAML[: ][\d\.]+)\z/ ) {
				push @$self, $self->_read_scalar( "$1", [undef], \@lines );
				next;
			}
		}

		if ( !@lines or $lines[0] =~ /^(?:---|\.\.\.)/ ) {

			# A naked document
			push @$self, undef;
			while ( @lines and $lines[0] !~ /^---/ ) {
				shift @lines;
			}

		} elsif ( $lines[0] =~ /^\s*\-/ ) {

			# An array at the root
			my $document = [];
			push @$self, $document;
			$self->_read_array( $document, [0], \@lines );

		} elsif ( $lines[0] =~ /^(\s*)\S/ ) {

			# A hash at the root
			my $document = {};
			push @$self, $document;
			$self->_read_hash( $document, [ length($1) ], \@lines );

		} else {
			croak("YAML::Tiny failed to classify the line '$lines[0]'");
		}
	} ## end while (@lines)

	$self;
} ## end sub read_string

# Deparse a scalar string to the actual scalar
sub _read_scalar {
	my ( $self, $string, $indent, $lines ) = @_;

	# Trim trailing whitespace
	$string =~ s/\s*\z//;

	# Explitic null/undef
	return undef if $string eq '~';

	# Quotes
	if ( $string =~ /^\'(.*?)\'\z/ ) {
		return '' unless defined $1;
		$string = $1;
		$string =~ s/\'\'/\'/g;
		return $string;
	}
	if ( $string =~ /^\"((?:\\.|[^\"])*)\"\z/ ) {

		# Reusing the variable is a little ugly,
		# but avoids a new variable and a string copy.
		$string = $1;
		$string =~ s/\\"/"/g;
		$string =~
s/\\([never\\fartz]|x([0-9a-fA-F]{2}))/(length($1)>1)?pack("H2",$2):$UNESCAPES{$1}/gex;
		return $string;
	}

	# Special cases
	if ( $string =~ /^[\'\"!&]/ ) {
		croak(
			"YAML::Tiny does not support a feature in line '$lines->[0]'");
	}
	return {} if $string eq '{}';
	return [] if $string eq '[]';

	# Regular unquoted string
	return $string unless $string =~ /^[>|]/;

	# Error
	croak("YAML::Tiny failed to find multi-line scalar content")
	  unless @$lines;

	# Check the indent depth
	$lines->[0] =~ /^(\s*)/;
	$indent->[-1] = length("$1");
	if ( defined $indent->[-2] and $indent->[-1] <= $indent->[-2] ) {
		croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
	}

	# Pull the lines
	my @multiline = ();
	while (@$lines) {
		$lines->[0] =~ /^(\s*)/;
		last unless length($1) >= $indent->[-1];
		push @multiline, substr( shift(@$lines), length($1) );
	}

	my $j = ( substr( $string, 0, 1 ) eq '>' ) ? ' ' : "\n";
	my $t = ( substr( $string, 1, 1 ) eq '-' ) ? ''  : "\n";
	return join( $j, @multiline ) . $t;
} ## end sub _read_scalar

# Parse an array
sub _read_array {
	my ( $self, $array, $indent, $lines ) = @_;

	while (@$lines) {

		# Check for a new document
		if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
			while ( @$lines and $lines->[0] !~ /^---/ ) {
				shift @$lines;
			}
			return 1;
		}

		# Check the indent level
		$lines->[0] =~ /^(\s*)/;
		if ( length($1) < $indent->[-1] ) {
			return 1;
		} elsif ( length($1) > $indent->[-1] ) {
			croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
		}

		if ( $lines->[0] =~ /^(\s*\-\s+)[^\'\"]\S*\s*:(?:\s+|$)/ ) {

			# Inline nested hash
			my $indent2 = length("$1");
			$lines->[0] =~ s/-/ /;
			push @$array, {};
			$self->_read_hash( $array->[-1], [ @$indent, $indent2 ],
				$lines );

		} elsif ( $lines->[0] =~ /^\s*\-(\s*)(.+?)\s*\z/ ) {

			# Array entry with a value
			shift @$lines;
			push @$array,
			  $self->_read_scalar( "$2", [ @$indent, undef ], $lines );

		} elsif ( $lines->[0] =~ /^\s*\-\s*\z/ ) {
			shift @$lines;
			unless (@$lines) {
				push @$array, undef;
				return 1;
			}
			if ( $lines->[0] =~ /^(\s*)\-/ ) {
				my $indent2 = length("$1");
				if ( $indent->[-1] == $indent2 ) {

					# Null array entry
					push @$array, undef;
				} else {

					# Naked indenter
					push @$array, [];
					$self->_read_array( $array->[-1],
						[ @$indent, $indent2 ], $lines );
				}

			} elsif ( $lines->[0] =~ /^(\s*)\S/ ) {
				push @$array, {};
				$self->_read_hash( $array->[-1], [ @$indent, length("$1") ],
					$lines );

			} else {
				croak("YAML::Tiny failed to classify line '$lines->[0]'");
			}

		} elsif ( defined $indent->[-2] and $indent->[-1] == $indent->[-2] )
		{

			# This is probably a structure like the following...
			# ---
			# foo:
			# - list
			# bar: value
			#
			# ... so lets return and let the hash parser handle it
			return 1;

		} else {
			croak("YAML::Tiny failed to classify line '$lines->[0]'");
		}
	} ## end while (@$lines)

	return 1;
} ## end sub _read_array

# Parse an array
sub _read_hash {
	my ( $self, $hash, $indent, $lines ) = @_;

	while (@$lines) {

		# Check for a new document
		if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
			while ( @$lines and $lines->[0] !~ /^---/ ) {
				shift @$lines;
			}
			return 1;
		}

		# Check the indent level
		$lines->[0] =~ /^(\s*)/;
		if ( length($1) < $indent->[-1] ) {
			return 1;
		} elsif ( length($1) > $indent->[-1] ) {
			croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
		}

		# Get the key
		unless ( $lines->[0] =~ s/^\s*([^\'\" ][^\n]*?)\s*:(\s+|$)// ) {
			if ( $lines->[0] =~ /^\s*[?\'\"]/ ) {
				croak(
"YAML::Tiny does not support a feature in line '$lines->[0]'"
				);
			}
			croak("YAML::Tiny failed to classify line '$lines->[0]'");
		}
		my $key = $1;

		# Do we have a value?
		if ( length $lines->[0] ) {

			# Yes
			$hash->{$key} =
			  $self->_read_scalar( shift(@$lines), [ @$indent, undef ],
				$lines );
		} else {

			# An indent
			shift @$lines;
			unless (@$lines) {
				$hash->{$key} = undef;
				return 1;
			}
			if ( $lines->[0] =~ /^(\s*)-/ ) {
				$hash->{$key} = [];
				$self->_read_array( $hash->{$key}, [ @$indent, length($1) ],
					$lines );
			} elsif ( $lines->[0] =~ /^(\s*)./ ) {
				my $indent2 = length("$1");
				if ( $indent->[-1] >= $indent2 ) {

					# Null hash entry
					$hash->{$key} = undef;
				} else {
					$hash->{$key} = {};
					$self->_read_hash( $hash->{$key},
						[ @$indent, length($1) ], $lines );
				}
			} ## end elsif ( $lines->[0] =~ /^(\s*)./)
		} ## end else [ if ( length $lines->[0...])]
	} ## end while (@$lines)

	return 1;
} ## end sub _read_hash

# Set error
sub _error {
	$YAML::Tiny::errstr = $_[1];
	undef;
}

# Retrieve error
sub errstr {
	$YAML::Tiny::errstr;
}



#####################################################################
# Use Scalar::Util if possible, otherwise emulate it

BEGIN {
	eval { require Scalar::Util; };
	if ($@) {

		# Failed to load Scalar::Util
		eval <<'END_PERL';
sub refaddr {
	my $pkg = ref($_[0]) or return undef;
	if (!!UNIVERSAL::can($_[0], 'can')) {
		bless $_[0], 'Scalar::Util::Fake';
	} else {
		$pkg = undef;
	}
	"$_[0]" =~ /0x(\w+)/;
	my $i = do { local $^W; hex $1 };
	bless $_[0], $pkg if defined $pkg;
	$i;
}
END_PERL
	} else {
		Scalar::Util->import('refaddr');
	}
} ## end BEGIN


#####################################################################
# main test
#####################################################################

package main;

BEGIN {

   # Skip modules that either don't want to be loaded directly, such as
   # Module::Install, or that mess with the test count, such as the Test::*
   # modules listed here.
   #
   # Moose::Role conflicts if Moose is loaded as well, but Moose::Role is in
   # the Moose distribution and it's certain that someone who uses
   # Moose::Role also uses Moose somewhere, so if we disallow Moose::Role,
   # we'll still get the relevant version number.

	my %skip = map { $_ => 1 } qw(
	  App::FatPacker
	  Class::Accessor::Classy
	  Module::Install
	  Moose::Role
	  Test::YAML::Meta
	  Test::Pod::Coverage
	  Test::Portability::Files
	  Test::Perl::Dist
	);

	my $Test = Test::Builder->new;

	$Test->plan( skip_all => "META.yml could not be found" )
	  unless -f 'META.yml' and -r _;

	my $meta = ( Local::YAML::Tiny->read('META.yml') )->[0];
	my %requires;
	for my $require_key ( grep {/requires/} keys %$meta ) {
		my %h = %{ $meta->{$require_key} };
		$requires{$_}++ for keys %h;
	}
	delete $requires{perl};

	diag("Testing with Perl $], $Config{archname}, $^X");
	for my $module ( sort keys %requires ) {
		if ( $skip{$module} ) {
			note "$module doesn't want to be loaded directly, skipping";
			next;
		}
		local $SIG{__WARN__} = sub { note "$module: $_[0]" };
		use_ok $module or BAIL_OUT("can't load $module");
		my $version = $module->VERSION;
		$version = 'undefined' unless defined $version;
		diag("    $module version is $version");
	}
	done_testing;
} ## end BEGIN
