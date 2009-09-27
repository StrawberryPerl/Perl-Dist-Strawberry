#!/usr/bin/perl

use strict;
use Carp;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Perl::Dist;

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_medium(
	903, '5101', 'Perl::Dist::Strawberry', 
	msi => 0
);

test_run_dist( $dist );

test_verify_files_medium(903, '510');

done_testing();
