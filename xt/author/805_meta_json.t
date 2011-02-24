#!perl

# Test that our META.yml file matches the specification

use strict;
use Test::More;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Parse::CPAN::Meta 1.4401',
	'Test::CPAN::Meta::JSON 0.10',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

meta_json_ok();

