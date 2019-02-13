use Time::HiRes qw( sleep );

$| = 1;  # Disable buffering on STDOUT.

my $BACKSPACE = chr(0x08);

my @seq = qw( | / - \ );

do {
	for ($i = 0; $i < 4; $i++) {
		print $seq[$i];
		sleep 0.200;
		print $BACKSPACE;
	}
} while (1);
