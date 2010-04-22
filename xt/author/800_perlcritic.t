#!/usr/bin/perl

# Test that modules pass perlcritic and perltidy.

use strict;
use Test::More;
use English qw(-no_match_vars);

BEGIN {
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Perl::Tidy',
	'Perl::Critic',
	'Regexp::Parser',
	'Email::Address',
	'Perl::Critic::Utils::Constants',
	'Perl::Critic::More',
	'Test::Perl::Critic',
);

plan( skip_all => "Not doing perlcriticism on this module yet..." );


# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "require $MODULE"; # Has to be require because we pass options to import.
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

if ( 1.105 > eval { $Perl::Critic::VERSION } ) {
	plan( skip_all => 'Perl::Critic needs updated to 1.105' );
}

if ( 20090616 > eval { $Perl::Tidy::VERSION } ) {
	plan( skip_all => "Perl::Tidy needs updated to 20090616" );
}

use File::Spec::Functions qw(catfile catdir);
Perl::Critic::Utils::Constants->import(':profile_strictness');
my $dummy = $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET;

local $ENV{PERLTIDY} = catfile( 't', 'settings', 'perltidy.txt' );

my $rcfile = catfile( 't', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( 
	-profile            => $rcfile, 
	-severity           => 1, 
	-profile-strictness => $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET
);

# I only want to criticize my own modules, not the module patches to the differing perls...
if (-d catdir('blib', 'lib')) {
    all_critic_ok(catdir('blib', 'lib', 'Perl'));
} else {
    all_critic_ok();
}