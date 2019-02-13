use 5;
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Data::Dumper;

use constant {
	WIDTH => 200,
	HEIGHT => 70,
	# Keep burning trees visible for a bit
	VBLANK_FRAMES => 32,
	PROBABILITY => 0.001,
	CELL_EMPTY => 0,
	CELL_TREE => 1,
	CELL_HEATING => 2,
	CELL_BURNING => 3,
	
};

# sigh
use constant {
	BOUND_HEIGHT => HEIGHT - 1,
	BOUND_WIDTH => WIDTH - 1,
};

# disable output buffer
$| = 1;
# resize terminal with windows garb
my ($h,$w) = (HEIGHT+1, WIDTH);
system("mode con lines=$h cols=$w");
our @forest = ();
my ($x, $y, $tree, $TICK_COUNT);
$TICK_COUNT = 0;

for ($y = 0; $y < HEIGHT; $y++) {
	for ($x = 0; $x < WIDTH; $x++) {
		$tree = CELL_EMPTY;
		if (rand() < PROBABILITY) {
			$tree = CELL_TREE;
		}
		$forest[$y][$x] = $tree;
	}
}

while (1) {
	tick();
	print_forest();
	usleep(2000);
}

sub tick {
	$TICK_COUNT++;
	$TICK_COUNT = 0 if $TICK_COUNT > 1000;
	my $neighbor_burning = 0;
	my $cell = 0;
	
	for ($y = 0; $y < HEIGHT; $y++) {
		for ($x = 0; $x < WIDTH; $x++) {
			$cell = $forest[$y][$x];
			if ($cell == CELL_EMPTY) {
				if (rand() < PROBABILITY) {
					$forest[$y][$x] = CELL_TREE;
				}
			} elsif ($cell == CELL_TREE) {
				$neighbor_burning = 0;
				if ($y < BOUND_HEIGHT && $forest[$y+1][$x] == CELL_BURNING) {
					$neighbor_burning = 1;
				} elsif ($y > 0 && $forest[$y-1][$x] == CELL_BURNING) {
					$neighbor_burning = 1;
				} elsif ($x < BOUND_WIDTH && $forest[$y][$x+1] == CELL_BURNING) {
					$neighbor_burning = 1;
				} elsif ($x > 0 && $forest[$y][$x-1] == CELL_BURNING) {
					$neighbor_burning = 1;
				}
				if ($neighbor_burning) {
					$forest[$y][$x] = CELL_HEATING;
				}
				
				# lightning!
				if (rand() < PROBABILITY) {
					$forest[$y][$x] = CELL_BURNING;
				}
			} elsif ($cell == CELL_HEATING) {
				$forest[$y][$x] = CELL_BURNING;
				
				# decay trees randomly
				# if the current frame * rand() + 100 % vbf == 0
				
			} elsif ($cell == CELL_BURNING) {
				if ((100+ $TICK_COUNT * rand()) % VBLANK_FRAMES == 0) {
					$forest[$y][$x] = CELL_EMPTY;
				}
			}
		}
	}
};

sub print_forest {
	my $cell = 0;
	my $cell_value = '';
	my $buffer = '';
	for ($y = 0; $y < HEIGHT; $y++) {
		for ($x = 0; $x < WIDTH; $x++) {
			$cell = $forest[$y][$x];
			if ($cell == CELL_EMPTY) {
				$cell_value = ' ';
			} elsif ($cell == CELL_TREE || $cell == CELL_HEATING) {
				$cell_value = '.';
			} elsif ($cell == CELL_BURNING) {
				$cell_value = '*';
			}
			$buffer .= $cell_value;
		}
		$buffer .= "\n";
	}
	print chr(0x08)x(WIDTH * HEIGHT);
	print $buffer;
}
