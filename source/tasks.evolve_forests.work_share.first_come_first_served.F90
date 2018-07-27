!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018
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

  use MPI_Utilities
  
  !# <evolveForestsWorkShare name="evolveForestsWorkShareFCFS" defaultThreadPrivate="yes">
  !#  <description>A forest evolution work sharing class in which forests are assigned on a first-come-first-served basis.</description>
  !# </evolveForestsWorkShare>
  type, extends(evolveForestsWorkShareClass) :: evolveForestsWorkShareFCFS
     !% Implementation of a forest evolution work sharing class in which forests are assigned on a first-come-first-served basis.
     private
   contains
     procedure :: forestNumber => fcfsForestNumber
  end type evolveForestsWorkShareFCFS

  interface evolveForestsWorkShareFCFS
     !% Constructors for the {\normalfont \ttfamily fcfs} forest evolution work sharing class.
     module procedure fcfsConstructorParameters
     module procedure fcfsConstructorInternal
  end interface evolveForestsWorkShareFCFS

  ! Global counter of forests assigned.
  type(mpiCounter) :: fcfsForestCounter
  
contains

  function fcfsConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily fcfs} forest evolution work sharing class which takes a parameter set as
    !% input.
    use Input_Parameters
    implicit none
    type(evolveForestsWorkShareFCFS)                :: self
    type(inputParameters           ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters
    
    self=evolveForestsWorkShareFCFS()
    return
  end function fcfsConstructorParameters

  function fcfsConstructorInternal() result(self)
    !% Internal constructor for the {\normalfont \ttfamily fcfs} forest evolution work sharing class.
    implicit none
    type(evolveForestsWorkShareFCFS) :: self
    !GCC$ attributes unused :: self
    
    fcfsForestCounter=mpiCounter()
    return
  end function fcfsConstructorInternal

  function fcfsForestNumber(self,utilizeOpenMPThreads)
    !% Return the number of the next forest to process.
#ifdef USEMPI
    use Galacticus_Error
#endif
    implicit none
    integer(c_size_t                  )                :: fcfsForestNumber
    class  (evolveForestsWorkShareFCFS), intent(inout) :: self
    logical                            , intent(in   ) :: utilizeOpenMPThreads
    !GCC$ attributes unused :: self, utilizeOpenMPThreads
    
    fcfsForestNumber=fcfsForestCounter%increment()+1_c_size_t
    return
  end function fcfsForestNumber