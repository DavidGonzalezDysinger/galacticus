# Contains a Perl module which implements source code introspection.

package SourceIntrospection;
use strict;
use warnings;
my $galacticusPath;
if ( exists($ENV{"GALACTICUS_ROOT_V094"}) ) {
 $galacticusPath = $ENV{"GALACTICUS_ROOT_V094"};
 $galacticusPath .= "/" unless ( $galacticusPath =~ m/\/$/ );
} else {
 $galacticusPath = "./";
}
unshift(@INC, $galacticusPath."perl"); 
use File::Slurp qw(slurp);
use Data::Dumper;
use XML::Simple;
require Galacticus::Build::SourceTree::Hooks;
require Galacticus::Build::SourceTree;

# Insert hooks for our functions.
$Hooks::processHooks{'sourceIntrospection'} = \&Process_Source_Introspection;

sub ReadFile {
    # Read a file and add instrumentation to assist in source introspection.
    my $fileName = shift();
    my $code;
    my $lineNumber = 0;
    open(my $sourceFile,$fileName);
    while ( my $line = <$sourceFile> ) {
	++$lineNumber;
	if ( $line =~ m/\{introspection:location\}/ ) {
	    $line =~ s/\{introspection:location\}/{introspection:location:$lineNumber}/g;
	}
	$code .= $line;
    }
    return $code;
}

sub Process_Source_Introspection {
    # Get the tree.
    my $tree = shift();
    # Walk the tree.
    my $node  = $tree;
    my $depth = 0;    
    while ( $node ) {
	if ( $node->{'type'} eq "code" ) {
	    my $newCode;
	    open(my $code,"<",\$node->{'content'});
	    while ( my $line = <$code> ) {
		if ( $line =~ m/\{introspection:location:(\d+)\}/ ) {
		    my $lineNumber = $1;
		    my $location   = "char(10)//' Occurred at:'";
		    my $branch     = $node;
		    while ( $branch ) {
			if (
			    $branch->{'type'} eq "file"
			    ||
			    $branch->{'type'} eq "module"
			    ||
			    $branch->{'type'} eq "function"
			    ||
			    $branch->{'type'} eq "subroutine"
			    ) {
			    $location .= "//char(10)//'   ".(" " x (10-length($branch->{'type'}))).$branch->{'type'}.":".$branch->{'name'}."'";			    
			}
			$branch = $branch->{'parent'};
		    }
		    $location .= "//' [line ".$lineNumber."]'";
		    $line =~ s/\{introspection:location:\d+\}/$location/g;
		}
		$newCode .= $line;
	    }
	    close($code);				    
	    $node->{'content'} = $newCode;	    
	}
	# Move on to the next node.
	$node = &SourceTree::Walk_Tree($node,\$depth);
    }
}

1;