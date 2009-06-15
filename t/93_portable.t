#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
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
	plan( tests => 6 );
}

use Perl::Dist::Strawberry ();
use URI::file              ();
use t::lib::Test           ();





#####################################################################
# Generation Test

my $dist = t::lib::Test->new4(93);
isa_ok( $dist, 'Perl::Dist::Strawberry' );
ok( $dist->run, '->run ok' );
