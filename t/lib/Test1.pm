package t::lib::Test1;

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
		@_,
	);
}

sub trace { 1 } # Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_module {
	return shift->SUPER::install_module( @_, trace => sub { 1 } );
}

1;
