#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Perl::Dist 0.300;
use File::Spec::Functions qw(catdir);

unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Release tests not required for installation" );
}

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_long(
	900, '5101', 'Perl::Dist::Bootstrap', catdir(qw(xt release)),
	user_agent_cache => 0,
);

test_run_dist( $dist );

test_verify_files_long(900, '510', catdir(qw(xt release)));

done_testing();