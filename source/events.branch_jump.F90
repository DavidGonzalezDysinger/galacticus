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

!% Contains a module which handles node branch jump events.

module Node_Branch_Jumps
  !% Handles satellite node branch jump events.
  implicit none
  private
  public :: Node_Branch_Jump

contains

  logical function Node_Branch_Jump(thisEvent,thisNode,deadlockStatus)
    !% Moves a satellite node to a different branch of the merger tree.
    use :: Galacticus_Display                 , only : Galacticus_Display_Message   , verbosityInfo
    use :: Galacticus_Nodes                   , only : nodeEvent                    , treeNode
    use :: ISO_Varying_String                 , only : varying_string               , assignment(=), operator(//)
    use :: Merger_Trees_Evolve_Deadlock_Status, only : deadlockStatusIsNotDeadlocked
    use :: String_Handling                    , only : operator(//)
    !# <include directive="branchJumpPostProcess" type="moduleUse">
    include 'events.branch_jump.post_process.modules.inc'
    !# </include>
    implicit none
    class    (nodeEvent     ), intent(in   )          :: thisEvent
    type     (treeNode      ), intent(inout), pointer :: thisNode
    integer                  , intent(inout)          :: deadlockStatus
    type     (treeNode      )               , pointer :: lastSatellite , newHost
    type     (varying_string)                         :: message
    character(len=12        )                         :: label

    ! If the node is not yet a satellite, wait until it is before peforming this task.
    if (.not.thisNode%isSatellite()) then
       Node_Branch_Jump=.false.
       return
    else
       Node_Branch_Jump=.true.
    end if
    ! Report.
    write (label,'(f12.6)') thisEvent%time
    message='Node ['
    message=message//thisNode%index()//'] jumping branch to host ['//thisEvent%node%index()//'] at time '//label//' Gyr'
    call Galacticus_Display_Message(message,verbosityInfo)
    ! Remove the satellite from its current host.
    call thisNode%removeFromHost()
    ! Find the new host and insert the node as a satellite in that new host.
    newHost          => thisEvent%node
    thisNode%sibling => null()
    thisNode%parent  => newHost
    if (associated(newHost%firstSatellite)) then
       lastSatellite                => newHost %lastSatellite()
       lastSatellite%sibling        => thisNode
    else
       newHost      %firstSatellite => thisNode
    end if
    ! Update the host tree pointer in the node to point to its new tree.
    thisNode%hostTree => newHost%hostTree
    ! Locate the paired event in the host and remove it.
    call newHost%removePairedEvent(thisEvent)
    ! Allow any postprocessing of the branch jump event that may be necessary.
    !# <include directive="branchJumpPostProcess" type="functionCall" functionType="void">
    !#  <functionArgs>thisNode</functionArgs>
    include 'events.branch_jump.postprocess.inc'
    !# </include>
    ! Since we changed the tree, record that the tree is not deadlocked.
    deadlockStatus=deadlockStatusIsNotDeadlocked
    return
  end function Node_Branch_Jump

end module Node_Branch_Jumps
