!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015 Andrew Benson <abenson@obs.carnegiescience.edu>
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

!% Contains a module which provides a class that implements galactic filters.

module Galactic_Filters
  !% Provides an object that implements galactic filters.
  use Galacticus_Nodes
  private
  
  !# <functionClass>
  !#  <name>galacticFilter</name>
  !#  <descriptiveName>Galactic Filter</descriptiveName>
  !#  <description>Object providing boolean filters acting on galaxies.</description>
  !#  <default>always</default>
  !#  <stateful>yes</stateful>
  !#  <method name="passes" >
  !#   <description>Return true if the given {\normalfont \ttfamily node} passes the filter.</description>
  !#   <type>logical</type>
  !#   <pass>yes</pass>
  !#   <argument>type(treeNode), intent(inout) :: node</argument>
  !#  </method>
  !# </functionClass>
  
end module Galactic_Filters