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

!+ Contributions to this file made by: Daniel McAndrew.

  !% An implementation of accretion from the \gls{igm} onto halos using filtering mass of the \gls{igm}
  !% calculated from an equation from \cite{naoz_formation_2007}.

  use :: Intergalactic_Medium_Filtering_Masses, only : intergalacticMediumFilteringMass, intergalacticMediumFilteringMassClass

  !# <accretionHalo name="accretionHaloNaozBarkana2007">
  !#  <description>
  !#   Accretion of baryonic onto halos is compute using the filtering mass prescription of
  !#   \cite{naoz_formation_2007}. Specifically, \cite{naoz_formation_2007} assume that the gas mass content of halos is given by
  !#   $M_\mathrm{g}(M_\mathrm{200b},M_\mathrm{F}) = (\Omega_\mathrm{b} / \Omega_\mathrm{M}) f(M_\mathrm{200b}/M_\mathrm{F})
  !#   M_\mathrm{200b}$ where $M_\mathrm{F}$ is the filtering mass, as first introduced by \cite{gnedin_effect_2000} but defined
  !#   following \cite{naoz_formation_2007}, $M_\mathrm{200b}$ is the halo mass defined by a density threshold of 200 times the
  !#   mean background, and
  !#   \begin{equation}
  !#     f(x) = [1-(2^{1/3}-1) x^{-1}]^{-3}.
  !#   \end{equation}
  !#   The accretion rate onto the halo is therefore assumed to be
  !#   \begin{equation}
  !#     \dot{M}_\mathrm{g} = {\Omega_\mathrm{b} \over \Omega_\mathrm{M}} {\mathrm{d} \over \mathrm{d} M_\mathrm{200b}} \left[
  !#     f(M_\mathrm{200b}/M_\mathrm{F}) M_\mathrm{200b} \right] \dot{M}_\mathrm{total}.
  !#   \end{equation}
  !#   This would result in a precise match to the \cite{naoz_formation_2007} assumption if:
  !#   \begin{enumerate}
  !#   \item The filtering mass is constant in time;
  !#   \item $M_\mathrm{total}$ corresponds to $M_\mathrm{200b}$; and
  !#   \item The growth of halos occurs through smooth accretion, not through merging of smaller halos.
  !#   \end{enumerate}
  !#   In practice all three assumptions are violated. As such, the mass fraction in the halo will differ from
  !#   $f(M_\mathrm{200b}/M_\mathrm{F})$. To address this issue, mass is additionally assumed to flow from the hot halo reservoir
  !#   to the unaccreted mass reservoir at a rate:
  !#   \begin{equation}
  !#   \dot{M}_\mathrm{hot} = - {\alpha_\mathrm{adjust} \over \tau_\mathrm{dyn}} [M_\mathrm{hot}+M_\mathrm{unaccreted}]
  !#   [f_\mathrm{accreted}-f(M_\mathrm{200b}/M_\mathrm{F})],
  !#   \end{equation}
  !#   where $\alpha_\mathrm{adjust} = $[{\normalfont \ttfamily accretionHaloNaozBarkana2007RateAdjust}].
  !#  </description>
  !# </accretionHalo>
  type, extends(accretionHaloSimple) :: accretionHaloNaozBarkana2007
     !% A halo accretion class using filtering mass of the \gls{igm} calculated from an equation from \cite{naoz_formation_2007}.
     private
     double precision                                                 :: rateAdjust                                 , massMinimum             , &
          &                                                              filteredFractionRateStored                 , filteredFractionStored
     logical                                                          :: filteredFractionRateComputed               , filteredFractionComputed
     integer         (kind=kind_int8                       )          :: lastUniqueID
     class           (intergalacticMediumFilteringMassClass), pointer :: intergalacticMediumFilteringMass_ => null()
   contains
     !# <methods>
     !#   <method description="Reset memoized calculations." method="calculationReset" />
     !#   <method description="Returns the fraction of potential accretion onto a halo from the \gls{igm} which succeeded." method="filteredFraction" />
     !#   <method description="Returns the fraction of potential accretion rate onto a halo from the \gls{igm} which succeeds." method="filteredFractionRate" />
     !#   <method description="Returns the fraction of potential accretion onto a halo from the \gls{igm} which succeeded given the halo and filtering masses." method="filteredFractionCompute" />
     !# </methods>
     final     ::                            naozBarkana2007Destructor
     procedure :: autoHook                => naozBarkana2007AutoHook
     procedure :: calculationReset        => naozBarkana2007CalculationReset
     procedure :: branchHasBaryons        => naozBarkana2007BranchHasBaryons
     procedure :: accretionRate           => naozBarkana2007AccretionRate
     procedure :: accretedMass            => naozBarkana2007AccretedMass
     procedure :: failedAccretionRate     => naozBarkana2007FailedAccretionRate
     procedure :: failedAccretedMass      => naozBarkana2007FailedAccretedMass
     procedure :: filteredFraction        => naozBarkana2007FilteredFraction
     procedure :: filteredFractionRate    => naozBarkana2007FilteredFractionRate
     procedure :: filteredFractionCompute => naozBarkana2007FilteredFractionCompute
  end type accretionHaloNaozBarkana2007

  interface accretionHaloNaozBarkana2007
     !% Constructors for the {\normalfont \ttfamily naozBarkana2007} halo accretion class.
     module procedure naozBarkana2007ConstructorParameters
     module procedure naozBarkana2007ConstructorInternal
  end interface accretionHaloNaozBarkana2007

  ! Virial density contrast definition used by Gnedin (2000) to define halos, and therefore used in the filtering mass fitting functions.
  double precision, parameter :: naozBarkana2007VirialDensityContrast=200.0d0

contains

  function naozBarkana2007ConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily naozBarkana2007} halo accretion class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type (accretionHaloNaozBarkana2007)                :: self
    type (inputParameters             ), intent(inout) :: parameters

    self%accretionHaloSimple=accretionHaloSimple(parameters)
    !# <inputParameter>
    !#   <name>rateAdjust</name>
    !#   <defaultValue>0.3d0</defaultValue>
    !#   <description>The dimensionless multiplier for the rate at which the halo gas content adjusts to changes in the filtering mass.</description>
    !#   <source>parameters</source>
    !#   <variable>self%rateAdjust</variable>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massMinimum</name>
    !#   <defaultValue>0.0d0</defaultValue>
    !#   <description>The minimum mass of gas accreted into a halo below which the mass is truncated to zero.</description>
    !#   <source>parameters</source>
    !#   <variable>self%massMinimum</variable>
    !# </inputParameter>
    !# <objectBuilder class="intergalacticMediumFilteringMass" name="self%intergalacticMediumFilteringMass_" source="parameters"/>
    !# <inputParametersValidate source="parameters"/>
    return
  end function naozBarkana2007ConstructorParameters

  function naozBarkana2007ConstructorInternal(timeReionization,velocitySuppressionReionization,accretionNegativeAllowed,accretionNewGrowthOnly,rateAdjust,massMinimum,cosmologyParameters_,cosmologyFunctions_,darkMatterHaloScale_,accretionHaloTotal_,chemicalState_,intergalacticMediumState_,intergalacticMediumFilteringMass_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily naozBarkana2007} halo accretion class.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    type            (accretionHaloNaozBarkana2007         )                        :: self
    double precision                                       , intent(in   )         :: timeReionization                , velocitySuppressionReionization, &
         &                                                                            rateAdjust                      , massMinimum
    logical                                                , intent(in   )         :: accretionNegativeAllowed        , accretionNewGrowthOnly
    class           (cosmologyParametersClass             ), intent(in   ), target :: cosmologyParameters_
    class           (cosmologyFunctionsClass              ), intent(in   ), target :: cosmologyFunctions_
    class           (accretionHaloTotalClass              ), intent(in   ), target :: accretionHaloTotal_
    class           (darkMatterHaloScaleClass             ), intent(in   ), target :: darkMatterHaloScale_
    class           (chemicalStateClass                   ), intent(in   ), target :: chemicalState_
    class           (intergalacticMediumStateClass        ), intent(in   ), target :: intergalacticMediumState_
    class           (intergalacticMediumFilteringMassClass), intent(in   ), target :: intergalacticMediumFilteringMass_
    !# <constructorAssign variables="rateAdjust, massMinimum, *intergalacticMediumFilteringMass_"/>

    self%accretionHaloSimple=accretionHaloSimple(timeReionization,velocitySuppressionReionization,accretionNegativeAllowed,accretionNewGrowthOnly,cosmologyParameters_,cosmologyFunctions_,darkMatterHaloScale_,accretionHaloTotal_,chemicalState_,intergalacticMediumState_)
    return
  end function naozBarkana2007ConstructorInternal

  subroutine naozBarkana2007AutoHook(self)
    !% Attach to the calculation reset event.
    use :: Events_Hooks, only : calculationResetEvent, openMPThreadBindingAllLevels
    implicit none
    class(accretionHaloNaozBarkana2007), intent(inout) :: self

    call calculationResetEvent%attach(self,naozBarkana2007CalculationReset,openMPThreadBindingAllLevels)
    return
  end subroutine naozBarkana2007AutoHook

  subroutine naozBarkana2007Destructor(self)
    !% Destructor for the {\normalfont \ttfamily naozBarkana2007} halo accretion class.
    use :: Events_Hooks, only : calculationResetEvent
    implicit none
    type(accretionHaloNaozBarkana2007), intent(inout) :: self

    call calculationResetEvent%detach(self,naozBarkana2007CalculationReset)
    !# <objectDestructor name="self%intergalacticMediumFilteringMass_"/>
    return
  end subroutine naozBarkana2007Destructor

  subroutine naozBarkana2007CalculationReset(self,node)
    !% Reset the accretion rate calculation.
    implicit none
    class(accretionHaloNaozBarkana2007), intent(inout) :: self
    type (treeNode                    ), intent(inout) :: node

    self%filteredFractionComputed    =.false.
    self%filteredFractionRateComputed=.false.
    self%lastUniqueID                =node%uniqueID()
    return
  end subroutine naozBarkana2007CalculationReset

  logical function naozBarkana2007BranchHasBaryons(self,node)
    !% Returns true if this branch can accrete any baryons.
    use :: Galacticus_Nodes   , only : nodeComponentBasic                 , treeNode
    use :: Merger_Tree_Walkers, only : mergerTreeWalkerIsolatedNodesBranch
    implicit none
    class           (accretionHaloNaozBarkana2007       ), intent(inout)          :: self
    type            (treeNode                           ), intent(inout), target  :: node
    type            (treeNode                           )               , pointer :: branchNode
    class           (nodeComponentBasic                 )               , pointer :: basic
    type            (mergerTreeWalkerIsolatedNodesBranch)                         :: treeWalker
    double precision                                                              :: fractionBaryons, massHaloMinimum

    fractionBaryons                 =  +self%cosmologyParameters_%OmegaBaryon() &
         &                             /self%cosmologyParameters_%OmegaMatter()
    massHaloMinimum                 =  +self                     %massMinimum   &
         &                             /fractionBaryons
    naozBarkana2007BranchHasBaryons =   .false.
    treeWalker                      =   mergerTreeWalkerIsolatedNodesBranch(node)
    do while (treeWalker%next(branchNode))
       basic => branchnode%basic()
       if (self%accretionHaloTotal_%accretedMass(branchNode)*self%filteredFraction(branchNode) >= massHaloMinimum) then
          naozBarkana2007BranchHasBaryons=.true.
          exit
       end if
    end do
    return
  end function naozBarkana2007BranchHasBaryons

  double precision function naozBarkana2007FilteredFraction(self,node)
    !% Returns the baryonic mass fraction in a halo after the effects of the filtering mass.
    use :: Dark_Matter_Profile_Mass_Definitions, only : Dark_Matter_Profile_Mass_Definition
    use :: Galacticus_Nodes                    , only : nodeComponentBasic                 , treeNode
    implicit none
    class           (accretionHaloNaozBarkana2007 ), intent(inout) :: self
    type            (treeNode                     ), intent(inout) :: node
    class           (nodeComponentBasic           ), pointer       :: basic
    double precision                                               :: massFiltering, massHalo

    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Evaluate the filtering mass suppression fitting formula as defined by Naoz & Barkana (2007;
    ! http://adsabs.harvard.edu/abs/2007MNRAS.377..667N). We use a halo mass in this formula defined in the same way (∆=200) as in
    ! the original work by Gnedin (2000; http://adsabs.harvard.edu/abs/2000ApJ...542..535G) based on the discussion of halo
    ! definition in Naoz, Yoshida, & Gnedin (2013; http://adsabs.harvard.edu/abs/2013ApJ...763...27N).
    if (.not.self%filteredFractionComputed) then
       basic                         => node                                  %basic        (                                                 )
       massFiltering                 =  self%intergalacticMediumFilteringMass_%massFiltering(basic%time()                                     )
       massHalo                      =  Dark_Matter_Profile_Mass_Definition                 (node        ,naozBarkana2007VirialDensityContrast)
       self%filteredFractionStored   =  self%filteredFractionCompute(massHalo,massFiltering)
       self%filteredFractionComputed =  .true.
    end if
    naozBarkana2007FilteredFraction=self%filteredFractionStored
    return
  end function naozBarkana2007FilteredFraction

  double precision function naozBarkana2007FilteredFractionRate(self,node)
    !% Returns the baryonic mass accretion rate fraction in a halo after the effects of the filtering mass.
    use :: Dark_Matter_Profile_Mass_Definitions, only : Dark_Matter_Profile_Mass_Definition
    use :: Galacticus_Nodes                    , only : nodeComponentBasic                 , treeNode
    use :: Math_Exponentiation                 , only : cubeRoot
    implicit none
    class           (accretionHaloNaozBarkana2007 ), intent(inout) :: self
    type            (treeNode                     ), intent(inout) :: node
    class           (nodeComponentBasic           ), pointer       :: basic
    double precision                                               :: massFiltering, massHalo

    ! Check if node differs from previous one for which we performed calculations.
    if (node%uniqueID() /= self%lastUniqueID) call self%calculationReset(node)
    ! Evaluate the rate of change of the filtering mass suppression fitting formula as defined by Naoz & Barkana (2007;
    ! http://adsabs.harvard.edu/abs/2007MNRAS.377..667N). We use a halo mass in this formula defined in the same way (∆=200) as in
    ! the original work by Gnedin (2000; http://adsabs.harvard.edu/abs/2000ApJ...542..535G) based on the discussion of halo
    ! definition in Naoz, Yoshida, & Gnedin (2013; http://adsabs.harvard.edu/abs/2013ApJ...763...27N). The rate of change here
    ! assumes that the filtering mass is constant in time.
    if (.not.self%filteredFractionRateComputed) then
       basic          => node                                  %basic        (                                                  )
       massFiltering  =  self%intergalacticMediumFilteringMass_%massFiltering(basic%time()                                      )
       massHalo       =  Dark_Matter_Profile_Mass_Definition                 (node         ,naozBarkana2007VirialDensityContrast)
       if (.not.self%filteredFractionComputed) then
          self%filteredFractionStored   =  self%filteredFractionCompute(massHalo,massFiltering)
          self%filteredFractionComputed =  .true.
       end if
       self%filteredFractionRateStored  = +           self%filteredFractionStored  &
            &                             *(+1.0d0                                 &
            &                               +cubeRoot(self%filteredFractionStored) &
            &                               *(                                     &
            &                                 +2.0d0**(1.0d0/3.0d0)                &
            &                                 -1.0d0                               &
            &                                )                                     &
            &                               *24.0d0                                &
            &                               *massFiltering                         &
            &                               /massHalo                              &
            &                              )
       self%filteredFractionRateComputed=.true.
    end if
    naozBarkana2007FilteredFractionRate=self%filteredFractionRateStored
    return
  end function naozBarkana2007FilteredFractionRate

  double precision function naozBarkana2007FilteredFractionCompute(self,massHalo,massFiltering)
    !% Compute the filtered fraction.
    implicit none
    double precision                               , intent(in   ) :: massHalo, massFiltering
    class           (accretionHaloNaozBarkana2007 ), intent(inout) :: self
    !$GLC attributes unused :: self

    naozBarkana2007FilteredFractionCompute=+1.0d0                     &
         &                                 /(                         &
         &                                    +1.0d0                  &
         &                                    +(                      &
         &                                      +2.0d0**(1.0d0/3.0d0) &
         &                                      -1.0d0                &
         &                                     )                      &
         &                                    *8.0d0                  &
         &                                    *massFiltering          &
         &                                    /massHalo               &
         &                                   )**3
    return
  end function naozBarkana2007FilteredFractionCompute

  double precision function naozBarkana2007AccretionRate(self,node,accretionMode)
    !% Computes the baryonic accretion rate onto {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, nodeComponentHotHalo, treeNode
    implicit none
    class           (accretionHaloNaozBarkana2007), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    integer                                       , intent(in   ) :: accretionMode
    class           (nodeComponentBasic          ), pointer       :: basic
    class           (nodeComponentHotHalo        ), pointer       :: hotHalo
    double precision                                              :: growthRate          , filteredFraction, &
         &                                                           filteredFractionRate, fractionAccreted

    naozBarkana2007AccretionRate=0.0d0
    if (accretionMode      == accretionModeCold) return
    if (node%isSatellite()                     ) return
    ! Get required objects.
    basic   => node%basic  ()
    hotHalo => node%hotHalo()
    ! Find the post-filtering accretion rate fraction.
    filteredFractionRate=self%filteredFractionRate(node)
    ! Compute the mass accretion rate onto the halo.
    naozBarkana2007AccretionRate=+self%cosmologyParameters_%OmegaBaryon  (    ) &
         &                       /self%cosmologyParameters_%OmegaMatter  (    ) &
         &                       *self%accretionHaloTotal_ %accretionRate(node) &
         &                       *filteredFractionRate
    ! Test for negative accretion.
    if (.not.self%accretionNegativeAllowed.and.self%accretionHaloTotal_%accretionRate(node) < 0.0d0) then
       ! Accretion rate is negative, and not allowed. Return zero accretion rate.
       naozBarkana2007AccretionRate=+0.0d0
    else
       ! Adjust the rate to allow mass to flow back-and-forth from accreted to unaccreted reservoirs if the current mass fraction
       ! differs from that expected given the filtering mass.
       growthRate                  =+self                     %rateAdjust               &
            &                       /self%darkMatterHaloScale_%dynamicalTimescale(node)
       filteredFraction            =+self                     %filteredFraction  (node)
       fractionAccreted            =+  hotHalo                %          mass    (    ) &
            &                       /(                                                  &
            &                         +hotHalo                %          mass    (    ) &
            &                         +hotHalo                %unaccretedMass    (    ) &
            &                        )
       naozBarkana2007AccretionRate=+naozBarkana2007AccretionRate                       &
            &                       -(                                                  &
            &                         +hotHalo                %          mass    (    ) &
            &                         +hotHalo                %unaccretedMass    (    ) &
            &                        )                                                  &
            &                       *(                                                  &
            &                         +fractionAccreted                                 &
            &                         -filteredFraction                                 &
            &                        )                                                  &
            &                       *growthRate
    end if
    ! If accretion is allowed only on new growth, check for new growth and shut off accretion if growth is not new.
    if (self%accretionNewGrowthOnly .and. self%accretionHaloTotal_%accretedMass(node) < basic%massMaximum()) naozBarkana2007AccretionRate=0.0d0
    return
  end function naozBarkana2007AccretionRate

  double precision function naozBarkana2007AccretedMass(self,node,accretionMode)
    !% Computes the mass of baryons accreted into {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (accretionHaloNaozBarkana2007), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    integer                                       , intent(in   ) :: accretionMode
    class           (nodeComponentBasic          ), pointer       :: basic
    double precision                                              :: filteredFraction

    naozBarkana2007AccretedMass=0.0d0
    if (accretionMode      == accretionModeCold) return
    if (node%isSatellite()                     ) return
    ! Get required objects.
    basic            => node%basic           (    )
    ! Get the filtered mass fraction.
    filteredFraction =  self%filteredFraction(node)
    ! Get the default cosmology.
    naozBarkana2007AccretedMass=+self%cosmologyParameters_%OmegaBaryon (    ) &
         &                      /self%cosmologyParameters_%OmegaMatter (    ) &
         &                      *self%accretionHaloTotal_ %accretedMass(node) &
         &                      *filteredFraction
         return
  end function naozBarkana2007AccretedMass

  double precision function naozBarkana2007FailedAccretionRate(self,node,accretionMode)
    !% Computes the baryonic accretion rate onto {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, nodeComponentHotHalo, treeNode
    implicit none
    class           (accretionHaloNaozBarkana2007), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    integer                                       , intent(in   ) :: accretionMode
    class           (nodeComponentBasic          ), pointer       :: basic
    class           (nodeComponentHotHalo        ), pointer       :: hotHalo
    double precision                                              :: growthRate          , filteredFraction, &
         &                                                           filteredFractionRate, fractionAccreted

    naozBarkana2007FailedAccretionRate=0.0d0
    if (accretionMode               == accretionModeCold) return
    if (node         %isSatellite()                     ) return
    ! Get required objects.
    basic   => node%basic  ()
    hotHalo => node%hotHalo()
    ! Get the post-filtering accretion rate fraction.
    filteredFractionRate=self%filteredFractionRate(node)
    ! Test for negative accretion.
    if (.not.self%accretionNegativeAllowed.and.self%accretionHaloTotal_%accretionRate(node) < 0.0d0) then
       naozBarkana2007FailedAccretionRate=+self%cosmologyParameters_%OmegaBaryon  (    ) &
            &                             /self%cosmologyParameters_%OmegaMatter  (    ) &
            &                             *self%accretionHaloTotal_ %accretionRate(node)
    else
       ! Compute the rate of failed accretion.
       naozBarkana2007FailedAccretionRate=+self%cosmologyParameters_%OmegaBaryon  (    ) &
            &                             /self%cosmologyParameters_%OmegaMatter  (    ) &
            &                             *self%accretionHaloTotal_ %accretionRate(node) &
            &                             *(                                             &
            &                               +1.0d0                                       &
            &                               -filteredFractionRate                        &
            &                              )
       ! Adjust the rate to allow mass to flow back-and-forth from accreted to unaccreted reservoirs if the current mass fraction
       ! differs from that expected given the filtering mass.
       growthRate                        =+self                     %rateAdjust               &
            &                             /self%darkMatterHaloScale_%dynamicalTimescale(node)
       filteredFraction                  =+self                     %filteredFraction  (node)
       fractionAccreted                  =+  hotHalo                %          mass    (    ) &
            &                             /(                                                  &
            &                               +hotHalo                %          mass    (    ) &
            &                               +hotHalo                %unaccretedMass    (    ) &
            &                              )
       naozBarkana2007FailedAccretionRate=+naozBarkana2007FailedAccretionRate                 &
            &                             +(                                                  &
            &                               +hotHalo                %          mass    (    ) &
            &                               +hotHalo                %unaccretedMass    (    ) &
            &                              )                                                  &
            &                             *(                                                  &
            &                               +fractionAccreted                                 &
            &                               -filteredFraction                                 &
            &                              )                                                  &
            &                             *growthRate
    end if
    ! If accretion is allowed only on new growth, check for new growth and shut off accretion if growth is not new.
    if (self%accretionNewGrowthOnly .and. self%accretionHaloTotal_%accretedMass(node) < basic%massMaximum()) naozBarkana2007FailedAccretionRate=0.0d0
    return
  end function naozBarkana2007FailedAccretionRate

  double precision function naozBarkana2007FailedAccretedMass(self,node,accretionMode)
    !% Computes the mass of baryons accreted into {\normalfont \ttfamily node}.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (accretionHaloNaozBarkana2007), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    integer                                       , intent(in   ) :: accretionMode
    class           (nodeComponentBasic          ), pointer       :: basic
    double precision                                              :: filteredFraction

    naozBarkana2007FailedAccretedMass=0.0d0
    if (accretionMode      == accretionModeCold) return
    if (node%isSatellite()                     ) return
    ! Get required objects.
    basic => node%basic()
    ! Get the failed fraction.
    filteredFraction=self%filteredFraction(node)
    ! Get the default cosmology.
    naozBarkana2007FailedAccretedMass = +self%cosmologyParameters_%OmegaBaryon (    ) &
         &                              /self%cosmologyParameters_%OmegaMatter (    ) &
         &                              *self%accretionHaloTotal_ %accretedMass(node) &
         &                              *(                                            &
         &                                +1.0d0                                      &
         &                                -filteredFraction                           &
         &                               )
    return
  end function naozBarkana2007FailedAccretedMass

