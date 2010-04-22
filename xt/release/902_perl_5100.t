#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Perl::Dist 0.300;
use File::Spec::Functions qw(catdir);

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_long(
	902, '5100', 'Perl::Dist::Strawberry', catdir(qw(xt release)),
);

test_run_dist( $dist );

test_verify_files_long(902, '510', catdir(qw(xt release)));

done_testing();