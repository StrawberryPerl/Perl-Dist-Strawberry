#!/usr/bin/perl

# Test that all modules have no common misspellings.

use strict;
use Test::More;
use English qw(-no_match_vars);

BEGIN {
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Spell::CommonMistakes 0.01',
	'Test::Pod::Spelling::CommonMistakes 0.01',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

all_pod_files_ok();
