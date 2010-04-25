#!/usr/bin/perl

# Test that all modules have a version number.

use strict;
use Test::More;
use English qw(-no_match_vars);
use File::Spec::Functions qw(catdir);

BEGIN {
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Fixme 0.04',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

run_tests(
	where    => catdir(qw(blib lib Perl)),  # where to find files to check
	match    => 'TO' . 'DO',                # what to check for
);
