!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

!% Contains a module which implements a filter which passes only isolated halos.

  !# <galacticFilter name="galacticFilterHaloIsolated">
  !#  <description>A filter which passes only isolated halos.</description>
  !# </galacticFilter>
  type, extends(galacticFilterClass) :: galacticFilterHaloIsolated
     !% A galactic high-pass filter class for basic mass.
     private
   contains
     procedure :: passes => haloIsolatedPasses
  end type galacticFilterHaloIsolated

  interface galacticFilterHaloIsolated
     !% Constructors for the ``haloIsolated'' galactic filter class.
     module procedure haloIsolatedConstructorParameters
  end interface galacticFilterHaloIsolated

contains

  function haloIsolatedConstructorParameters(parameters) result(self)
    !% Constructor for the ``haloIsolated'' galactic filter class which takes a parameter set as input.
    use Input_Parameters2
    implicit none
    type(galacticFilterHaloIsolated)                :: self
    type(inputParameters           ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters

    self=galacticFilterHaloIsolated()
    return
  end function haloIsolatedConstructorParameters

  logical function haloIsolatedPasses(self,node)
    !% Implement a  basic mass high-pass galactic filter.
    implicit none
    class(galacticFilterHaloIsolated), intent(inout) :: self
    type (treeNode                  ), intent(inout) :: node
    !GCC$ attributes unused :: self

    haloIsolatedPasses=.not.node%isSatellite()
    return
  end function haloIsolatedPasses