#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

use_ok( 'Perl::Dist::Strawberry' );
use_ok( 'Perl::Dist::Bootstrap' );
diag( "Testing Perl::Dist::Strawberry $Perl::Dist::Strawberry::VERSION" );
