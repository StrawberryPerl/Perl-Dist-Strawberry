#!perl
use strict;
use warnings;

my $inno_setup = "C:\\Program Files\\Inno Setup 5\\Compil32.exe";

system( $inno_setup, "/cc", "strawberry.iss" )
