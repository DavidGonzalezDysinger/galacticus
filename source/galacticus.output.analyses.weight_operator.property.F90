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

!% Contains a module which implements an analysis weight operator class which weights by a property value.
  use Output_Analysis_Property_Extractions
  use Output_Analysis_Property_Operators
  
  !# <outputAnalysisWeightOperator name="outputAnalysisWeightOperatorProperty" defaultThreadPrivate="yes">
  !#  <description>An analysis weight operator class which weights by a property value.</description>
  !# </outputAnalysisWeightOperator>
  type, extends(outputAnalysisWeightOperatorClass) :: outputAnalysisWeightOperatorProperty
     !% An weight operator class which weights by a property value.
     private
     class(outputAnalysisPropertyExtractorClass), pointer :: extractor_
     class(outputAnalysisPropertyOperatorClass ), pointer :: operator_
   contains
     final     ::            propertyDestructor
     procedure :: operate => propertyOperate
  end type outputAnalysisWeightOperatorProperty

  interface outputAnalysisWeightOperatorProperty
     !% Constructors for the ``property'' output analysis class.
     module procedure propertyConstructorParameters
     module procedure propertyConstructorInternal
  end interface outputAnalysisWeightOperatorProperty

contains

  function propertyConstructorParameters(parameters) result(self)
    !% Constructor for the ``property'' output analysis weight operator class which takes a parameter set as input.
    use Input_Parameters2
    implicit none
    type (outputAnalysisWeightOperatorProperty)                :: self
    type (inputParameters                     ), intent(inout) :: parameters
    class(outputAnalysisPropertyExtractorClass), pointer       :: extractor_
    class(outputAnalysisPropertyOperatorClass ), pointer       :: operator_
    !# <inputParameterList label="allowedParameterNames" />
    
    ! Check and read parameters.
    call parameters%checkParameters(allowedParameterNames)
    !# <objectBuilder class="outputAnalysisPropertyExtractor" name="extractor_" source="parameters"/>
    !# <objectBuilder class="outputAnalysisPropertyOperator"  name="operator_"  source="parameters"/>
    ! Construct the object.
    self=outputAnalysisWeightOperatorProperty(extractor_,operator_)
    return
  end function propertyConstructorParameters

  function propertyConstructorInternal(extractor_,operator_) result(self)
    !% Internal constructor for the ``property'' output analysis weight operator class.
    implicit none
    type (outputAnalysisWeightOperatorProperty)                        :: self
    class(outputAnalysisPropertyExtractorClass), intent(in   ), target :: extractor_
    class(outputAnalysisPropertyOperatorClass ), intent(in   ), target :: operator_
    !# <constructorAssign variables="*extractor_, *operator_"/>

   return
  end function propertyConstructorInternal

  subroutine propertyDestructor(self)
    !% Destructor for the ``property'' output analysis weight operator class.
    implicit none
    type(outputAnalysisWeightOperatorProperty), intent(inout) :: self

    !# <objectDestructor name="self%extractor_"/>
    !# <objectDestructor name="self%operator_" />
    return
  end subroutine propertyDestructor
  
  double precision function propertyOperate(self,weightValue,node,propertyValue,propertyValueIntrinsic,propertyType,outputIndex)
    !% Implement an property output analysis weight operator.
    use, intrinsic :: ISO_C_Binding
    implicit none
    class           (outputAnalysisWeightOperatorProperty), intent(inout) :: self
    type            (treeNode                            ), intent(inout) :: node
    double precision                                      , intent(in   ) :: propertyValue      , propertyValueIntrinsic, &
         &                                                                   weightValue
    integer                                               , intent(in   ) :: propertyType
    integer         (c_size_t                            ), intent(in   ) :: outputIndex
    double precision                                                      :: weightPropertyValue
    integer                                                               :: weightPropertyType
    !GCC$ attributes unused :: propertyType, propertyValueIntrinsic, propertyValue

    weightPropertyValue=+self       %extractor_%extract(node                                                   )
    weightPropertyType = self       %extractor_%type   (                                                       )
    propertyOperate    =+self       %operator_ %operate(weightPropertyValue,node,weightPropertyType,outputIndex) &
         &              *weightValue
    return
  end function propertyOperate