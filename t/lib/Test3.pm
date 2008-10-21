package t::lib::Test3;

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
		perl_version => 588,
		trace        => 1,
		@_,
	);
}

sub trace { Test::More::diag($_[1]) }

1;
