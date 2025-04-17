#!/usr/bin/perl -T

#############################################################################
# username-obfuscator.pl - UNIX user name obfuscator using OTP and base36.  #
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

use constant {
	ERR_OPTS => 2,
	ERR_MISSING_USERNAME => 3,
	ERR_INVALID_USERNAME => 4,
	ERR_MISSING_OTP => 5,
	ERR_MISSING_PREFIX => 6,
	ERR_INVALID_PREFIX => 7,
	ERR_UNSAFE_OTP => 8
};

my $help = 0;
my $man = 0;
my $safe_otp = 0;
my $prefix = undef;

GetOptions ('help|?|h' => \$help,
	    'man' => \$man,
	    'prefix|p=s' => \$prefix,
	    'safe-otp|s' => \$safe_otp) or pod2usage (-output => \*STDERR, -exitval => ERR_OPTS);

pod2usage (-output => \*STDERR, -exitval => 1) if $help;
pod2usage (-verbose => 2, -output => \*STDERR, -exitval => 0) if $man;

my ($username, $otp) = @ARGV;

pod2usage (-message => 'Expected user name as first argument.',
	   -output => \*STDERR, -exitval => ERR_MISSING_USERNAME) if (not defined ($username));

## no critic (RegularExpressions::RequireLineBoundaryMatching)
pod2usage (-message => 'User name does not look legal.',
	   -output => \*STDERR,
	   -exitval => ERR_INVALID_USERNAME) unless $username =~ /^[[:alpha:]_][-[:alnum:]_.]*$/xs;
## use critic

pod2usage (-message => 'Expected OTP as second argument.',
	   -output => \*STDERR, -exitval => ERR_MISSING_OTP) if (not defined ($otp));

pod2usage (-message => 'No prefix provided.',
	   -output => \*STDERR, -exitval => ERR_MISSING_PREFIX) if ((defined ($prefix)) && ('' eq $prefix));

## no critic (RegularExpressions::RequireLineBoundaryMatching)
pod2usage (-message => 'Prefix does not look legal.',
	   -output => \*STDERR,
	   -exitval => ERR_INVALID_PREFIX) if ((defined ($prefix)) && ($prefix !~ /^[[:alnum:]_][-[:alnum:]_.]*$/xs));
## use critic

# Make sure that OTP length is the same as the user name length.
if (length ($otp) > length ($username)) {
	print {*STDERR} 'OTP longer than user name, truncating it to the user ' .
			'name\'s length.' . "\n";
	$otp = substr ($otp, 0, length ($username));
}
elsif (length ($otp) < length ($username)) {
	print {*STDERR} 'OTP shorter than the user name! This is unsafe!' . "\n";

	if (0 == $safe_otp) {
		print {*STDERR} 'The OTP will be repeated as many times as ' .
				'necessary to match the user name\'s ' .
				'length.' . "\n" .
				'Please consider using an OTP that is at ' .
				'least as long as the user name!' . "\n";

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
	else {
		exit (ERR_UNSAFE_OTP);
	}
}

# Split input into individual characters for easy handling.
my @username_chrs = split (//msx, $username);
my @otp_chrs = split (//msx, $otp);

my $base36num = Math::BigInt->new (0);

# Loop through all the characters in the user name string and ...
while (@username_chrs) {
	# ... convert each character to its ordinal (ASCII) value, XORing them
	# with each character of the OTP ...
	my $xor_res = ord (shift (@username_chrs)) ^ ord (shift (@otp_chrs));

	if (0 != $base36num) {
		# Shift temporary result number up eight bits (i.e., a byte...
		# hopefully...) if it isn't "empty", i.e., zero.
		$base36num->blsft (8);
	}

	# ... and finally add the XOR'd result to the lowest 8 bits of the
	# temporary number.
	$base36num->badd ($xor_res);
}

# Convert to base36.
my $ret = $base36num->to_base (36);

# Convert to lowercase, which is better suited to UNIX user names, although
# strictly speaking, uppercase characters are also legit.
$ret = lc ($ret);

# Drop leading zeros.
$ret =~ s/^0*(.*)$/$1/sx; ## no critic (RegularExpressions::RequireLineBoundaryMatching)

if (defined ($prefix)) {
	$ret = $prefix . $ret;
}

if ($ret =~ m/^[-\d.]/sx) { ## no critic (RegularExpressions::RequireLineBoundaryMatching)
	# If the result starts with digits, transpose them with the first
	# alphanumeric or underscore character.
	# UNIX user names are typically not allowed to start with either
	# digits, dashes or dots, so we want to make sure that these
	# characters are not part of the start.
	# We still want to keep the characters in the string, but transpose
	# the first "legal" starting character to the front.
	# Note that this breaks the whole base36 scheme and decoding such a
	# string will not be possible, unless we've prepended a prefix and it
	# turns out that we only need to transpose (part of) the prefix.
	# Also note that this could be simplified to just
	# s/^(\d*)(.)(.*)$/$2$1$3/sx because the base36 result cannot include
	# either dashes, dots or underscores, but it's good to be more
	# specific to showcase what we're actually after.
	$ret =~ s/^([-\d.]*)([[:lower:]_])(.*)$/$2$1$3/sx; ## no critic (RegularExpressions::RequireLineBoundaryMatching)
}

# Lastly, if the result contains only digits, add an underscore to make it a
# legit UNIX user name (hopefully).
if ($ret =~ m/^\d+$/sx) { ## no critic (RegularExpressions::RequireLineBoundaryMatching)
	$ret = '_' . $ret;
}

print $ret . "\n";

exit (0);

__END__

=head1 NAME

username-obfuscator.pl - Obfuscates username via OTP input

=head1 SYNOPSIS

=over

=item B<username-obfuscator.pl> B<--help>|B<-h>|B<-?>

=item B<username-obfuscator.pl> B<--man>

=item B<username-obfuscator.pl> [B<--prefix>|B<-p> I<PREFIX>] [B<--safe-otp>|B<-s>] I<USERNAME> I<OTP>

=back

=head1 DESCRIPTION

B<username-obfuscator.pl> takes a user name as its first operand (I<USERNAME>)
and an OTP (I<OTP>) as its second operand. Optionally, you may specify a prefix
(I<PREFIX>) to be prepended to the result via the B<--prefix> option.

The user name will be mangled by using a (bitwise) exclusive or (I<XOR>)
operation on each character of the input arguments.

To make sure, that the resulting data is an alphanumeric string, it is then
encoded through base36, converted to lowercase, the prefix prepended if
provided, potentially further mangled in order to attain proper UNIX user name
semantics, and printed to the standard output.

If an optional prefix is provided and it does not start with a digit, dot or
dash character, no mangling is required and this step is hence skipped.

=head2 ABOUT THE OTP

Internally, the provided OTP is mangled so that it matches the provided user
name in length, if that is not already the case.

If the B<--safe-otp> option has been provided, shorter OTPs lead to program
termination.

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
as it takes to match the provided user name's length, unless the B<--safe-otp>
option has been provided.

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

=item B<--prefix>|B<-p>

Specifies the prefix to prepend to the converted user name.

=item B<--safe-otp>|B<-s>

Return an error if the OTP is too short to encrypt the whole user name string.

=back

=head1 RETURN

First and foremost, this utility shall print a valid UNIX user name to stdout
and return a value of zero, unless an error occurred or the B<--man> option has
been used.

Errors are indicated by non-zero return values.

If the B<--man> option was specified, the whole man page is printed to stderr
and the program returns a value of zero.

While base36 is used internally to obfuscate the input user name, the returned
obfuscated user name is not guaranteed to be valid base36 input - not even
after converting it to uppercase characters.

=head1 AUTHOR

This manual has been written by L<Mihai Moldovan|mailto:ionic@ionic.de> for
L<the X2Go project|https://www.x2go.org>.

=cut
