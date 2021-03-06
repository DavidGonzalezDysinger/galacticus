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

!% Contains a module which implements a sequence of operators on merger trees.

  !# <mergerTreeOperator name="mergerTreeOperatorSequence">
  !#  <description>Provides a sequence of operators on merger trees.</description>
  !#  <deepCopy>
  !#   <linkedList type="operatorList" variable="operators" next="next" object="operator_" objectType="mergerTreeOperatorClass"/>
  !#  </deepCopy>
  !# </mergerTreeOperator>

  type, public :: operatorList
     class(mergerTreeOperatorClass), pointer :: operator_
     type (operatorList           ), pointer :: next      => null()
  end type operatorList

  type, extends(mergerTreeOperatorClass) :: mergerTreeOperatorSequence
     !% A sequence merger tree operator class.
     private
     type(operatorList), pointer :: operators => null()
  contains
     final     ::                        sequenceDestructor
     procedure :: operatePreEvolution => sequenceOperatePreEvolution
     procedure :: finalize            => sequenceFinalize
  end type mergerTreeOperatorSequence

  interface mergerTreeOperatorSequence
     !% Constructors for the sequence merger tree operator class.
     module procedure sequenceConstructorParameters
     module procedure sequenceConstructorInternal
  end interface mergerTreeOperatorSequence

contains

  function sequenceConstructorParameters(parameters) result(self)
    !% Constructor for the sequence merger tree operator class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type   (mergerTreeOperatorSequence)                :: self
    type   (inputParameters           ), intent(inout) :: parameters
    type   (operatorList              ), pointer       :: operator_
    integer                                            :: i

    self     %operators => null()
    operator_           => null()
    do i=1,parameters%copiesCount('mergerTreeOperatorMethod',zeroIfNotPresent=.true.)
       if (associated(operator_)) then
          allocate(operator_%next)
          operator_ => operator_%next
       else
          allocate(self%operators)
          operator_ => self%operators
       end if
       !# <objectBuilder class="mergerTreeOperator" name="operator_%operator_" source="parameters" copy="i" />
    end do
    return
  end function sequenceConstructorParameters

  function sequenceConstructorInternal(operators) result(self)
    !% Internal constructor for the sequence merger tree operator class.
    implicit none
    type(mergerTreeOperatorSequence)                        :: self
    type(operatorList              ), target, intent(in   ) :: operators
    type(operatorList              ), pointer               :: operator_

    self     %operators => operators
    operator_           => operators
    do while (associated(operator_))
       !# <referenceCountIncrement owner="operator_" object="operator_"/>
       operator_ => operator_%next
    end do
    return
  end function sequenceConstructorInternal

  subroutine sequenceDestructor(self)
    !% Destructor for the merger tree operator function class.
    implicit none
    type(mergerTreeOperatorSequence), intent(inout) :: self
    type(operatorList              ), pointer       :: operator_, operatorNext

    if (associated(self%operators)) then
       operator_ => self%operators
       do while (associated(operator_))
          operatorNext => operator_%next
          !# <objectDestructor name="operator_%operator_"/>
          deallocate(operator_)
          operator_ => operatorNext
       end do
    end if
    return
  end subroutine sequenceDestructor

  subroutine sequenceOperatePreEvolution(self,tree)
    !% Perform a sequence operation on a merger tree.
    implicit none
    class(mergerTreeOperatorSequence), intent(inout), target :: self
    type (mergerTree                ), intent(inout), target :: tree
    type (operatorList              ), pointer               :: operator_

    operator_ => self%operators
    do while (associated(operator_))
       call operator_%operator_%operatePreEvolution(tree)
       operator_ => operator_%next
    end do
    return
  end subroutine sequenceOperatePreEvolution

  subroutine sequenceFinalize(self)
    !% Perform a finalization on a sequence of operators on a merger tree.
    implicit none
    class(mergerTreeOperatorSequence), intent(inout) :: self
    type (operatorList              ), pointer       :: operator_

    operator_ => self%operators
    do while (associated(operator_))
       call operator_%operator_%finalize()
       operator_ => operator_%next
    end do
    return
  end subroutine sequenceFinalize
