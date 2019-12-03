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

  !% Contains a module which implements an N-body halo mass ratio output analysis distribution operator class.
  
  use :: Statistics_NBody_Halo_Mass_Errors, only : nbodyHaloMassErrorClass
  use :: Galactic_Filters                 , only : galacticFilterClass

  !# <outputAnalysisDistributionOperator name="outputAnalysisDistributionOperatorMassRatioNBody">
  !#  <description>A random error output analysis distribution operator class.</description>
  !# </outputAnalysisDistributionOperator>
  type, extends(outputAnalysisDistributionOperatorClass) :: outputAnalysisDistributionOperatorMassRatioNBody
     !% An N-body halo mass ratio output analysis distribution operator class.
     private
     class           (nbodyHaloMassErrorClass), pointer :: nbodyHaloMassError_ => null()
     class           (galacticFilterClass    ), pointer :: galacticFilter_     => null()
     double precision                                   :: massParentMinimum            , massParentMaximum, &
          &                                                timeParent     
   contains
     final     ::                        massRatioNBodyDestructor
     procedure :: operateScalar       => massRatioNBodyOperateScalar
     procedure :: operateDistribution => massRatioNBodyOperateDistribution
  end type outputAnalysisDistributionOperatorMassRatioNBody

  interface outputAnalysisDistributionOperatorMassRatioNBody
     module procedure massRatioNBodyConstructorParameters
     module procedure massRatioNBodyConstructorInternal
  end interface outputAnalysisDistributionOperatorMassRatioNBody
  
contains

  function massRatioNBodyConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily massRatioNBody} output analysis weight operator class which takes a parameter
    !% set as input.
    use :: Input_Parameters, only : inputParameters
    implicit none
    type            (outputAnalysisDistributionOperatorMassRatioNBody)                :: self
    type            (inputParameters                                 ), intent(inout) :: parameters
    class           (nbodyHaloMassErrorClass                         ), pointer       :: nbodyHaloMassError_
    class           (galacticFilterClass                             ), pointer       :: galacticFilter_
    double precision                                                                  :: massParentMinimum  , massParentMaximum, &
         &                                                                               timeParent

    !# <inputParameter>
    !#   <name>massParentMinimum</name>
    !#   <source>parameters</source>
    !#   <description>Minimum mass of the parent halo over which to integrate.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massParentMaximum</name>
    !#   <source>parameters</source>
    !#   <description>Maximum mass of the parent halo over which to integrate.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>timeParent</name>
    !#   <source>parameters</source>
    !#   <description>The time at which the parent halo is defined.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <objectBuilder class="nbodyHaloMassError" name="nbodyHaloMassError_" source="parameters"/>
    !# <objectBuilder class="galacticFilter"     name="galacticFilter_"     source="parameters"/>
    self=outputAnalysisDistributionOperatorMassRatioNBody(massParentMinimum,massParentMaximum,timeParent,nbodyHaloMassError_,galacticFilter_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="nbodyHaloMassError_"/>
    return
  end function massRatioNBodyConstructorParameters

  function massRatioNBodyConstructorInternal(massParentMinimum,massParentMaximum,timeParent,nbodyHaloMassError_,galacticFilter_) result (self)
    !% Internal constructor for the {\normalfont \ttfamily massRatioNBody} output analysis distribution operator class.
    use :: Galacticus_Error        , only : Galacticus_Error_Report
    use :: Node_Property_Extractors, only : nodePropertyExtractorClass, nodePropertyExtractorScalar
    implicit none
    type            (outputAnalysisDistributionOperatorMassRatioNBody)                        :: self
    double precision                                                  , intent(in   )         :: massParentMinimum  , massParentMaximum, &
         &                                                                                       timeParent
    class(nbodyHaloMassErrorClass                                    ), intent(in   ), target :: nbodyHaloMassError_
    class           (galacticFilterClass                             ), intent(in   ), target :: galacticFilter_
    !# <constructorAssign variables="massParentMinimum, massParentMaximum, timeParent, *nbodyHaloMassError_, *galacticFilter_"/>

    return
  end function massRatioNBodyConstructorInternal

  subroutine massRatioNBodyDestructor(self)
    !% Destructor for  the {\normalfont \ttfamily massRatioNBody} output analysis weight operator class.
    type(outputAnalysisDistributionOperatorMassRatioNBody), intent(inout) :: self

    !# <objectDestructor name="self%nbodyHaloMassError_"/>
    !# <objectDestructor name="self%galacticFilter_"    />
    return
  end subroutine massRatioNBodyDestructor

  function massRatioNBodyOperateScalar(self,propertyValue,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
    !% Implement an N-body mass ratio output analysis distribution operator.
    use :: Arrays_Search          , only : Search_Array
    use :: FGSL                   , only : fgsl_function                   , fgsl_integration_workspace
    use :: Galacticus_Error       , only : Galacticus_Error_Report
    use :: Galacticus_Nodes       , only : nodeComponentBasic
    use :: Numerical_Comparison   , only : Values_Agree
    use :: Numerical_Integration  , only : Integrate                       , Integrate_Done
    use :: Output_Analyses_Options, only : outputAnalysisPropertyTypeLinear, outputAnalysisPropertyTypeLog10
    implicit none
    class           (outputAnalysisDistributionOperatorMassRatioNBody), intent(inout)                                        :: self
    double precision                                                  , intent(in   )                                        :: propertyValue
    integer                                                           , intent(in   )                                        :: propertyType
    double precision                                                  , intent(in   ), dimension(:)                          :: propertyValueMinimum              , propertyValueMaximum
    integer         (c_size_t                                        ), intent(in   )                                        :: outputIndex
    type            (treeNode                                        ), intent(inout)                                        :: node
    double precision                                                                 , dimension(size(propertyValueMinimum)) :: massRatioNBodyOperateScalar
    double precision                                                  , parameter                                            :: timeTolerance              =1.0d-4
    double precision                                                  , parameter                                            :: integrationExtent          =1.0d+1
    type            (treeNode                                        ), pointer                                              :: nodeParent
    class           (nodeComponentBasic                              ), pointer                                              :: basic
    double precision                                                                                                         :: massUncertaintyRatio              , massUncertaintyParent      , &
         &                                                                                                                      massUncertaintyCorrelation        , massParent                 , &
         &                                                                                                                      massRatio                         , massUncertaintyRatioReduced, &
         &                                                                                                                      massRatioMinimum                  , massRatioMaximum           , &
         &                                                                                                                      massParentLimitLower              , massParentLimitUpper       , &
         &                                                                                                                      massRatioLimitLower               , massRatioLimitUpper
    integer         (c_size_t                                        )                                                       :: binIndex
    type            (fgsl_function                                   )                                                       :: integrandFunction
    type            (fgsl_integration_workspace                      )                                                       :: integrationWorkspace
    !GCC$ attributes unused :: outputIndex

    ! Get the parent halo mass.
    nodeParent => node%parent
    do while (associated(nodeParent))
       basic => nodeParent%basic()
       if (Values_Agree(basic%time(),self%timeParent,absTol=timeTolerance) .and. self%galacticFilter_%passes(nodeParent)) exit
       nodeParent => nodeParent%parent
    end do
    if (.not.associated(nodeParent)) call Galacticus_Error_Report('unable to find parent halo'//{introspection:location})
    massParent=basic%mass()
    ! Determine progenitor mass.
    select case (propertyType)
    case (outputAnalysisPropertyTypeLinear)
       massRatio=        propertyValue
    case (outputAnalysisPropertyTypeLog10)
       massRatio=10.0d0**propertyValue
    case default
       massRatio= 0.0d0
       call Galacticus_Error_Report('unsupported property type'//{introspection:location})
    end select
    ! Get the uncertainties and correlation of the masses.
    massUncertaintyRatio       =+self%nbodyHaloMassError_%errorFractional(node           )*massRatio
    massUncertaintyParent      =+self%nbodyHaloMassError_%errorFractional(     nodeParent)*massParent
    massUncertaintyCorrelation =+self%nbodyHaloMassError_%correlation    (node,nodeParent)
    massUncertaintyRatioReduced=+massUncertaintyRatio                                                 &
         &                      *sqrt(1.0d0-massUncertaintyCorrelation**2)
    ! Check for zero uncertainties.
    if (massUncertaintyRatio <= 0.0d0 .or. massUncertaintyParent <= 0.0d0) then
       ! Zero uncertainties - add the full weight to the bin if the progenitor and parent are within range.
       massRatioNBodyOperateScalar=0.0d0
       if (massParent <  self%massParentMinimum .or. massParent >=      self%massParentMaximum    ) return
       binIndex=Search_Array(propertyValueMinimum,propertyValue)
       if (binIndex   <= 0                      .or. binIndex   >  size(     propertyValueMinimum)) return
       if     (                                                 &
            &   propertyValue >= propertyValueMinimum(binIndex) &
            &  .and.                                            &
            &   propertyValue <  propertyValueMaximum(binIndex) &
            & ) massRatioNBodyOperateScalar(binIndex)=1.0d0
    else
       ! Integrate over the bivariate normal distribution to find the contribution to each bin in mass ratio.
       massParentLimitLower=max(                         &
            &                   +self%massParentMinimum, &
            &                   +massParent              &
            &                   -integrationExtent       &
            &                   *massUncertaintyParent   &
            &                  )
       massParentLimitUpper=min(                         &
            &                   +self%massParentMaximum, &
            &                   +massParent              &
            &                   +integrationExtent       &
            &                   *massUncertaintyParent   &
            &                  )
       if (massParentLimitUpper > massParentLimitLower) then
          do binIndex=1,size(propertyValueMinimum)
             select case (propertyType)
             case (outputAnalysisPropertyTypeLinear)
                massRatioMinimum=        propertyValueMinimum(binIndex)
                massRatioMaximum=        propertyValueMaximum(binIndex)
             case (outputAnalysisPropertyTypeLog10)
                massRatioMinimum=10.0d0**propertyValueMinimum(binIndex)
                massRatioMaximum=10.0d0**propertyValueMaximum(binIndex)
             case default
                massRatioMinimum= 0.0d0
                massRatioMaximum= 0.0d0
                call Galacticus_Error_Report('unsupported property type'//{introspection:location})
             end select
             massRatioLimitLower=+massRatioMinimum       &
                  &          -integrationExtent          &
                  &          *massUncertaintyRatio       &
                  &          +massUncertaintyCorrelation &
                  &          *(                          &
                  &            +massUncertaintyRatio     &
                  &            /massUncertaintyParent    &
                  &           )                          &
                  &          *(                          &
                  &            +massParentLimitLower     &
                  &            -massParent               &
                  &           )
             massRatioLimitUpper=+massRatioMaximum       &
                  &          +integrationExtent          &
                  &          *massUncertaintyRatio       &
                  &          +massUncertaintyCorrelation &
                  &          *(                          &
                  &            +massUncertaintyRatio     &
                  &            /massUncertaintyParent    &
                  &           )                          &
                  &          *(                          &
                  &            +massParentLimitUpper     &
                  &            -massParent               &
                  &           )
             if     (                                 &
                  &   massRatioLimitLower > massRatio &
                  &  .or.                             &
                  &   massRatioLimitUpper < massRatio &
                  & ) then
                massRatioNBodyOperateScalar(binIndex)=0.0d0
             else
                massRatioNBodyOperateScalar(binIndex)=max(                                                      &
                     &                                    Integrate(                                            &
                     &                                              massParentLimitLower                      , &
                     &                                              massParentLimitUpper                      , &
                     &                                              massRatioBivariateNormalIntegrand         , &
                     &                                              integrandFunction                         , &
                     &                                              integrationWorkspace                      , &
                     &                                              toleranceAbsolute                 =1.0d-10, &
                     &                                              toleranceRelative                 =1.0d-03  &
                     &                                             )                                          , &
                     &                                    0.0d0                                                 &
                     &                                   )
                call Integrate_Done(integrandFunction,integrationWorkspace)
             end if
          end do
       else
          massRatioNBodyOperateScalar=0.0d0
       end if
    end if
    return

  contains

    double precision function massRatioBivariateNormalIntegrand(massParentPrimed)
      !% Integrand used in finding the weight given to a bin in the space of parent mass vs. progenitor mass ratio.
      use :: Galacticus_Error        , only : Galacticus_Error_Report
      use :: Numerical_Constants_Math, only : Pi
      implicit none
      double precision, intent(in   ) :: massParentPrimed
      double precision                :: massRatioShifted
      
      ! Find the shifted mass ratio.
      massRatioShifted=+massRatio                  &
           &           +massUncertaintyCorrelation &
           &           *(                          &
           &             +massUncertaintyRatio     &
           &             /massUncertaintyParent    &
           &            )                          &
           &           *(                          &
           &             +massParentPrimed         &
           &             -massParent               &
           &            )
      ! Evaluate integrand. We divide through by the mass ratio here, such that our distribution is normalized to unity, but correctly accounts for the integral over mass ratio.
      massRatioBivariateNormalIntegrand=+(                                    &
           &                              +massRatioShifted                   &
           &                              *erf(                               &
           &                                   +(                             &
           &                                     +massRatioMaximum            &
           &                                     -massRatioShifted            &
           &                                    )                             &
           &                                   /sqrt(2.0d0)                   &
           &                                   /massUncertaintyRatioReduced   &
           &                                  )                               &
           &                              /2.0d0                              &
           &                              -massUncertaintyRatioReduced        &
           &                              *exp(                               &
           &                                   -(                             &
           &                                     +(                           &
           &                                       +massRatioMaximum          &
           &                                       -massRatioShifted          &
           &                                      )                           &
           &                                     /massUncertaintyRatioReduced &
           &                                    )**2                          &
           &                                   /2.0d0                         &
           &                                  )                               &
           &                              /sqrt(                              &
           &                                    +2.0d0                        &
           &                                    *Pi                           &
           &                                   )                              &
           &                              -massRatioShifted                   &
           &                              *erf(                               &
           &                                   +(                             &
           &                                     +massRatioMinimum            &
           &                                     -massRatioShifted            &
           &                                    )                             &
           &                                   /sqrt(2.0d0)                   &
           &                                   /massUncertaintyRatioReduced   &
           &                                  )                               &
           &                              /2.0d0                              &
           &                              +massUncertaintyRatioReduced        &
           &                              *exp(                               &
           &                                   -(                             &
           &                                     +(                           &
           &                                       +massRatioMinimum          &
           &                                       -massRatioShifted          &
           &                                      )                           &
           &                                     /massUncertaintyRatioReduced &
           &                                    )**2                          &
           &                                   /2.0d0                         &
           &                                  )                               &
           &                              /sqrt(                              &
           &                                    +2.0d0                        &
           &                                    *Pi                           &
           &                                   )                              &
           &                             )                                    &
           &                            /massRatio                            &
           &                            *exp(                                 &
           &                                 -0.5d0                           & 
           &                                 *(                               &
           &                                   +(                             &
           &                                     +massParentPrimed            &
           &                                     -massParent                  &
           &                                    )                             &
           &                                   /massUncertaintyParent         &
           &                                  )**2                            &
           &                                )                                 &
           &                            /sqrt(                                &
           &                                  +2.0d0                          &
           &                                  *Pi                             &
           &                                 )                                & 
           &                            /massUncertaintyParent
      return
    end function massRatioBivariateNormalIntegrand

  end function massRatioNBodyOperateScalar

  function massRatioNBodyOperateDistribution(self,distribution,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
    !% Implement an N-body mass ratio output analysis distribution operator.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class           (outputAnalysisDistributionOperatorMassRatioNBody), intent(inout)                                        :: self
    double precision                                                  , intent(in   ), dimension(:)                          :: distribution
    integer                                                           , intent(in   )                                        :: propertyType
    double precision                                                  , intent(in   ), dimension(:)                          :: propertyValueMinimum          , propertyValueMaximum
    integer         (c_size_t                                        ), intent(in   )                                        :: outputIndex
    type            (treeNode                                        ), intent(inout)                                        :: node
    double precision                                                                 , dimension(size(propertyValueMinimum)) :: massRatioNBodyOperateDistribution
    !GCC$ attributes unused :: self, distribution, propertyValueMinimum, propertyValueMaximum, outputIndex, propertyType, node

    massRatioNBodyOperateDistribution=0.0d0
    call Galacticus_Error_Report('not implemented'//{introspection:location})
    return
  end function massRatioNBodyOperateDistribution