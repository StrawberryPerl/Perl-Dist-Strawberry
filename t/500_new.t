#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Perl::Dist 0.300;

#####################################################################
# Complete Generation Run

# Throw information on tghe testing module up.
diag("Testing with Test::Perl::Dist $Test::Perl::Dist::VERSION");

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_short(500, '589', 'Perl::Dist::Strawberry', 't');

# Check useragent method
my $ua = $dist->user_agent;
isa_ok( $ua, 'LWP::UserAgent' );

test_run_dist( $dist );

test_verify_files_short(500, '58', 't');

is( ref($dist->patch_include_path), 'ARRAY', '->patch_include_path ok' );

is( scalar(@{$dist->patch_include_path}), 2, 'Two include path entries' );

like( $dist->image_dir_url(), qr/^file\:\/\//, '->image_dir_url ok' );

ok( $dist->strawberry_url(), '->strawberry_url ok' );

done_testing(5);


