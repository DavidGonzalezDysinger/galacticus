!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
!!           2019, 2020
!!    Andrew Benson <abenson@carnegiescience.edu>
!!
!! This file is part of Galacticus.
!!
!!    Galacticus is free software: you can redistribute it and/or modify
!!    it under the terms of the GNU General Public License as published by
!!    the Free Software Foundation, either version 3 of the License, or
!!    (at your option) any later version.
!!
!!    Galacticus is distributed in the hope that it will be useful,
!!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!    GNU General Public License for more details.
!!
!!    You should have received a copy of the GNU General Public License
!!    along with Galacticus.  If not, see <http://www.gnu.org/licenses/>.

program Tests_Kepler_Orbits
  !% Tests for orbital parameter conversions.
  use :: Galacticus_Display          , only : Galacticus_Verbosity_Level_Set , verbosityStandard
  use :: ISO_Varying_String          , only : varying_string                 , assignment(=)
  use :: Input_Parameters            , only : inputParameters
  use :: Kepler_Orbits               , only : keplerOrbit
  use :: Numerical_Constants_Astronomical, only : gravitationalConstantGalacticus
  use :: Unit_Tests                  , only : Assert                         , Unit_Tests_Begin_Group, Unit_Tests_End_Group, Unit_Tests_Finish, &
          &                                   compareEquals
  implicit none
  type            (varying_string ) :: parameterFile
  type            (keplerOrbit    ) :: thisOrbit
  double precision                  :: valueActual  , valueExpected, velocityScale
  type            (inputParameters) :: parameters

  ! Set verbosity level.
  call Galacticus_Verbosity_Level_Set(verbosityStandard)
  ! Begin unit tests.
  call Unit_Tests_Begin_Group("Orbital parameter conversions")

  ! Open the parameter file.
  parameterFile='parameters.xml'
  parameters=inputParameters(parameterFile)
  call parameters%markGlobal()

  ! Compute velocity scale for unit mass and radius.
  velocityScale=sqrt(gravitationalConstantGalacticus)

  ! Create a circular orbit.
  call thisOrbit%reset()
  call thisOrbit%velocityRadialSet    (0.0d0*velocityScale)
  call thisOrbit%velocityTangentialSet(1.0d0*velocityScale)
  call thisOrbit%radiusSet            (1.0d0              )
  call thisOrbit%massesSet            (0.0d0,1.0d0        )

  ! Check values are computed correctly.
  valueActual  =thisOrbit%energy         ()
  valueExpected=-0.50d0*velocityScale**2 ! Energy of a circular orbit at the virial radius.
  call Assert('Energy of circular orbit'          ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%angularMomentum()
  valueExpected=velocityScale ! Angular momentum of a circular orbit at the virial radius.
  call Assert('Angular momentum of circular orbit',valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%eccentricity   ()
  valueExpected=0.0d0
  call Assert('Eccentricity of circular orbit'    ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%semiMajorAxis  ()
  valueExpected=1.0d0
  call Assert('Semi-major axis of circular orbit' ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)

  ! Create an elliptical orbit.
  call thisOrbit%reset()
  call thisOrbit%velocityRadialSet    (0.5d0*velocityScale)
  call thisOrbit%velocityTangentialSet(0.5d0*velocityScale)
  call thisOrbit%radiusSet            (1.0d0      )
  call thisOrbit%massesSet            (0.0d0,1.0d0)

  ! Check values are computed correctly.
  valueActual  =thisOrbit%energy         ()
  valueExpected=-0.750d0*velocityScale**2
  call Assert('Energy of elliptical orbit'          ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%angularMomentum()
  valueExpected=0.5d0*velocityScale
  call Assert('Angular momentum of elliptical orbit',valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%eccentricity   ()
  valueExpected=sqrt(5.0d0/8.0d0)
  call Assert('Eccentricity of elliptical orbit'    ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%semiMajorAxis  ()
  valueExpected=(2.0d0/3.0d0)
  call Assert('Semi-major axis of elliptical orbit' ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)

  ! Create a circular orbit with equal mass satellite and host.
  call thisOrbit%reset()
  call thisOrbit%velocityRadialSet    (0.0d0*velocityScale)
  call thisOrbit%velocityTangentialSet(1.0d0*velocityScale)
  call thisOrbit%radiusSet            (1.0d0              )
  call thisOrbit%massesSet            (1.0d0,1.0d0        )

  ! Check values are computed correctly.
  valueActual  =thisOrbit%energy         ()
  valueExpected=-0.75d0*velocityScale**2 ! Energy of a circular orbit at the virial radius.
  call Assert('Energy of "circular" orbit with equal mass objects'          ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%angularMomentum()
  valueExpected=0.5d0*velocityScale ! Angular momentum of a circular orbit at the virial radius.
  call Assert('Angular momentum of "circular" orbit with equal mass objects',valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%eccentricity   ()
  valueExpected=0.5d0
  call Assert('Eccentricity of "circular" orbit with equal mass objects'    ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%semiMajorAxis  ()
  valueExpected=2.0d0/3.0d0
  call Assert('Semi-major axis of "circular" orbit with equal mass objects' ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)

  ! Create a circular orbit, specifying eccentricity, radius and periapsis.
  call thisOrbit%reset()
  call thisOrbit%eccentricitySet    (0.0d0      )
  call thisOrbit%radiusPericenterSet(1.0d0      )
  call thisOrbit%radiusSet          (1.0d0      )
  call thisOrbit%massesSet          (0.0d0,1.0d0)

  ! Check values are computed correctly.
  valueActual  =thisOrbit%energy            ()
  valueExpected=-0.50d0*velocityScale**2 ! Energy of a circular orbit at the virial radius.
  call Assert('Energy of circular orbit'             ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%angularMomentum   ()
  valueExpected=velocityScale ! Angular momentum of a circular orbit at the virial radius.
  call Assert('Angular momentum of circular orbit'   ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%velocityRadial    ()
  valueExpected=0.0d0
  call Assert('Radial velocity of circular orbit'    ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%velocityTangential()
  valueExpected=velocityScale
  call Assert('Tangential velocity of circular orbit',valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)
  valueActual  =thisOrbit%semiMajorAxis     ()
  valueExpected=1.0d0
  call Assert('Semi-major axis of circular orbit'    ,valueActual,valueExpected,compare=compareEquals,relTol=1.0d-6)

  ! End unit tests.
  call Unit_Tests_End_Group()
  call Unit_Tests_Finish()

end program Tests_Kepler_Orbits
