#!/usr/bin/perl -T

use strict;
use warnings;
use diagnostics;

use POSIX;
use Math::BigInt;

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
