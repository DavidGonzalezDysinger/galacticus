!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
!!           2019
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

!% Contains a module which defines the base class for all {\normalfont \ttfamily functionClass} classes.

module Function_Classes
  !% Defines the base class for all {\normalfont \ttfamily functionClass} classes.
  use :: ISO_Varying_String, only : varying_string, assignment(=)
  implicit none
  private
  public :: functionClass
#ifdef OBJECTDEBUG
  public :: debugStackPush, debugStackPop, debugStackGet
#endif
  
  type functionClass
     !% The base class for all {\normalfont \ttfamily functionClass} classes.
     logical :: isDefaultOfClass=.false.
     integer :: referenceCount  =0
   contains
     !@ <objectMethods>
     !@   <object>functionClass</object>
     !@   <objectMethod>
     !@     <method>referenceCountReset</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Reset the reference count to this object to 0.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>referenceCountIncrement</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Increment the reference count to this object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>referenceCountDecrement</method>
     !@     <type>\intzero</type>
     !@     <arguments></arguments>
     !@     <description>Decrement the reference count to this object and return the new reference count.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>isDefault</method>
     !@     <type>\logicalzero</type>
     !@     <arguments></arguments>
     !@     <description>Return true if this is the default object of this class.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     procedure :: isDefault               => functionClassIsDefault
     procedure :: referenceCountReset     => functionClassReferenceCountReset
     procedure :: referenceCountIncrement => functionClassReferenceCountIncrement
     procedure :: referenceCountDecrement => functionClassReferenceCountDecrement
  end type functionClass

#ifdef OBJECTDEBUG
  integer                , parameter                        :: debugStackSizeMaximum=100
  type   (varying_string), dimension(debugStackSizeMaximum) :: debugLocStack
  integer                                                   :: debugLocStackSize    =  0
  interface debugStackPush
     module procedure debugStackPushStr
     module procedure debugStackPushLoc
  end interface debugStackPush
  !$omp threadprivate(debugLocStack,debugLocStackSize)
#endif

contains

  logical function functionClassIsDefault(self)
    !% Return true if this is the default object of this class.
    implicit none
    class(functionClass), intent(in   ) :: self

    functionClassIsDefault=self%isDefaultOfClass
    return
  end function functionClassIsDefault
  
  subroutine functionClassReferenceCountReset(self)
    !% Reset the reference count to this object to 0.
    implicit none
    class(functionClass), intent(inout) :: self

    self%referenceCount=1
    return
  end subroutine functionClassReferenceCountReset
  
  subroutine functionClassReferenceCountIncrement(self)
    !% Increment the reference count to this object.
    implicit none
    class(functionClass), intent(inout) :: self

    self%referenceCount=self%referenceCount+1
   return
  end subroutine functionClassReferenceCountIncrement
  
  integer function functionClassReferenceCountDecrement(self)
    !% Decrement the reference count to this object and return the new count.
    implicit none
    class(functionClass), intent(inout) :: self

    self%referenceCount=self%referenceCount-1
    functionClassReferenceCountDecrement=self%referenceCount
    return
  end function functionClassReferenceCountDecrement

#ifdef OBJECTDEBUG
  subroutine debugStackPushStr(location)
    !% Push a text-location onto the debug location stack.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    character(len=*), intent(in   ) :: location

    debugLocStackSize=debugLocStackSize+1
    if (debugLocStackSize > debugStackSizeMaximum) call Galacticus_Error_Report('debug stack is not large enough'//{introspection:location})
    debugLocStack(debugLocStackSize)=trim(location)
    return
  end subroutine debugStackPushStr

  subroutine debugStackPushLoc(location)
    !% Push a numeric-location onto the debug location stack.
    use, intrinsic :: ISO_C_Binding   , only : c_size_t
    use            :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    integer  (c_size_t), intent(in   ) :: location
    character(len=24  )                :: locationStr
    
    debugLocStackSize=debugLocStackSize+1
    if (debugLocStackSize > debugStackSizeMaximum) call Galacticus_Error_Report('debug stack is not large enough'//{introspection:location})
    write (locationStr,'(i24)') location
    debugLocStack(debugLocStackSize)=trim(adjustl(locationStr))
    return
  end subroutine debugStackPushLoc

  subroutine debugStackPop()
    !% Pop a location off the debug stack.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    
    debugLocStackSize=debugLocStackSize-1
    if (debugLocStackSize < 0) call Galacticus_Error_Report('pop from empty debug stack'//{introspection:location})
    return
  end subroutine debugStackPop

  function debugStackGet()
    !% Get the current location from the debug stack.
    implicit none
    type(varying_string) :: debugStackGet
    
    if (debugLocStackSize <= 0) then 
       debugStackGet='[unknown]'
    else 
       debugStackGet=debugLocStack(debugLocStackSize)
    end if
    return
  end function debugStackGet
#endif
   
end module Function_Classes