package t::lib::TestNew;

use strict;
use Perl::Dist::Strawberry;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.00';
	@ISA     = 'Perl::Dist::Strawberry';
}





#####################################################################
# Main Methods

sub new {
	return shift->SUPER::new(
		perl_version => 5100,
		trace        => 101,
		@_,
	);
}

1;
