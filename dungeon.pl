#!F:\perl\perl\bin\perl.exe
use 5;
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Term::ReadKey;

use constant {
	WIDTH => 25,
	HEIGHT => 25,
	
	# Movement
	UP => 'w',
	LEFT => 'a',
	DOWN => 's',
	RIGHT => 'd',
	CELL_GRASS => 0,
	CELL_TREE => 1,
	CELL_ROCK => 2,
	# water has to generate together
	# Chance there is water and it spreads
	CELL_WATER => 3,
	
	# Probability weights
	P_TREE => 0.005,
	P_ROCK => 0.005,
	P_WATER => 0.001,
	
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

# Game globals
our @MAP = ();

# Game vars
my ($x, $y, $cell, $RUNNING,
 $playerX, $playerY, 
);
$RUNNING = 1;
$playerX = int(BOUND_WIDTH / 2 + 0.5);
$playerY = int(BOUND_HEIGHT / 2 + 0.5);

# Populate
for ($y = 0; $y < HEIGHT; $y++) {
	for ($x = 0; $x < WIDTH; $x++) {
		$cell = CELL_GRASS;
		if (rand() < P_TREE) {
			$cell = CELL_TREE;
		}
		elsif (rand() < P_ROCK) {
			$cell = CELL_ROCK;
		}
		elsif (rand() < P_WATER) {
			$cell = CELL_WATER;
		}
		$MAP[$y][$x] = $cell;
	}
}

do {
	tick();
	printer();
} while ($RUNNING);

sub tick {
	my ($key, $deltaX, $deltaY, $relativeCell, $newX, $newY);
	$key = "";

	$key = ReadKey(-1) || "";
	chomp($key);

  # Defaults, save a few assignments
	$deltaX = 0;
	$deltaY = 0;
	if ($key eq UP) {
    $deltaY = -1;
  } elsif ($key eq DOWN) {
    $deltaY = 1;
  } elsif ($key eq RIGHT) {
    $deltaX = 1;
  } elsif ($key eq LEFT) {
		$deltaX = -1;
  }
	
  # Call getRelativeCell once, We don't have to do bounds checks anymore
	($relativeCell, $newX, $newY) = getRelativeCell($playerX, $playerY, $deltaX, $deltaY);

	if ($relativeCell == CELL_GRASS) {
		$playerX = $newX;
		$playerY = $newY;
	} else {
		# can't move
	}
};


# Get the cell n,m coordinates away from some requested x,y
# Wrap around on boundaries
# 
# @param int $playerX Player x pos
# @param int $playerY Player y pos
# @param int $shiftX  Horizontal shift 
# @param int $shiftY  Vertical shift
# 
# @return ($cell, $newX, $newY) The cell we landed on, and it's coords
sub getRelativeCell {
  if (scalar @_ != 4) {
    croak("Not enough arguments: playerX, playerY, shiftX, shiftY\n");
  }
  my($playerX, $playerY, $shiftX, $shiftY) = @_;
  my ($newX, $newY) = ($playerX + $shiftX, $playerY + $shiftY);
	$newX = BOUND_WIDTH if $newX > BOUND_WIDTH;
	$newX = 0 if $newX < 0;
	$newY = BOUND_HEIGHT if $newY > BOUND_HEIGHT;
	$newY = 0 if $newY < 0;
  return ($MAP[$newY][$newX], $newX, $newY);
}

sub printer {
	my $cell = 0;
	my $cell_value = '';
	my $buffer = '';
	for ($y = 0; $y < HEIGHT; $y++) {
		for ($x = 0; $x < WIDTH; $x++) {
			$cell = $MAP[$y][$x];
			if ($cell == CELL_GRASS) {
				$cell_value = '"';
			} elsif ($cell == CELL_TREE) {
				$cell_value = '#';
			} elsif ($cell == CELL_ROCK) {
				$cell_value = '@';
			} elsif ($cell == CELL_WATER) {
			    $cell_value = '~';
			}
			
			if ($y == $playerY && $x == $playerX) {
				$cell_value = '0';
			}
			$buffer .= $cell_value;
		}
		$buffer .= "\n";
	}
	print chr(0x08)x(WIDTH * HEIGHT);
	print $buffer;
}
