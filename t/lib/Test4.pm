package t::lib::Test4;

use strict;
use Perl::Dist::Strawberry;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.07';
	@ISA     = 'Perl::Dist::Strawberry';
}





#####################################################################
# Main Methods

sub new {
	return shift->SUPER::new(
		trace => 1,
		@_,
	);
}

sub trace { Test::More::diag($_[1]) }
