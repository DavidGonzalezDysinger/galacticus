#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use lib exists($ENV{'GALACTICUS_ROOT_V094'}) ? $ENV{'GALACTICUS_ROOT_V094'}.'/perl' : cwd().'/perl';

# Determine the size of an executable file and store the results to a given file.
# Andrew Benson (08-August-2016)

die('Usage: executableSize.pl <executableName> <sizeFileName>')
    unless ( scalar(@ARGV) == 2 );
my $executableName = $ARGV[0];
my $sizeFileName   = $ARGV[1];

# Simply run the "size" command and redirect output to the given file.
system("size ".$executableName." > ".$sizeFileName);

exit;