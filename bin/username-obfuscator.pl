#!/usr/bin/perl -T

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Pod::Usage;
use POSIX;
use Math::BigInt;

Getopt::Long::Configure("gnu_getopt", "no_auto_abbrev");

my $help = 0;
my $man = 0;

GetOptions('help|?|h' => \$help, 'man' => \$man) or pod2usage(-output => \*STDERR, -exitval => 2);

pod2usage(-output => \*STDERR, -exitval => 1) if $help;
pod2usage(-verbose => 2, -output => \*STDERR, -exitval => 0) if $man;

my $in = $ARGV[0];
my $otp = $ARGV[1];

if (length ($otp) > length ($in)) {
	$otp = substr ($otp, 0, length ($in));
} elsif (length ($otp) < length ($in)) {
	$otp = $otp x (length ($in) / length ($otp));
	my $rem = (length ($in) % length ($otp));
	$otp = $otp . substr ($otp, 0, $rem);
}

my @in = split ('', $in);
my @otp = split ('', $otp);
my $base36digits = ceil ((length ($in) * log (256)) / log (36));
my $base36num = Math::BigInt->new (0);
my $i = 0;

while (@in) {
	my $xor_res = ord (shift (@in)) ^ ord (shift (@otp));
	if ($i) {
		$base36num->blsft (8);
	};
	$base36num->badd ($xor_res);
	++$i;
}

my $ret = $base36num->to_base (36);
if (length ($ret) < $base36digits) {
	$ret = "0" x ($base36digits - length ($ret)) . $ret;
}

print $ret . "\n";
