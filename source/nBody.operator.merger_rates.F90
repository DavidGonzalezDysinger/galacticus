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

!% Contains a module which implements an N-body data operator which computes merger rates of halos.

  use :: Cosmology_Functions, only : cosmologyFunctionsClass

  !# <nbodyOperator name="nbodyOperatorMergerRates">
  !#  <description>An N-body data operator which computes merger rates of halos.</description>
  !# </nbodyOperator>
  type, extends(nbodyOperatorClass) :: nbodyOperatorMergerRates
     !% An N-body data operator which computes merger rates of halos.
     private
     class           (cosmologyFunctionsClass), pointer :: cosmologyFunctions_ => null()
     integer         (c_size_t               )          :: indexSnapshot
     double precision                                   :: massMinimum                  , massMaximum       , &
          &                                                massHostMinimum              , massHostMaximum
     logical                                            :: missingHostIsFatal           , alwaysIsolatedOnly
     type            (varying_string         )          :: suffix
   contains
     final :: mergerRatesDestructor
     procedure :: operate => mergerRatesOperate
  end type nbodyOperatorMergerRates

  interface nbodyOperatorMergerRates
     !% Constructors for the {\normalfont \ttfamily mergerRates} N-body operator class.
     module procedure mergerRatesConstructorParameters
     module procedure mergerRatesConstructorInternal
  end interface nbodyOperatorMergerRates

contains

  function mergerRatesConstructorParameters(parameters) result (self)
    !% Constructor for the {\normalfont \ttfamily mergerRates} N-body operator class which takes a parameter set as input.
    use :: Input_Parameters  , only : inputParameters
    use :: ISO_Varying_String, only : operator(/=)
    implicit none
    type            (nbodyOperatorMergerRates)                :: self
    type            (inputParameters         ), intent(inout) :: parameters
    class           (cosmologyFunctionsClass ), pointer       :: cosmologyFunctions_
    integer         (c_size_t                )                :: indexSnapshot
    type            (varying_string          )                :: suffix
    double precision                                          :: massMinimum        , massMaximum       , &
         &                                                       massHostMinimum    , massHostMaximum
    logical                                                   :: missingHostIsFatal , alwaysIsolatedOnly

    !# <inputParameter>
    !#   <name>indexSnapshot</name>
    !#   <source>parameters</source>
    !#   <description>The snapshot index for which to compute the merger rate.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massMinimum</name>
    !#   <source>parameters</source>
    !#   <description>The minimum mass (of the secondary halo) for which to accumulate merging statistics.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massMaximum</name>
    !#   <source>parameters</source>
    !#   <description>The maximum mass (of the secondary halo) for which to accumulate merging statistics.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massHostMinimum</name>
    !#   <source>parameters</source>
    !#   <description>The minimum mass (of the primary halo) for which to accumulate merging statistics.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massHostMaximum</name>
    !#   <source>parameters</source>
    !#   <description>The maximum mass (of the primary halo) for which to accumulate merging statistics.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>missingHostIsFatal</name>
    !#   <source>parameters</source>
    !#   <defaultValue>.true.</defaultValue>
    !#   <description>If true, missing host halos are cause for a fatal error. Otherwise they are ignored.</description>
    !#   <type>boolean</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>alwaysIsolatedOnly</name>
    !#   <source>parameters</source>
    !#   <defaultValue>.true.</defaultValue>
    !#   <description>If true, only mergers of halos which have been always isolated are considered. Otherwise, all halos are considered.</description>
    !#   <type>boolean</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>suffix</name>
    !#   <source>parameters</source>
    !#   <defaultValue>var_str('')</defaultValue>
    !#   <description>A suffix to append to the output merger rate attribute. Useful if you want to write output multiple merger rates.</description>
    !#   <type>boolean</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <objectBuilder class="cosmologyFunctions" name="cosmologyFunctions_" source="parameters"/>
    self=nbodyOperatorMergerRates(indexSnapshot,massMinimum,massMaximum,massHostMinimum,massHostMaximum,missingHostIsFatal,alwaysIsolatedOnly,suffix,cosmologyFunctions_)
    !# <objectDestructor name="cosmologyFunctions_"   />
    !# <inputParametersValidate source="parameters"/>
    return
  end function mergerRatesConstructorParameters

  function mergerRatesConstructorInternal(indexSnapshot,massMinimum,massMaximum,massHostMinimum,massHostMaximum,missingHostIsFatal,alwaysIsolatedOnly,suffix,cosmologyFunctions_) result (self)
    !% Internal constructor for the {\normalfont \ttfamily mergerRates} N-body operator class.
    implicit none
    type            (nbodyOperatorMergerRates)                        :: self
    class           (cosmologyFunctionsClass ), intent(in   ), target :: cosmologyFunctions_
    integer         (c_size_t                ), intent(in   )         :: indexSnapshot
    type            (varying_string          ), intent(in   )         :: suffix
    double precision                          , intent(in   )         :: massMinimum        , massMaximum       , &
         &                                                               massHostMinimum    , massHostMaximum
    logical                                   , intent(in   )         :: missingHostIsFatal , alwaysIsolatedOnly
    !# <constructorAssign variables="indexSnapshot, massMinimum, massMaximum, massHostMinimum, massHostMaximum, missingHostIsFatal, alwaysIsolatedOnly, suffix, *cosmologyFunctions_"/>

    return
  end function mergerRatesConstructorInternal

  subroutine mergerRatesDestructor(self)
    !% Destructor for the {\normalfont \ttfamily mergerRates} N-body operator class.
    implicit none
    type(nbodyOperatorMergerRates), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyFunctions_"/>
    return
  end subroutine mergerRatesDestructor
  
  subroutine mergerRatesOperate(self,simulations)
    !% Compute the merger rate at a given snapshot.
    !$ use :: OMP_Lib, only : OMP_Get_Thread_Num
    use    :: Arrays_Search     , only : searchIndexed
    use    :: Galacticus_Display, only : Galacticus_Display_Indent , Galacticus_Display_Unindent, Galacticus_Display_Counter, Galacticus_Display_Counter_Clear, &
         &                               Galacticus_Display_Message, verbosityStandard
    use    :: Galacticus_Error  , only : Galacticus_Error_Report
    use    :: Sorting           , only : sortIndex
    use    :: IO_HDF5           , only : hdf5Access
#ifdef USEMPI
    use    :: MPI_Utilities     , only : mpiSelf
#endif
    implicit none
    class           (nbodyOperatorMergerRates), intent(inout)               :: self
    type            (nBodyData               ), intent(inout), dimension(:) :: simulations
    integer         (c_size_t                ), pointer      , dimension(:) :: particleID                    , hostID                    , &
         &                                                                     descendentID                  , snapshotID                , &
         &                                                                     isMostMassiveProgenitor       , alwaysIsolated
    integer         (c_size_t                ), allocatable  , dimension(:) :: indexID
    double precision                          , pointer      , dimension(:) :: massVirial                    , expansionFactor
    double precision                          , allocatable  , dimension(:) :: mergerRate
    logical                                   , allocatable  , dimension(:) :: selection
    integer         (c_size_t                )                              :: i                             , j                         , &
         &                                                                     k                             , iSimulation               , &
         &                                                                     countSelection
    logical                                                                 :: isMerger                      , expansionFactorParentFound, &
         &                                                                     expansionFactorProgenitorFound
    double precision                                                        :: expansionFactorParent         , expansionFactorProgenitor , &
         &                                                                     mergerRateMean                , mergerRateMeanError
    type            (varying_string          )                              :: attributeName
    
#ifdef USEMPI
    if (mpiSelf%isMaster()) then
#endif
    call Galacticus_Display_Indent('compute merger rates',verbosityStandard)
#ifdef USEMPI
    end if
#endif
    do iSimulation=1,size(simulations)
#ifdef USEMPI
       if (mpiSelf%isMaster()) then
#endif
       call Galacticus_Display_Message(var_str('simulation "')//simulations(iSimulation)%label//'"',verbosityStandard)
#ifdef USEMPI
       end if
#endif
       ! Retrieve required properties.
       particleID              => simulations(iSimulation)%propertiesInteger%value('particleID'             )
       hostID                  => simulations(iSimulation)%propertiesInteger%value('hostID'                 )
       descendentID            => simulations(iSimulation)%propertiesInteger%value('descendentID'           )
       snapshotID              => simulations(iSimulation)%propertiesInteger%value('snapshotID'             )
       isMostMassiveProgenitor => simulations(iSimulation)%propertiesInteger%value('isMostMassiveProgenitor')
       alwaysIsolated          => simulations(iSimulation)%propertiesInteger%value('alwaysIsolated'         )
       massVirial              => simulations(iSimulation)%propertiesReal   %value('massVirial'             )
       expansionFactor         => simulations(iSimulation)%propertiesReal   %value('expansionFactor'        )
       ! Allocate workspace.
       allocate(indexID   (size(particleID)))
       allocate(mergerRate(size(particleID)))
       allocate(selection (size(particleID)))
       ! Initialize merger rates.
       mergerRate=0.0d0
       ! Initialize expansion factors.
       expansionFactorParentFound    = .false.
       expansionFactorProgenitorFound= .false.
       expansionFactorParent         =-huge(0.0d0)
       expansionFactorProgenitor     =-huge(0.0d0)
       ! Build a sort index.
       indexID=sortIndex(particleID)
       ! Visit each particle.
#ifdef USEMPI
       if (mpiSelf%isMaster()) then
#endif
          call Galacticus_Display_Counter(0,.true.)
#ifdef USEMPI
       end if
#endif
       !$omp parallel do private(j,k,isMerger) schedule(dynamic)
       do i=1_c_size_t,size(particleID)
#ifdef USEMPI
          ! If running under MPI with N processes, process only every Nth particle.
          if (mod(i,mpiSelf%count()) /= mpiSelf%rank()) cycle
#endif
          ! Look for expansion factors.
          if (.not.expansionFactorParentFound    ) then
             if (snapshotID(i) == self%indexSnapshot           ) then
                expansionFactorParentFound    =.true.
                expansionFactorParent         =expansionFactor(i)
             end if
          end if
          if (.not.expansionFactorProgenitorFound) then
             if (snapshotID(i) == self%indexSnapshot-1_c_size_t) then
                expansionFactorProgenitorFound=.true.
                expansionFactorProgenitor     =expansionFactor(i)
             end if
          end if
          ! Skip halos which are not at the snapshot immediately prior to the snapshot of interest.
          if     (snapshotID    (i) /= self%indexSnapshot-1_c_size_t                              ) cycle
          ! Skip non-isolated halos.
          if     (hostID        (i) >= 0_c_size_t                                                 ) cycle
          ! Skip non-always-isolated halos.
          if     (alwaysIsolated(i) == 0_c_size_t                    .and. self%alwaysIsolatedOnly) cycle
          ! Skip halos with no descendent.
          if     (descendentID  (i) <  0_c_size_t                                                 ) cycle
          ! Skip halos outside the mass range.
          if     (                                                                                        &
               &   massVirial   (i) <  self%massMinimum                                                   &
               &  .or.                                                                                    &
               &   massVirial   (i) >  self%massMaximum                                                   &
               & )                                                                                  cycle
          ! Identify the descendent halo.
          k=searchIndexed(particleID,indexID,descendentID(i))
          if     (                                           &
               &   k                         < 1_c_size_t    &
               &  .or.                                       &
               &   k                         > size(indexID) &
               & )                                           &
               & call Galacticus_Error_Report('failed to find descendent'//{introspection:location})
          j=indexID(k)
          ! If this halo is not the most-massive progenitor, or if the descendent is hosted, we have a merger.
          isMerger=isMostMassiveProgenitor(i) == 0 .or. hostID(j) >= 0_c_size_t
          if (isMerger) then
             ! Find the ultimate host.
             do while (hostID(j) >= 0_c_size_t)
                k=searchIndexed(particleID,indexID,hostID(j))
                if     (                                           &
                     &   k                         < 1_c_size_t    &
                     &  .or.                                       &
                     &   k                         > size(indexID) &
                     & ) then
                   ! A host could not be found.
                   if (self%missingHostIsFatal) then
                      call Galacticus_Error_Report('failed to find host'//{introspection:location})
                   else
                      exit
                   end if
                end if
                if (particleID(indexID(k)) /= hostID(j)) then
                   ! A host could not be found.
                   if (self%missingHostIsFatal) then
                      call Galacticus_Error_Report('failed to find host'//{introspection:location})
                   else
                      exit
                   end if
                end if
                j=indexID(k)
             end do
          end if
          if (isMerger) then
             !$omp atomic
             mergerRate(j)=mergerRate(j)+1.0d0
          end if
          !$ if (OMP_Get_Thread_Num() == 0) then
#ifdef USEMPI
          if (mpiSelf%isMaster()) then
#endif
             call Galacticus_Display_Counter(int(100.0d0*dble(i)/dble(size(particleID))),verbosity=verbosityStandard,isNew=i == 1_c_size_t)
#ifdef USEMPI
          end if
#endif
          !$ end if
       end do
       !$omp end parallel do
#ifdef USEMPI
       if (mpiSelf%isMaster()) then
#endif
          call Galacticus_Display_Counter_Clear()
#ifdef USEMPI
       end if
#endif
#ifdef USEMPI
       ! Reduce across MPI processes.
       mergerRate=mpiSelf%sum(mergerRate)
#endif
       ! Sum and average merger rates.
       !! Select isolated halos within the host halo mass range.
       selection= hostID     <  0_c_size_t           &
            &    .and.                               &
            &     massVirial >= self%massHostMinimum &
            &    .and.                               &
            &     massVirial <= self%massHostMaximum &
            &    .and.&
            &     snapshotID == self%indexSnapshot
       !! Count the number of selected halos.
       countSelection=count(selection)
       if (countSelection > 0_c_size_t) then
          mergerRateMean     =     sum(mergerRate,mask=selection) /dble(countSelection)
          mergerRateMeanError=sqrt(sum(mergerRate,mask=selection))/dble(countSelection)
       else
          mergerRateMean     =-1.0d0
          mergerRateMeanError=-1.0d0
       end if
       ! Convert merger rate to dN₁₂/dlnM₂/dt in units of Gyr⁻¹.
       mergerRateMean     =+mergerRateMean                                                                                                                  &
            &              /log(+self%massMaximum                                          /self%massMinimum                                              ) &
            &              /   (+self%cosmologyFunctions_%cosmicTime(expansionFactorParent)-self%cosmologyFunctions_%cosmicTime(expansionFactorProgenitor))
       mergerRateMeanError=+mergerRateMeanError                                                                                                             &
            &              /log(+self%massMaximum                                          /self%massMinimum                                              ) &
            &              /   (+self%cosmologyFunctions_%cosmicTime(expansionFactorParent)-self%cosmologyFunctions_%cosmicTime(expansionFactorProgenitor))
       ! Store results.
#ifdef USEMPI
       if (mpiSelf%isMaster()) then
#endif
          attributeName=var_str('mergerRateMean:'     )//simulations(iSimulation)%label
          if (self%suffix /= "") attributeName=attributeName//":"//self%suffix
          !$ call hdf5Access%  set()
          call simulations(iSimulation)%analysis%writeAttribute(mergerRateMean     ,char(attributeName))
          !$ call hdf5Access%unset()
          attributeName=var_str('mergerRateMeanError:')//simulations(iSimulation)%label
          if (self%suffix /= "") attributeName=attributeName//":"//self%suffix
          !$ call hdf5Access%  set()
          call simulations(iSimulation)%analysis%writeAttribute(mergerRateMeanError,char(attributeName))
          !$ call hdf5Access%unset()
#ifdef USEMPI
       end if
#endif
       ! Clean up.
       deallocate(snapshotID     )
       deallocate(indexID        )
       deallocate(hostID         )
       deallocate(descendentID   )
       deallocate(massVirial     )
       deallocate(expansionFactor)
       deallocate(mergerRate     )
       deallocate(alwaysIsolated )
       deallocate(selection      )
    end do
#ifdef USEMPI
    if (mpiSelf%isMaster()) then
#endif
       call Galacticus_Display_Unindent('done',verbosityStandard)
#ifdef USEMPI
    end if
#endif
    return
  end subroutine mergerRatesOperate
