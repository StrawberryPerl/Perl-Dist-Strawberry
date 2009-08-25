#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Scalar::Util 'blessed';
use LWP::Online ':skip_all';
use File::Spec::Functions ':ALL';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
		exit(0);
	}
	plan( tests => 7 );
}

use Perl::Dist::Strawberry ();
use URI::file              ();
use t::lib::Test           ();





#####################################################################
# Generation Test

my $dist = t::lib::Test->new5(91);
isa_ok( $dist, 'Perl::Dist::Strawberry' );

# Run the dist object, and ensure everything we expect was created
my $time = scalar localtime();
diag( "Building test dist @ $time, may take several hours... (sorry)" );
ok( eval { $dist->run; 1; }, '->run ok' );
if ( defined $@ ) {
	if ( blessed( $@ ) && $@->isa("Exception::Class::Base") ) {
		diag($@->as_string);
	} else {
		diag($@);
	}
}
$time = scalar localtime();
diag( "Test dist finished @ $time." );
