#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.20',
	'Test::MinimumVersion 0.008',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

# Terminate leftovers with prejudice aforethought.
require File::Remove;
foreach my $dir ( 't\tmp50', 't\tmp900', 't\tmp904', 't\tmp901', 't\tmp902', 't\tmp903' ) {
	File::Remove::remove( \1, $dir ) if -d $dir;
}

use File::Spec::Functions qw(catdir);
# I only want to test my own modules, not the module patches to the differing perls...
# Nor do I want 5k+ tests after a RELEASE_TESTING build!
if (-d catdir('blib', 'lib')) {
    all_minimum_version_from_metayml_ok({ paths => [ catdir('blib', 'lib', 'Perl'), 't' ]});
} else {
    all_minimum_version_from_metayml_ok({ paths => [ catdir('lib', 'Perl'), 't' ]});
}
