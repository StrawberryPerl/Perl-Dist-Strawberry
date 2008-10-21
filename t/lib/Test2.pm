package t::lib::Test2;

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
		perl_version => 5100,
		trace        => 1,
		@_,
	);
}

sub trace { Test::More::diag($_[1]) }

1;
