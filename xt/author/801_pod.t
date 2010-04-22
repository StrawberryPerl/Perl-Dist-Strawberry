#!/usr/bin/perl

# Test that the syntax of our POD documentation is valid

use strict;
use Test::More;
use English qw(-no_match_vars);

BEGIN {
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Simple 3.07',
	'Test::Pod 1.26',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

all_pod_files_ok();
