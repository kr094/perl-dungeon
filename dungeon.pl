#!F:\perl\perl\bin\perl.exe
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Term::ReadKey;
use Data::Dumper;

use constant {
	WIDTH => 50,
	HEIGHT => 50,
	
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
	CELL_DOOR => 4,
	CELL_DOOR_RETURN => 5,
	
	# Probability weights
	P_TREE => 0.005,
	P_ROCK => 0.005,
	P_WATER => 0.001,
	
};

# Constants can't be used to define new constants in the same constant{} block
use constant {
	BOUND_HEIGHT => HEIGHT - 1,
	BOUND_WIDTH => WIDTH - 1,
};

# disable output buffer
$| = 1;
# resize terminal with windows commands
my ($h,$w) = (HEIGHT+1, WIDTH);
system("mode con lines=$h cols=$w");
# faster keyboard input 
system("mode con rate=100 delay=0");

# Game globals
our @MAP = generateMap();
our @HISTORY = ();

# Game vars
my ($x, $y, $cell, $RUNNING,
 $playerX, $playerY, $historyPos,
);
$RUNNING = 1;
$playerX = int(BOUND_WIDTH / 2 + 0.5);
$playerY = int(BOUND_HEIGHT / 2 + 0.5);
# Index within @HISTORY, the current screen
$historyPos = 0;

do {
	tick();
	printer();
} while ($RUNNING);

sub tick {
	my ($key, $deltaX, $deltaY, $relativeCell, $newX, $newY);
  # Potential new map. Used if navigating to a door
	my @newMap = ();
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
  } else {
		# Not a valid input
		return;
	}
	
  # Call getRelativeCell once, We don't have to do bounds checks anymore
	($relativeCell, $newX, $newY) = getRelativeCell($playerX, $playerY, $deltaX, $deltaY);

	if ($relativeCell == CELL_GRASS) {
		$playerX = $newX;
		$playerY = $newY;
	} elsif ($relativeCell == CELL_DOOR) {
		$historyPos++;
		@newMap = generateMap();
		$newMap[BOUND_HEIGHT][0] = CELL_DOOR_RETURN;
		push(@HISTORY, \@newMap);
		@MAP = @newMap;
	} elsif ($relativeCell == CELL_DOOR_RETURN) {
		$historyPos-- if $historyPos > 0;
		@MAP = @{$HISTORY[$historyPos]};
	} else {
		# can't move
	}
};


=for comment
Get the cell n,m coordinates away from some requested x,y
Wrap around on boundaries

@todo make this not depend on @MAP. Do the lookup of $cell outside

@param int $playerX Player x pos
@param int $playerY Player y pos
@param int $shiftX  Horizontal shift 
@param int $shiftY  Vertical shift

@return ($cell, $newX, $newY) The cell we landed on, and it's coords
=cut
sub getRelativeCell {
  if (scalar @_ != 4) {
    croak("Not enough arguments: playerX, playerY, shiftX, shiftY\n");
  }
  my($playerX, $playerY, $shiftX, $shiftY) = @_;
  my ($newX, $newY) = ($playerX + $shiftX, $playerY + $shiftY);
	$newX = 0 if $newX > BOUND_WIDTH;
	$newX = BOUND_WIDTH if $newX < 0;

	$newY = 0 if $newY > BOUND_HEIGHT;
	$newY = BOUND_HEIGHT if $newY < 0;
  return ($MAP[$newY][$newX], $newX, $newY);
}

=for comment
Generate a random map

@param %previousDoor Optional. Only if there is a previous door (one being entered)

@return @localMap New map
=cut
sub generateMap {
	my %previousDoor = shift if scalar @_;
	my @localMap = ();
	for ($y = 0; $y < HEIGHT; $y++) {
		for ($x = 0; $x < WIDTH; $x++) {
			$cell = CELL_GRASS;
			if (rand() < P_TREE) {
				$cell = CELL_TREE;
			} elsif (rand() < P_ROCK) {
				$cell = CELL_ROCK;
			} elsif (rand() < P_WATER) {
				$cell = CELL_WATER;
			}
			$localMap[$y][$x] = $cell;
		}
	}
	$localMap[rand(BOUND_HEIGHT)][rand(BOUND_WIDTH)] = CELL_DOOR;
	return @localMap;
}

sub printer {
	my $cell = 0;
	my $cell_value = '';
	my $buffer = '';
	for ($y = 0; $y < HEIGHT; $y++) {
		for ($x = 0; $x < WIDTH; $x++) {
			$cell = $MAP[$y][$x];

			if ($y == $playerY && $x == $playerX) {
				$cell_value = '0';
			} elsif ($y == 0 && $x == 0) {
				$cell_value = int($historyPos);
			} elsif ($cell == CELL_GRASS) {
				$cell_value = '"';
			} elsif ($cell == CELL_TREE) {
				$cell_value = '#';
			} elsif ($cell == CELL_ROCK) {
				$cell_value = '@';
			} elsif ($cell == CELL_WATER) {
				$cell_value = '~';
			} elsif ($cell == CELL_DOOR) {
				$cell_value = ']';
			} elsif ($cell == CELL_DOOR_RETURN) {
				$cell_value = '|';
			}
			
			$buffer .= $cell_value;
		}
		$buffer .= "\n";
	}
	print chr(0x08)x(WIDTH * HEIGHT);
	print $buffer;
}
