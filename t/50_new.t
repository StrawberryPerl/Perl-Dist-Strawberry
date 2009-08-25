#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Scalar::Util 'blessed';
use File::Spec::Functions ':ALL';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
		exit(0);
	}
	plan( tests => 12 );
}

use Perl::Dist::Strawberry ();
use URI::file              ();
use t::lib::Test           ();





#####################################################################
# Constructor Test

my $dist = t::lib::Test->new1(50);
isa_ok( $dist, 'Perl::Dist::Strawberry' );
is( ref($dist->patch_include_path), 'ARRAY', '->patch_include_path ok' );
is( scalar(@{$dist->patch_include_path}), 2, 'Two include path entries' );
like( $dist->image_dir_url, qr/^file\:\/\//, '->image_dir_url ok' );
ok( $dist->strawberry_url, '->strawberry_url ok' );
