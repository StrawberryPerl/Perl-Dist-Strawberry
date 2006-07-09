#--------------------------------------------------------------------------#
# XXX THIS FILE HAS BEEN MODIFIED FROM THE ORIGINAL XXX
#
# Bundle::CPAN includes Module::Signature, which doesn't play well on win32.
# Until it's removed from the bundle, this file provides a mock interface
# with a sufficiently high VERSION to prevent CPAN from attempting to install
# it when upgrading a Bundle
#
# Its mock functionality will falsify a "valid signature" response for
# all queries.  Signing will falsely succeed and give a warning.
#
# Original file is copyright (c) 2002 by Audrey Tang
# Disabling modifications copyright (c) 2006 David Golden
#
#--------------------------------------------------------------------------#

package Module::Signature;
$Module::Signature::VERSION = '99999';

use 5.005;
use strict;
use vars qw($VERSION $SIGNATURE @ISA @EXPORT_OK);
use vars qw($Preamble $Cipher $Debug $Verbose $Timeout);
use vars qw($KeyServer $KeyServerPort $AutoKeyRetrieve $CanKeyRetrieve); 

use constant CANNOT_VERIFY       => '0E0';
use constant SIGNATURE_OK        => 0;
use constant SIGNATURE_MISSING   => -1;
use constant SIGNATURE_MALFORMED => -2;
use constant SIGNATURE_BAD       => -3;
use constant SIGNATURE_MISMATCH  => -4;
use constant MANIFEST_MISMATCH   => -5;
use constant CIPHER_UNKNOWN      => -6;

use ExtUtils::Manifest ();
use Exporter;

@EXPORT_OK      = (
    qw(sign verify),
    qw($SIGNATURE $KeyServer $Cipher $Preamble),
    (grep { /^[A-Z_]+_[A-Z_]+$/ } keys %Module::Signature::),
);
@ISA            = 'Exporter';

$SIGNATURE      = 'SIGNATURE';
$Timeout        = $ENV{MODULE_SIGNATURE_TIMEOUT} || 3;
$Verbose        = $ENV{MODULE_SIGNATURE_VERBOSE} || 0;
$KeyServer      = $ENV{MODULE_SIGNATURE_KEYSERVER} || 'pgp.mit.edu';
$KeyServerPort  = $ENV{MODULE_SIGNATURE_KEYSERVERPORT} || '11371';
$Cipher         = $ENV{MODULE_SIGNATURE_CIPHER} || 'SHA1';
$Preamble       = << ".";
This file contains message digests of all files listed in MANIFEST,
signed via the Module::Signature module, version $VERSION.

To verify the content in this distribution, first make sure you have
Module::Signature installed, then type:

    % cpansign -v

It will check each file's integrity, as well as the signature's
validity.  If "==> Signature verified OK! <==" is not displayed,
the distribution may already have been compromised, and you should
not run its Makefile.PL or Build.PL.

.

$AutoKeyRetrieve    = 1;
$CanKeyRetrieve     = undef;

sub verify {
    return SIGNATURE_OK;
}

sub sign {
    my %args = ( skip => 1, @_ );

    warn "Modified Module::Signature does not support signing";
    return SIGNATURE_OK;
}

1;

__END__

=head1 NAME

Module::Signature - Module signature file manipulation

=head1 VERSION

This document describes a modified version of B<Module::Signature>.

=head1 SYNOPSIS

 # Don't worry about this -- this module isn't functional.

=head1 DESCRIPTION

B<Module::Signature> adds cryptographic authentications to CPAN
distributions, via the special F<SIGNATURE> file.

It currently has dependency and newline troubles on win32, so this stub 
file is bundled with Win32 to allow Bundle::CPAN to install without error.

Until it's removed from the CPAN bundle, this file provides a mock interface
with a sufficiently high VERSION to prevent CPAN from attempting to install
it when upgrading a Bundle

Its mock functionality will falsify a "signature ok" response for
all queries.  Signing will also falsely succeed, but give a warning.

Original file is copyright (c) 2002 by Audrey Tang. 
Disabling modifications copyright (c) 2006 David Golden.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

( Custom modifications Copyright (c) 2006 by David Golden )

=head1 COPYRIGHT (The "MIT" License)

Copyright 2002-2006 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE X
CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
