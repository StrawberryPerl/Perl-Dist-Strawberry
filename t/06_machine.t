#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	plan( tests => 6 );
}

use File::Spec::Functions ':ALL';
use Perl::Dist::Strawberry ();
use URI::file              ();
use t::lib::Test           ();





#####################################################################
# Generation Test

my $output = catdir( 't', 'tmp7' );
t::lib::Test::remake_path( $output );
my $machine = Perl::Dist::Strawberry->default_machine(
	t::lib::Test->paths(6),
	output => $output,
);
isa_ok( $machine, 'Perl::Dist::Machine' );

# Run the machine and generate the dists
ok( $machine->run, '->run completed' );
