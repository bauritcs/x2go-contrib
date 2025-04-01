#!/usr/bin/perl -T

#############################################################################
# username-obfuscator.pl - transforms usernames via OTP and outputs base36. #
# Copyright (C) 2025  Mihai Moldovan <ionic@ionic.de>                       #
#                                                                           #
# This program is free software: you can redistribute it and/or modify      #
# it under the terms of the GNU General Public License as published by      #
# the Free Software Foundation, either version 3 of the License, or         #
# (at your option) any later version.                                       #
#                                                                           #
# This program is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
# GNU General Public License for more details.                              #
#                                                                           #
# You should have received a copy of the GNU General Public License         #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.    #
#############################################################################

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Pod::Usage;
use POSIX;
use Math::BigInt;

Getopt::Long::Configure ('gnu_getopt', 'no_auto_abbrev');

my $help = 0;
my $man = 0;

GetOptions ('help|?|h' => \$help,
	    'man' => \$man) or pod2usage (-output => \*STDERR, -exitval => 2);

pod2usage (-output => \*STDERR, -exitval => 1) if $help;
pod2usage (-verbose => 2, -output => \*STDERR, -exitval => 0) if $man;

my ($username, $otp) = @ARGV;

pod2usage (-message => 'Expected user name as first argument.',
	   -output => \*STDERR, -exitval => 3) if (not defined ($username));

pod2usage (-message => 'User name does not look legal.',
	   -output => \*STDERR,
	   -exitval => 4) unless $username =~ /^[a-zA-Z_][-a-zA-Z0-9_.]*$/;

pod2usage (-message => 'Expected OTP as second argument.',
	   -output => \*STDERR, -exitval => 5) if (not defined ($otp));

# Make sure that OTP length is the same as the user name length.
if (length ($otp) > length ($username)) {
	print STDERR 'OTP longer than user name, truncating it to the user ' .
		     'name\'s length.' . "\n";
	$otp = substr ($otp, 0, length ($username));
}
elsif (length ($otp) < length ($username)) {
	print STDERR 'OTP shorter than the user name! This is unsafe!' . "\n" .
		     'The OTP will be repeated as many times as necessary ' .
		     'to match the user name\'s length.' . "\n" .
		     'Please consider using an OTP that is at least as ' .
		     'long as the user name!' . "\n";

	# Fully repeat it as many times as necessary.
	$otp = $otp x (length ($username) / length ($otp));

	# If the user name is still longer, copy as many characters from the
	# beginning of the OTP to the end so that string sizes match up.
	# Example: (brackets to show which part of the user name and OTP match
	#           up in length)
	#          [abc]defgh [xyz] will lead to the OTP being repeated twice,
	#          so we now have [abcdef]gh [xyzxyz], but still need to
	#          repeat two other characters to cover all user name
	#          characters, so we end up with [abcdefgh] [xyzxyzxy].
	my $rem = (length ($username) % length ($otp));
	$otp = $otp . substr ($otp, 0, $rem);
}

# Split input into individual characters for easy handling.
my @username_chrs = split ('', $username);
my @otp_chrs = split ('', $otp);

my $base36num = Math::BigInt->new (0);

while (@username_chrs) {
	my $xor_res = ord (shift (@username_chrs)) ^ ord (shift (@otp_chrs));

	if (0 != $base36num) {
		$base36num->blsft (8);
	}
	$base36num->badd ($xor_res);
}

my $ret = $base36num->to_base (36);

print $ret . "\n";

exit (0);

__END__

=head1 NAME

username-obfuscator.pl - Obfuscates username via OTP input

=head1 SYNOPSIS

=over

=item B<username-obfuscator.pl> B<--help>|B<-h>|B<-?>

=item B<username-obfuscator.pl> B<--man>

=item B<username-obfuscator.pl> I<USERNAME> I<OTP>

=back

=head1 DESCRIPTION

B<username-obfuscator.pl> takes a user name as its first operand (I<USERNAME>)
and an OTP (I<OTP>) as its second operand.

The user name will be mangled by using a (bitwise) exclusive or (I<XOR>)
operation on each character of the input arguments.

To make sure, that the resulting data is an alphanumeric string, it is then
encoded through base36 and printed to the standard output.

=head2 ABOUT THE OTP

Internally, the provided OTP is mangled so that it matches the provided user
name in length, if that is not already the case.

=over

=item *

If the I<OTP> length matches the I<USERNAME> length, nothing is modified.

This is the best-case scenario and users are encouraged to use length-matching
arguments.

Example: B<username-obfuscator.pl> I<'user'> I<'name'>

Resulting OTP: I<'name'>

=item *

If the I<OTP> is longer than the provided I<USERNAME>, it is truncated to match
the user name's length.

This operation is rather safe, since additional information
is just discarded and the entropy provided by the user for user name mangling
is preserved.

Example: B<username-obfuscator.pl> I<'usr'> I<'name'>

Resulting OTP: I<'nam'>

=item *

If the I<OTP> is shorter than the provided I<USERNAME>, it is repeated as long
as it takes to match the provided user name's length.

This operation is risky, but the best thing we can do in this case. Avoid OTP
lengths less than the length of the user name string at any cost.

Example: B<username-obfuscator.pl> I<'veryveryveryverylongusername'> I<'shortotp'>

Resulting OTP: I<'shortotpshortotpshortotpshor'>

=back

=head2 WARNING

This obfuscator is neither cryptographically secure, nor is it meant to be:

=over

=item *

The base36 encoding can be easily reversed.

=item *

Known-plaintext attacks can trivially return the OTP used for obfuscation.

=item *

Linguistic attacks are made difficult by choosing a proper OTP, but not
impossible.

=back

=head1 OPTIONS

=over 8

=item B<--help>|B<-h>|B<-?>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 AUTHOR

This manual has been written by L<Mihai Moldovan|mailto:ionic@ionic.de> for
L<the X2Go project|https://www.x2go.org>.

=cut
