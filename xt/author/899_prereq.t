#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq 1.036',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

plan( skip_all => "Module::Install and Test::Prereq do not go together." );

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

#plan( skip_all => 'Test is buggy at the moment' );
#exit(0);

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

# Terminate leftovers with prejudice aforethought.
require File::Remove;
foreach my $dir ( 't\tmp500', 't\tmp900', 't\tmp901', 't\tmp902', 't\tmp903' ) {
	File::Remove::remove( \1, $dir ) if -d $dir;
}

my @modules_skip = (
# Needed only for AUTHOR_TEST tests
       'Perl::Critic::More',
       'Test::HasVersion',
       'Test::MinimumVersion',
       'Test::Perl::Critic',
       'Test::Prereq',
# Needed only for the optional script
	   'CPAN::Mini::Devel',
	   'File::Slurp',
	   'feature'
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

use File::Copy qw();

File::Copy::move( 't\inc\Module\Install.pm', 'inc\Module\Install.pm' );
File::Remove::remove( \1, 't\inc' );
