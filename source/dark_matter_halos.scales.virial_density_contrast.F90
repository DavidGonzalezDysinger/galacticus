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

  !% An implementation of dark matter halo scales based on virial density contrast.

  use :: Cosmology_Functions    , only : cosmologyFunctionsClass
  use :: Cosmology_Parameters   , only : cosmologyParametersClass
  use :: Kind_Numbers           , only : kind_int8
  use :: Tables                 , only : table1DLogarithmicLinear
  use :: Virial_Density_Contrast, only : virialDensityContrastClass

  !# <darkMatterHaloScale name="darkMatterHaloScaleVirialDensityContrastDefinition" recursive="yes">
  !#  <description>Dark matter halo scales derived from virial density contrasts.</description>
  !# </darkMatterHaloScale>
  type, extends(darkMatterHaloScaleClass) :: darkMatterHaloScaleVirialDensityContrastDefinition
     !% A dark matter halo scale contrast class using virial density contrasts.
     private
     logical                                                                       :: isRecursive                         , parentDeferred
     class           (darkMatterHaloScaleVirialDensityContrastDefinition), pointer :: recursiveSelf              => null()
     class           (cosmologyParametersClass                          ), pointer :: cosmologyParameters_       => null()
     class           (cosmologyFunctionsClass                           ), pointer :: cosmologyFunctions_        => null()
     class           (virialDensityContrastClass                        ), pointer :: virialDensityContrast_     => null()
     ! Record of unique ID of node which we last computed results for.
     integer         (kind=kind_int8                                    )          :: lastUniqueID
     ! Record of whether or not halo scales have already been computed for this node.
     logical                                                                       :: dynamicalTimescaleComputed          , virialRadiusComputed            , &
          &                                                                           virialTemperatureComputed           , virialVelocityComputed
     ! Stored values of halo scales.
     double precision                                                              :: dynamicalTimescaleStored            , virialRadiusStored              , &
          &                                                                           virialTemperatureStored             , virialVelocityStored            , &
          &                                                                           timePrevious                        , densityGrowthRatePrevious       , &
          &                                                                           massPrevious
     ! Table for fast lookup of the mean density of halos.
     double precision                                                              :: meanDensityTimeMaximum              , meanDensityTimeMinimum   =-1.0d0
     type            (table1DLogarithmicLinear                          )          :: meanDensityTable
   contains
     !# <methods>
     !#   <method description="Reset memoized calculations." method="calculationReset" />
     !# </methods>
     final     ::                                        virialDensityContrastDefinitionDestructor
     procedure :: autoHook                            => virialDensityContrastDefinitionAutoHook
     procedure :: calculationReset                    => virialDensityContrastDefinitionCalculationReset
     procedure :: dynamicalTimescale                  => virialDensityContrastDefinitionDynamicalTimescale
     procedure :: virialVelocity                      => virialDensityContrastDefinitionVirialVelocity
     procedure :: virialVelocityGrowthRate            => virialDensityContrastDefinitionVirialVelocityGrowthRate
     procedure :: virialTemperature                   => virialDensityContrastDefinitionVirialTemperature
     procedure :: virialRadius                        => virialDensityContrastDefinitionVirialRadius
     procedure :: virialRadiusGradientLogarithmicMass => virialDensityContrastDefinitionVirialRadiusGradientLogMass
     procedure :: virialRadiusGrowthRate              => virialDensityContrastDefinitionVirialRadiusGrowthRate
     procedure :: meanDensity                         => virialDensityContrastDefinitionMeanDensity
     procedure :: meanDensityGrowthRate               => virialDensityContrastDefinitionMeanDensityGrowthRate
     procedure :: deepCopy                            => virialDensityContrastDefinitionDeepCopy
  end type darkMatterHaloScaleVirialDensityContrastDefinition

  interface darkMatterHaloScaleVirialDensityContrastDefinition
     !% Constructors for the {\normalfont \ttfamily virialDensityContrastDefinition} dark matter halo scales class.
     module procedure virialDensityContrastDefinitionParameters
     module procedure virialDensityContrastDefinitionInternal
  end interface darkMatterHaloScaleVirialDensityContrastDefinition

  integer, parameter :: virialDensityContrastDefinitionMeanDensityTablePointsPerDecade=100

contains

  recursive function virialDensityContrastDefinitionParameters(parameters,recursiveConstruct,recursiveSelf) result(self)
    !% Constructor for the {\normalfont \ttfamily virialDensityContrastDefinition} dark matter halo scales class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type   (darkMatterHaloScaleVirialDensityContrastDefinition), target                  :: self
    type   (inputParameters                                   ), intent(inout)           :: parameters
    logical                                                    , intent(in   ), optional :: recursiveConstruct
    class  (darkMatterHaloScaleClass                          ), intent(in   ), optional :: recursiveSelf
    class  (cosmologyParametersClass                          ), pointer                 :: cosmologyParameters_
    class  (cosmologyFunctionsClass                           ), pointer                 :: cosmologyFunctions_
    class  (virialDensityContrastClass                        ), pointer                 :: virialDensityContrast_

    !# <objectBuilder class="cosmologyParameters"   name="cosmologyParameters_"   source="parameters"/>
    !# <objectBuilder class="cosmologyFunctions"    name="cosmologyFunctions_"    source="parameters"/>
    !# <objectBuilder class="virialDensityContrast" name="virialDensityContrast_" source="parameters"/>
    self=darkMatterHaloScaleVirialDensityContrastDefinition(cosmologyParameters_,cosmologyFunctions_,virialDensityContrast_,recursiveConstruct,recursiveSelf)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="cosmologyParameters_"  />
    !# <objectDestructor name="cosmologyFunctions_"   />
    !# <objectDestructor name="virialDensityContrast_"/>
    return
  end function virialDensityContrastDefinitionParameters

  recursive function virialDensityContrastDefinitionInternal(cosmologyParameters_,cosmologyFunctions_,virialDensityContrast_,recursiveConstruct,recursiveSelf) result(self)
    !% Default constructor for the {\normalfont \ttfamily virialDensityContrastDefinition} dark matter halo scales class.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    type   (darkMatterHaloScaleVirialDensityContrastDefinition)                                  :: self
    class  (cosmologyParametersClass                          ), intent(in   ), target           :: cosmologyParameters_
    class  (cosmologyFunctionsClass                           ), intent(in   ), target           :: cosmologyFunctions_
    class  (virialDensityContrastClass                        ), intent(in   ), target           :: virialDensityContrast_
    logical                                                    , intent(in   )        , optional :: recursiveConstruct
    class  (darkMatterHaloScaleClass                          ), intent(in   ), target, optional :: recursiveSelf
    !# <optionalArgument name="recursiveConstruct" defaultsTo=".false." />
    !# <constructorAssign variables="*cosmologyParameters_, *cosmologyFunctions_, *virialDensityContrast_"/>

    self%lastUniqueID              =-1_kind_int8
    self%dynamicalTimescaleComputed=.false.
    self%virialRadiusComputed      =.false.
    self%virialTemperatureComputed =.false.
    self%virialVelocityComputed    =.false.
    self%meanDensityTimeMaximum    =-1.0d0
    self%meanDensityTimeMinimum    =-1.0d0
    self%timePrevious              =-1.0d0
    self%massPrevious              =-1.0d0
    self%isRecursive               =recursiveConstruct_
    if (recursiveConstruct_) then
       if (.not.present(recursiveSelf)) call Galacticus_Error_Report('recursiveSelf not present'//{introspection:location})
       select type (recursiveSelf)
       class is (darkMatterHaloScaleVirialDensityContrastDefinition)
          self%recursiveSelf => recursiveSelf
       class default
          call Galacticus_Error_Report('recursiveSelf is of incorrect class'//{introspection:location})
       end select
    end if
    self%parentDeferred=.false.
    return
  end function virialDensityContrastDefinitionInternal

  subroutine virialDensityContrastDefinitionAutoHook(self)
    !% Attach to the calculation reset event.
    use :: Events_Hooks, only : calculationResetEvent, openMPThreadBindingAllLevels
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self

    call calculationResetEvent%attach(self,virialDensityContrastDefinitionCalculationReset,openMPThreadBindingAllLevels)
    return
  end subroutine virialDensityContrastDefinitionAutoHook

  subroutine virialDensityContrastDefinitionDestructor(self)
    !% Destructir for the {\normalfont \ttfamily virialDensityContrastDefinition} dark matter halo scales class.
    use :: Events_Hooks, only : calculationResetEvent
    implicit none
    type (darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyParameters_"  />
    !# <objectDestructor name="self%cosmologyFunctions_"   />
    !# <objectDestructor name="self%virialDensityContrast_"/>
    if (self%meanDensityTimeMinimum >= 0.0d0) call self%meanDensityTable%destroy()
    call calculationResetEvent%detach(self,virialDensityContrastDefinitionCalculationReset)
    return
  end subroutine virialDensityContrastDefinitionDestructor

  subroutine virialDensityContrastDefinitionCalculationReset(self,node)
    !% Reset the halo scales calculation.
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node

    self%virialRadiusComputed      =.false.
    self%virialTemperatureComputed =.false.
    self%virialVelocityComputed    =.false.
    self%dynamicalTimescaleComputed=.false.
    self%lastUniqueID              =node%uniqueID()
    return
  end subroutine virialDensityContrastDefinitionCalculationReset

  double precision function virialDensityContrastDefinitionDynamicalTimescale(self,node)
    !% Returns the dynamical timescale for {\normalfont \ttfamily node}.
    use :: Numerical_Constants_Astronomical, only : gigaYear, megaParsec
    use :: Numerical_Constants_Prefixes    , only : kilo
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionDynamicalTimescale=self%recursiveSelf%dynamicalTimescale(node)
       return
    end if
    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Check if halo dynamical timescale is already computed. Compute and store if not.
    if (.not.self%dynamicalTimescaleComputed) then
       self%dynamicalTimescaleComputed= .true.
       self%dynamicalTimescaleStored  = self%virialRadius  (node) &
            &                          /self%virialVelocity(node) &
            &                          *(megaParsec/kilo/gigaYear)
     end if
    ! Return the stored timescale.
    virialDensityContrastDefinitionDynamicalTimescale=self%dynamicalTimescaleStored
    return
  end function virialDensityContrastDefinitionDynamicalTimescale

  double precision function virialDensityContrastDefinitionVirialVelocity(self,node)
    !% Returns the virial velocity scale for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes            , only : nodeComponentBasic             , treeNode
    use :: Numerical_Constants_Astronomical, only : gravitationalConstantGalacticus
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node
    class(nodeComponentBasic                                ), pointer       :: basic

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialVelocity=self%recursiveSelf%virialVelocity(node)
       return
    end if
    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Check if virial velocity is already computed. Compute and store if not.
    if (.not.self%virialVelocityComputed) then
       ! Get the basic component.
       basic => node%basic()
       ! Compute the virial velocity.
       self%virialVelocityStored=sqrt(gravitationalConstantGalacticus*basic%mass() &
            &/self%virialRadius(node))
       ! Record that virial velocity has now been computed.
       self%virialVelocityComputed=.true.
    end if
    ! Return the stored virial velocity.
    virialDensityContrastDefinitionVirialVelocity=self%virialVelocityStored
    return
  end function virialDensityContrastDefinitionVirialVelocity

  double precision function virialDensityContrastDefinitionVirialVelocityGrowthRate(self,node)
    !% Returns the growth rate of the virial velocity scale for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node
    class(nodeComponentBasic                                ), pointer       :: basic

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialVelocityGrowthRate=self%recursiveSelf%virialVelocityGrowthRate(node)
       return
    end if
    ! Get the basic component.
    basic => node%basic()
    virialDensityContrastDefinitionVirialVelocityGrowthRate= &
         & +0.5d0                                            &
         & *  self%virialVelocity        (node)              &
         & *(                                                &
         &    basic%accretionRate        (    )              &
         &   /basic%mass                 (    )              &
         &   -self%virialRadiusGrowthRate(node)              &
         &   /self%virialRadius          (node)              &
         &  )
    return
  end function virialDensityContrastDefinitionVirialVelocityGrowthRate

  double precision function virialDensityContrastDefinitionVirialTemperature(self,node)
    !% Returns the virial temperature (in Kelvin) for {\normalfont \ttfamily node}.
    use :: Numerical_Constants_Astronomical, only : meanAtomicMassPrimordial
    use :: Numerical_Constants_Atomic      , only : atomicMassUnit
    use :: Numerical_Constants_Physical    , only : boltzmannsConstant
    use :: Numerical_Constants_Prefixes    , only : kilo
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialTemperature=self%recursiveSelf%virialTemperature(node)
       return
    end if
    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Check if virial temperature is already computed. Compute and store if not.
    if (.not.self%virialTemperatureComputed) then
       self%virialTemperatureComputed=.true.
       self%virialTemperatureStored=0.5d0*atomicMassUnit*meanAtomicMassPrimordial*((kilo&
            &*self%virialVelocity(node))**2)/boltzmannsConstant
    end if
    ! Return the stored temperature.
    virialDensityContrastDefinitionVirialTemperature=self%virialTemperatureStored
    return
  end function virialDensityContrastDefinitionVirialTemperature

  double precision function virialDensityContrastDefinitionVirialRadius(self,node)
    !% Returns the virial radius scale for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes        , only : nodeComponentBasic, treeNode
    use :: Math_Exponentiation     , only : cubeRoot
    use :: Numerical_Constants_Math, only : Pi
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node
    class(nodeComponentBasic                                ), pointer       :: basic

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialRadius=self%recursiveSelf%virialRadius(node)
       return
    end if
    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Check if virial radius is already computed. Compute and store if not.
    if (.not.self%virialRadiusComputed) then
       ! Get the basic component.
       basic => node%basic()
       ! Compute the virial radius.
       self%virialRadiusStored=cubeRoot(3.0d0*basic%mass()/4.0d0/Pi/self%meanDensity(node))
       ! Record that the virial radius has been computed.
       self%virialRadiusComputed=.true.
    end if
    ! Return the stored value.
    virialDensityContrastDefinitionVirialRadius=self%virialRadiusStored
    return
  end function virialDensityContrastDefinitionVirialRadius

  double precision function virialDensityContrastDefinitionVirialRadiusGradientLogMass(self,node)
    !% Returns the logarithmic gradient of virial radius with halo mass at fixed epoch for {\normalfont \ttfamily node}.
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node
    !$GLC attributes unused :: self, node

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialRadiusGradientLogMass=self%recursiveSelf%virialRadiusGradientLogarithmicMass(node)
       return
    end if
    ! Halos at given epoch have fixed density, so radius always grows as the cube-root of mass.
    virialDensityContrastDefinitionVirialRadiusGradientLogMass=1.0d0/3.0d0
    return
  end function virialDensityContrastDefinitionVirialRadiusGradientLogMass

  double precision function virialDensityContrastDefinitionVirialRadiusGrowthRate(self,node)
    !% Returns the growth rate of the virial radius scale for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type (treeNode                                          ), intent(inout) :: node
    class(nodeComponentBasic)                                , pointer       :: basic

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionVirialRadiusGrowthRate=self%recursiveSelf%virialRadiusGrowthRate(node)
       return
    end if
    ! Get the basic component.
    basic => node%basic()
    virialDensityContrastDefinitionVirialRadiusGrowthRate=(1.0d0/3.0d0)*self%virialRadius(node)&
         &*(basic%accretionRate()/basic%mass()-self%meanDensityGrowthRate(node)&
         &/virialDensityContrastDefinitionMeanDensity(self,node))
    return
  end function virialDensityContrastDefinitionVirialRadiusGrowthRate

  double precision function virialDensityContrastDefinitionMeanDensity(self,node)
    !% Returns the mean density for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type            (treeNode                                          ), intent(inout) :: node
    class           (nodeComponentBasic                                ), pointer       :: basic
    integer                                                                             :: i    , meanDensityTablePoints
    double precision                                                                    :: time

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionMeanDensity=self%recursiveSelf%meanDensity(node)
       return
    end if
    ! Get the basic component.
    basic => node%basic()
    ! Get the time at which this halo was last an isolated halo.
    time=basic%timeLastIsolated()
    if (time <= 0.0d0) time=basic%time()
    ! For mass-dependent virial density contrasts we must always recompute the result.
    if (self%virialDensityContrast_%isMassDependent()) then
       ! Get default objects.
       virialDensityContrastDefinitionMeanDensity =  +self%virialDensityContrast_%densityContrast(basic%mass(),time)    &
            &                                        *self%cosmologyParameters_  %OmegaMatter    (                 )    &
            &                                        *self%cosmologyParameters_  %densityCritical(                 )    &
            &                                        /self%cosmologyFunctions_   %expansionFactor(             time)**3
    else
       ! For non-mass-dependent virial density contrasts we can tabulate as a function of time.
       ! Retabulate the mean density vs. time if necessary.
       if (time < self%meanDensityTimeMinimum .or. time > self%meanDensityTimeMaximum) then
          if (self%meanDensityTimeMinimum <= 0.0d0) then
             self%meanDensityTimeMinimum=                                time/10.0d0
             self%meanDensityTimeMaximum=                                time* 2.0d0
          else
             self%meanDensityTimeMinimum=min(self%meanDensityTimeMinimum,time/10.0d0)
             self%meanDensityTimeMaximum=max(self%meanDensityTimeMaximum,time* 2.0d0)
          end if
          meanDensityTablePoints=int(log10(self%meanDensityTimeMaximum/self%meanDensityTimeMinimum)*dble(virialDensityContrastDefinitionMeanDensityTablePointsPerDecade))+1
          call self%meanDensityTable%destroy()
          call self%meanDensityTable%create(self%meanDensityTimeMinimum,self%meanDensityTimeMaximum,meanDensityTablePoints)
          do i=1,meanDensityTablePoints
             call self%meanDensityTable%populate                                                               &
                  & (                                                                                          &
                  &  +self%virialDensityContrast_%densityContrast(basic%mass(),self%meanDensityTable%x(i))     &
                  &  *self%cosmologyParameters_  %OmegaMatter    (                                       )     &
                  &  *self%cosmologyParameters_  %densityCritical(                                       )     &
                  &  /self%cosmologyFunctions_   %expansionFactor(             self%meanDensityTable%x(i))**3, &
                  &  i                                                                                         &
                  & )
          end do
       end if
       ! Return the stored value.
       virialDensityContrastDefinitionMeanDensity=self%meanDensityTable%interpolate(time)
    end if
    return
  end function virialDensityContrastDefinitionMeanDensity

  double precision function virialDensityContrastDefinitionMeanDensityGrowthRate(self,node)
    !% Returns the growth rate of the mean density for {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    type            (treeNode                                          ), intent(inout) :: node
    class           (nodeComponentBasic                                ), pointer       :: basic
    double precision                                                                    :: expansionFactor, time

    ! Use recursive self if necessary.
    if (self%isRecursive) then
       call virialDensityContrastFindParent(self)
       virialDensityContrastDefinitionMeanDensityGrowthRate=self%recursiveSelf%meanDensityGrowthRate(node)
       return
    end if
    if (node%isSatellite()) then
       ! Satellite halo is not growing, return zero rate.
       virialDensityContrastDefinitionMeanDensityGrowthRate=0.0d0
    else
       ! Get the basic component.
       basic => node%basic()
       ! Get the time at which this halo was last an isolated halo.
       time=basic%timeLastIsolated()
       ! Check if the time is different from that one previously used.
       if (time /= self%timePrevious .or. basic%mass() /= self%massPrevious) then
          ! It is not, so recompute the density growth rate.
          self%timePrevious=time
          self%massPrevious=basic%mass()
          ! Get the expansion factor at this time.
          expansionFactor=self%cosmologyFunctions_%expansionFactor(time)
          ! Compute growth rate of its mean density based on mean cosmological density and overdensity of a collapsing halo.
          self%densityGrowthRatePrevious=                                                                 &
               & self%meanDensity(node)                                                                   &
               & *(                                                                                       &
               &   +self%virialDensityContrast_%densityContrastRateOfChange(basic%mass(),time           ) &
               &   /self%virialDensityContrast_%densityContrast            (basic%mass(),time           ) &
               &   -3.0d0                                                                                 &
               &   *self%cosmologyFunctions_   %expansionRate              (             expansionFactor) &
               &  )
       end if
       ! Return the stored value.
       virialDensityContrastDefinitionMeanDensityGrowthRate=self%densityGrowthRatePrevious
    end if
    return
  end function virialDensityContrastDefinitionMeanDensityGrowthRate

  subroutine virialDensityContrastDefinitionDeepCopy(self,destination)
    !% Perform a deep copy of the object.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self
    class(darkMatterHaloScaleClass                          ), intent(inout) :: destination

    call self%darkMatterHaloScaleClass%deepCopy(destination)
    select type (destination)
    type is (darkMatterHaloScaleVirialDensityContrastDefinition)
       destination%isRecursive               =self%isRecursive
       destination%lastUniqueID              =self%lastUniqueID
       destination%dynamicalTimescaleComputed=self%dynamicalTimescaleComputed
       destination%virialRadiusComputed      =self%virialRadiusComputed
       destination%virialTemperatureComputed =self%virialTemperatureComputed
       destination%virialVelocityComputed    =self%virialVelocityComputed
       destination%dynamicalTimescaleStored  =self%dynamicalTimescaleStored
       destination%virialRadiusStored        =self%virialRadiusStored
       destination%virialTemperatureStored   =self%virialTemperatureStored
       destination%virialVelocityStored      =self%virialVelocityStored
       destination%timePrevious              =self%timePrevious
       destination%densityGrowthRatePrevious =self%densityGrowthRatePrevious
       destination%massPrevious              =self%massPrevious
       destination%meanDensityTimeMaximum    =self%meanDensityTimeMaximum
       destination%meanDensityTimeMinimum    =self%meanDensityTimeMinimum
       destination%meanDensityTable          =self%meanDensityTable
       destination%parentDeferred            =.false.
       if (self%isRecursive) then
          if (associated(self%recursiveSelf%recursiveSelf)) then
             ! If the parent self's recursiveSelf pointer is set, it indicates that it was deep-copied, and the pointer points to
             ! that copy. In that case we set the parent self of our destination to that copy.
             destination%recursiveSelf  => self%recursiveSelf%recursiveSelf
          else
             ! The parent self does not appear to have been deep-copied yet. Retain the same parent self pointer in our copy, but
             ! indicate that we need to look for the new parent later.
             destination%recursiveSelf  => self%recursiveSelf
             destination%parentDeferred =  .true.
          end if
       else
          ! This is a parent of a recursively-constructed object. Record the location of our copy so that it can be used to set
          ! the parent in deep copies of the child object.
          call virialDensityContrastDefinitionDeepCopyAssign(self,destination)
          destination%recursiveSelf     => null()
       end if       
       if (associated(self%cosmologyParameters_)) then
          if (associated(self%cosmologyParameters_%copiedSelf)) then
             select type(s => self%cosmologyParameters_%copiedSelf)
                class is (cosmologyParametersClass)
                destination%cosmologyParameters_ => s
                class default
                call Galacticus_Error_Report('copiedSelf has incorrect type'//{introspection:location})
             end select
             call self%cosmologyParameters_%copiedSelf%referenceCountIncrement()
          else
             allocate(destination%cosmologyParameters_,mold=self%cosmologyParameters_)
             call self%cosmologyParameters_%deepCopy(destination%cosmologyParameters_)
             self%cosmologyParameters_%copiedSelf => destination%cosmologyParameters_
             call destination%cosmologyParameters_%autoHook()
          end if
       end if
       if (associated(self%cosmologyFunctions_)) then
          if (associated(self%cosmologyFunctions_%copiedSelf)) then
             select type(s => self%cosmologyFunctions_%copiedSelf)
                class is (cosmologyFunctionsClass)
                destination%cosmologyFunctions_ => s
                class default
                call Galacticus_Error_Report('copiedSelf has incorrect type'//{introspection:location})
             end select
             call self%cosmologyFunctions_%copiedSelf%referenceCountIncrement()
          else
             allocate(destination%cosmologyFunctions_,mold=self%cosmologyFunctions_)
             call self%cosmologyFunctions_%deepCopy(destination%cosmologyFunctions_)
             self%cosmologyFunctions_%copiedSelf => destination%cosmologyFunctions_
             call destination%cosmologyFunctions_%autoHook()
          end if
       end if
       if (associated(self%virialDensityContrast_)) then
          if (associated(self%virialDensityContrast_%copiedSelf)) then
             select type(s => self%virialDensityContrast_%copiedSelf)
                class is (virialDensityContrastClass)
                destination%virialDensityContrast_ => s
                class default
                call Galacticus_Error_Report('copiedSelf has incorrect type'//{introspection:location})
             end select
             call self%virialDensityContrast_%copiedSelf%referenceCountIncrement()
          else
             allocate(destination%virialDensityContrast_,mold=self%virialDensityContrast_)
             call self%virialDensityContrast_%deepCopy(destination%virialDensityContrast_)
             self%virialDensityContrast_%copiedSelf => destination%virialDensityContrast_
             call destination%virialDensityContrast_%autoHook()
          end if
       end if
       call destination%meanDensityTable%deepCopyActions()
    class default
       call Galacticus_Error_Report('destination and source types do not match'//{introspection:location})
    end select
    return
  end subroutine virialDensityContrastDefinitionDeepCopy

  subroutine virialDensityContrastDefinitionDeepCopyAssign(self,destination)
    !% Perform pointer assignment during a deep copy of the object.
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout)         :: self
    class(darkMatterHaloScaleClass                          ), intent(inout), target :: destination

    select type (destination)
    type is (darkMatterHaloScaleVirialDensityContrastDefinition)
       self%recursiveSelf => destination
    end select
    return
  end subroutine virialDensityContrastDefinitionDeepCopyAssign

  subroutine virialDensityContrastFindParent(self)
    !% Find the deep-copied parent of a recursive child.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class(darkMatterHaloScaleVirialDensityContrastDefinition), intent(inout) :: self

    if (self%parentDeferred) then
       if (associated(self%recursiveSelf%recursiveSelf)) then
          self%recursiveSelf => self%recursiveSelf%recursiveSelf
       else
          call Galacticus_Error_Report("recursive child's parent was not copied"//{introspection:location})
       end if
       self%parentDeferred=.false.
    end if
    return
  end subroutine virialDensityContrastFindParent
