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

  !% Contains a merger tree evolution timestep class which limits the step to the next satellite destruction event.

  !# <mergerTreeEvolveTimestep name="mergerTreeEvolveTimestepSatelliteDestruction">
  !#  <description>A merger tree evolution timestepping class which limits the step to the next satellite destruction event.</description>
  !# </mergerTreeEvolveTimestep>
  type, extends(mergerTreeEvolveTimestepClass) :: mergerTreeEvolveTimestepSatelliteDestruction
     !% Implementation of a merger tree evolution timestepping class which limits the step to the next satellite destruction event.
     private
     logical :: limitTimesteps
   contains
     procedure :: timeEvolveTo => satelliteDestructionTimeEvolveTo
  end type mergerTreeEvolveTimestepSatelliteDestruction

  interface mergerTreeEvolveTimestepSatelliteDestruction
     !% Constructors for the {\normalfont \ttfamily satelliteDestruction} merger tree evolution timestep class.
     module procedure satelliteDestructionConstructorParameters
     module procedure satelliteDestructionConstructorInternal
  end interface mergerTreeEvolveTimestepSatelliteDestruction

contains

  function satelliteDestructionConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily satelliteDestruction} merger tree evolution timestep class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type(mergerTreeEvolveTimestepSatelliteDestruction)                :: self
    type(inputParameters                             ), intent(inout) :: parameters
    !$GLC attributes unused :: parameters
    
    self=mergerTreeEvolveTimestepSatelliteDestruction()
    return
  end function satelliteDestructionConstructorParameters

  function satelliteDestructionConstructorInternal() result(self)
    !% Constructor for the {\normalfont \ttfamily satelliteDestruction} merger tree evolution timestep class which takes a parameter set as input.
    use :: Galacticus_Nodes, only : defaultSatelliteComponent
    implicit none
    type(mergerTreeEvolveTimestepSatelliteDestruction) :: self

    self%limitTimesteps=defaultSatelliteComponent%destructionTimeIsGettable()
    return
  end function satelliteDestructionConstructorInternal

  double precision function satelliteDestructionTimeEvolveTo(self,node,task,taskSelf,report,lockNode,lockType)
    !% Determine a suitable timestep for {\normalfont \ttfamily node} such that it does not exceed the time of the next satellite merger.
    use :: Evolve_To_Time_Reports, only : Evolve_To_Time_Report
    use :: Galacticus_Nodes      , only : nodeComponentBasic   , nodeComponentSatellite
    use :: ISO_Varying_String    , only : varying_string
    implicit none
    class           (mergerTreeEvolveTimestepSatelliteDestruction), intent(inout), target            :: self
    type            (treeNode                                    ), intent(inout), target            :: node
    procedure       (timestepTask                                ), intent(  out), pointer           :: task
    class           (*                                           ), intent(  out), pointer           :: taskSelf
    logical                                                       , intent(in   )                    :: report
    type            (treeNode                                    ), intent(  out), pointer, optional :: lockNode
    type            (varying_string                              ), intent(  out)         , optional :: lockType
    class           (nodeComponentBasic                          )               , pointer           :: basic
    class           (nodeComponentSatellite                      )               , pointer           :: satellite
    double precision                                                                                 :: timeUntilDestruction

    ! By default set a huge timestep so that this class has no effect.
    satelliteDestructionTimeEvolveTo =  huge(0.0d0)
    task                             => null(     )
    taskSelf                         => null(     )
    if (present(lockNode)) lockNode  => null(     )
    if (present(lockType)) lockType  =  ""
    ! If not limiting timesteps return.
    if (.not.self%limitTimesteps) return
    ! Find the time of destruction.
    satellite            => node     %satellite      ()
    timeUntilDestruction =  satellite%destructionTime()
    ! If time is negative, implies this is not a satellite, so return.
    if (timeUntilDestruction < 0.0d0) return
    ! Limit the timestep.
    if (present(lockNode)) lockNode  => node
    if (present(lockType)) lockType  =  "satellite (destruction)"
    basic                            => node%basic()
    satelliteDestructionTimeEvolveTo =  timeUntilDestruction+basic%time()
    ! Trigger a destruction event.
    task     => satelliteDestructionDestructionProcess
    taskSelf => self
    if (report) call Evolve_To_Time_Report("satellite (destruction): ",satelliteDestructionTimeEvolveTo,node%index())
    return
  end function satelliteDestructionTimeEvolveTo

  subroutine satelliteDestructionDestructionProcess(self,tree,node,deadlockStatus)
    !% Process a satellite node which has undergone a merger with its host node.
    use :: Galacticus_Display                 , only : Galacticus_Display_Message   , Galacticus_Verbosity_Level, verbosityInfo
    use :: Galacticus_Error                   , only : Galacticus_Error_Report
    use :: ISO_Varying_String                 , only : varying_string
    use :: Merger_Trees_Evolve_Deadlock_Status, only : deadlockStatusIsNotDeadlocked
    use :: String_Handling                    , only : operator(//)
    implicit none
    class  (*             ), intent(inout)          :: self
    type   (mergerTree    ), intent(in   )          :: tree
    type   (treeNode      ), intent(inout), pointer :: node
    integer                , intent(inout)          :: deadlockStatus
    type   (treeNode      )               , pointer :: mergee        , mergeeNext
    type   (varying_string)                         :: message
    !$GLC attributes unused :: self, tree

    ! Report if necessary.
    if (Galacticus_Verbosity_Level() >= verbosityInfo) then
       message='Satellite node ['
       message=message//node%index()//'] is being destroyed'
       call Galacticus_Display_Message(message)
    end if
    ! Any mergees of the merging node must become mergees of its merge target.
    mergee => node%firstMergee
    do while (associated(mergee))
       mergeeNext => mergee%siblingMergee
       call mergee%removeFromMergee()
       mergee%siblingMergee             => node      %mergeTarget%firstMergee
       node  %mergeTarget  %firstMergee => mergee
       mergee%mergeTarget               => node      %mergeTarget
       mergee                           => mergeeNext
    end do
    ! Finally remove the satellite node from the host and merge targets and destroy it.
    call node%removeFromHost  ()
    call node%removeFromMergee()
    call node%destroy         ()
    deallocate(node)
    node => null()
    ! The tree was changed, so mark that it is not deadlocked.
    deadlockStatus=deadlockStatusIsNotDeadlocked
    return
  end subroutine satelliteDestructionDestructionProcess
