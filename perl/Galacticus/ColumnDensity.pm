# Calculate column density of hydrogen in cm^{-2} to the center of each galaxy.

package ColumnDensity;
use strict;
use warnings;
use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use PDL::GSLSF::PSI;
use PDL::Math;
require Galacticus::HDF5;
require Galacticus::Inclination;

%HDF5::galacticusFunctions = 
    (
     %HDF5::galacticusFunctions,
     "columnDensity(Disk|Spheroid)??\$" => \&ColumnDensity::Get_Column_Density
    );

sub Get_Column_Density {
    my $model       = shift;
    my $dataSetName = $_[0];
    # Define constants.
    my $massHydrogen = pdl 1.67262158000e-27; # kg
    my $massSolar    = pdl 1.98892000000e+30; # kg
    my $megaParsec   = pdl 3.08568024000e+22; # m
    my $hecto        = pdl 1.00000000000e+02;

    # Determine which components are needed.
    my $includeDisk     = 0;
    my $includeSpheroid = 0;
    $includeDisk     = 1
	if ( $dataSetName eq "columnDensity" || $dataSetName eq "columnDensityDisk"     );
    $includeSpheroid = 1
	if ( $dataSetName eq "columnDensity" || $dataSetName eq "columnDensitySpheroid" );

    # Ensure that we have all of the datasets that we need.
    my @requiredDatasets = ( 'nodeIndex' );
    push(@requiredDatasets,'diskScaleLength','diskGasMass','inclination')
	if ( $includeDisk     == 1 );
    push(@requiredDatasets,'spheroidGasMass', 'spheroidScaleLength')
	if ( $includeSpheroid == 1 );
    &HDF5::Get_Dataset($model,\@requiredDatasets);
    my $dataSets = $model->{'dataSets'};
    # Compute spheroid column density if necessary.
    my $sigmaSpheroid = pdl zeroes(nelem($dataSets->{'nodeIndex'}));
    if ( $includeSpheroid == 1 ) {
	# Compute central density of spheroid component.
	my $spheroidGasMass        = $dataSets->{'spheroidGasMass'    };
	my $spheroidScaleLength    = $dataSets->{'spheroidScaleLength'};
	my $spheroidDensityCentral = $spheroidGasMass/(2.0*PI*$spheroidScaleLength**3);
	# Using 0.1*(scale length) for inner spheroid cutoff
	my $spheroidRadiusMinimum              = 0.1*$spheroidScaleLength;
	my $spheroidRadiusMinimumDimensionless = $spheroidRadiusMinimum/$spheroidScaleLength;
	# Compute column density to center of spheroid.
	$sigmaSpheroid                        .=
	    0.5
	    *$spheroidDensityCentral
	    *$spheroidScaleLength
	    *(
		-$spheroidScaleLength
		*(3.0+2.0*$spheroidRadiusMinimumDimensionless)
		/(2.0*(1.0+$spheroidRadiusMinimumDimensionless)**2)
		+2.0*log(1.0+1.0/$spheroidRadiusMinimumDimensionless)
	    );
	$sigmaSpheroid->where($spheroidScaleLength == 0.0) .= 0.0;
    }
    # Compute disk column density if necessary.
    my $sigmaDisk = pdl zeroes(nelem($dataSets->{'nodeIndex'}));
    if ( $includeDisk == 1 ) {
	# Compute central density of disk component.
	my $diskGasMass        = $dataSets->{'diskGasMass'    };
	my $diskScaleLength    = $dataSets->{'diskScaleLength'};
	my $diskDensityCentral = $diskGasMass/(0.4*PI*$diskScaleLength**3);
	# Compute column density to center of disk.
	my $diskInclination    = ($dataSets->{'inclination'})*(PI/180.0);
	my $tangentInclination = abs(tan($diskInclination));
	my $digamma1           = (gsl_sf_psi($tangentInclination/40.0+0.5))[0];
	my $digamma2           = (gsl_sf_psi($tangentInclination/40.0    ))[0];
	$sigmaDisk            .= 
	    (1.0/200.0)
	    *$diskDensityCentral
	    *$diskScaleLength
	    *sqrt($tangentInclination**2+1.0)
	    *($tangentInclination*($digamma1-$digamma2)-20.0);
	$sigmaDisk->where($diskScaleLength == 0.0) .= 0.0;
    }
    # Evaluate conversion factor from mass column density to hydrogen column density.
    my $hydrogenFactor = (0.76)*$massSolar/($massHydrogen*($megaParsec*$hecto)**2);
    # Compute the column density.
    $dataSets->{$dataSetName} = ($sigmaDisk+$sigmaSpheroid)*$hydrogenFactor;

}

1;

