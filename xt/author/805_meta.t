#!/usr/bin/perl

# Test that our META.yml file matches the specification

use strict;
use Test::More;
use English qw(-no_match_vars);

BEGIN {
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::CPAN::Meta 0.12',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

meta_yaml_ok();
