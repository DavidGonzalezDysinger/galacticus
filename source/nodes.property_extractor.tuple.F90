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

  !# <nodePropertyExtractor name="nodePropertyExtractorTuple" abstract="yes">
  !#  <description>An abstract output analysis property extractor class which provieds a tuple of floating point properties.</description>
  !# </nodePropertyExtractor>
  type, extends(nodePropertyExtractorClass), abstract :: nodePropertyExtractorTuple
     !% A tuple property extractor.
     private
   contains
     !# <methods>
     !#   <method description="Return the number of properties in the tuple." method="elementCount" pass="yes" />
     !#   <method description="Extract the properties from the given {\normalfont \ttfamily node}." method="extract" pass="yes" />
     !#   <method description="Return the names of the properties extracted." method="names" pass="yes" />
     !#   <method description="Return descriptions of the properties extracted." method="descriptions" pass="yes" />
     !#   <method description="Return the units of the properties extracted in the SI system." method="unitsInSI" pass="yes" />
     !# </methods>
     procedure(tupleElementCount), deferred :: elementCount
     procedure(tupleExtract     ), deferred :: extract
     procedure(tupleNames       ), deferred :: names
     procedure(tupleNames       ), deferred :: descriptions
     procedure(tupleUnitsInSI   ), deferred :: unitsInSI
  end type nodePropertyExtractorTuple

  abstract interface
     function tupleExtract(self,node,time,instance)
       !% Interface for tuple property extraction.
       import nodePropertyExtractorTuple, treeNode, multiCounter
       double precision                            , dimension(:) , allocatable :: tupleExtract
       class           (nodePropertyExtractorTuple), intent(inout), target      :: self
       type            (treeNode                  ), intent(inout), target      :: node
       double precision                            , intent(in   )              :: time
       type            (multiCounter              ), intent(inout), optional    :: instance
     end function tupleExtract
  end interface

  abstract interface
     function tupleNames(self,time)
       !% Interface for tuple property names.
       import varying_string, nodePropertyExtractorTuple
       type            (varying_string            ), dimension(:) , allocatable :: tupleNames
       class           (nodePropertyExtractorTuple), intent(inout)              :: self
       double precision                            , intent(in   )              :: time
     end function tupleNames
  end interface

  abstract interface
     function tupleUnitsInSI(self,time)
       !% Interface for tuple property units.
       import nodePropertyExtractorTuple
       double precision                            , dimension(:) , allocatable :: tupleUnitsInSI
       class           (nodePropertyExtractorTuple), intent(inout)              :: self
       double precision                            , intent(in   )              :: time
     end function tupleUnitsInSI
  end interface

  abstract interface
     integer function tupleElementCount(self,time)
       !% Interface for tuple element count.
       import nodePropertyExtractorTuple
       class           (nodePropertyExtractorTuple), intent(inout) :: self
       double precision                            , intent(in   ) :: time
     end function tupleElementCount
  end interface
