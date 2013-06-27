#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

# Run a set of short Galacticus models which test cases that have failed before,
# in order to catch regressions.
# Andrew Benson (01-Feb-2011)

# Clean up any automatically generated files.
# Noninstantaneous recycling files (older than 14 days).
system("find data/stellarPopulations -name '".$_."' -atime +14 -exec rm {} \;")
    foreach ( "Stellar_*_Yield_*_*.xml", "Stellar_Recycled_Fraction_*_*.xml", "Stellar_Energy_Input_*_*.xml" );

# Find all regression parameter files and run them.
my $outputDirectory = "outputs/regressions";
system("mkdir -p ".$outputDirectory);
my @regressionDirs = ( "regressions" );
find(\&runRegressions,@regressionDirs);

exit;

sub runRegressions {
    # Run a regression case.
    my $fileName = $_;
    chomp($fileName);

    # Test if this is a parameter fil to run.
    if ( $fileName =~ m/\.xml$/ ) {
	print "\n\n:--> Running regression test case: ".$fileName."\n";
	system("cd ../..; Galacticus.exe testSuite/".$File::Find::dir."/".$fileName);       
	print "FAILED: regression test case: ".$fileName."\n" unless ( $? == 0 );
    }

    # Test if this is a script to run.
    if ( $fileName =~ m/\.pl$/ ) {
	print "\n\n:--> Running regression test case: ".$fileName."\n";
	system("cd ../..; testSuite/".$File::Find::dir."/".$fileName);       
	print "FAILED: regression test case: ".$fileName."\n" unless ( $? == 0 );
    }
}
