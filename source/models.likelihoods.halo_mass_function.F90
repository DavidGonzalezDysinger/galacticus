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
  
  !% Implementation of a posterior sampling likelihood class which implements a likelihood for halo mass functions.

  use Cosmology_Functions
  use Cosmology_Parameters
  use Cosmological_Density_Field
  use Dark_Matter_Halo_Scales
  use Dark_Matter_Profiles

  !# <posteriorSampleLikelihood name="posteriorSampleLikelihoodHaloMassFunction" defaultThreadPrivate="yes">
  !#  <description>A posterior sampling likelihood class which implements a likelihood for halo mass functions.</description>
  !# </posteriorSampleLikelihood>
  type, extends(posteriorSampleLikelihoodClass) :: posteriorSampleLikelihoodHaloMassFunction
     !% Implementation of a posterior sampling likelihood class which implements a likelihood for halo mass functions.
     private
     double precision                               , dimension(:  ), allocatable :: mass                     , massFunction     , &
          &                                                                          massMinimum              , massMaximum
     double precision                               , dimension(:,:), allocatable :: covarianceMatrix
     class           (cosmologyFunctionsClass      ), pointer                     :: cosmologyFunctions_
     class           (cosmologyParametersClass     ), pointer                     :: cosmologyParameters_
     class           (cosmologicalMassVarianceClass), pointer                     :: cosmologicalMassVariance_
     class           (criticalOverdensityClass     ), pointer                     :: criticalOverdensity_
     class           (darkMatterHaloScaleClass     ), pointer                     :: darkMatterHaloScale_
     class           (darkMatterProfileClass       ), pointer                     :: darkMatterProfile_
     class           (haloEnvironmentClass         ), pointer                     :: haloEnvironment_
     double precision                                                             :: time                     , massParticle     , &
          &                                                                          massRangeMinimum         , redshift     
     type            (vector                       )                              :: means
     type            (matrix                       )                              :: covariance               , inverseCovariance
     integer                                                                      :: errorModel
     type            (varying_string               )                              :: fileName                 , massFunctionType
     logical                                                                      :: environmentAveraged
   contains
     final     ::                    haloMassFunctionDestructor
     procedure :: evaluate        => haloMassFunctionEvaluate
     procedure :: functionChanged => haloMassFunctionFunctionChanged
  end type posteriorSampleLikelihoodHaloMassFunction

  interface posteriorSampleLikelihoodHaloMassFunction
     !% Constructors for the {\normalfont \ttfamily haloMassFunction} posterior sampling convergence class.
     module procedure haloMassFunctionConstructorParameters
     module procedure haloMassFunctionConstructorInternal
  end interface posteriorSampleLikelihoodHaloMassFunction

  ! Mass function error model enumeration.
  !# <enumeration>
  !#  <name>haloMassFunctionErrorModel</name>
  !#  <description>Used to specify the error model to use for halo mass function likelihoods.</description>
  !#  <visibility>private</visibility>
  !#  <validator>yes</validator>
  !#  <encodeFunction>yes</encodeFunction>
  !#  <entry label="none"                />
  !#  <entry label="powerLaw"            />
  !#  <entry label="sphericalOverdensity"/>
  !#  <entry label="trenti2010"          />
  !# </enumeration>
  
contains

  function haloMassFunctionConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily haloMassFunction} posterior sampling convergence class which builds the object from a
    !% parameter set.
    use Input_Parameters
    implicit none
    type            (posteriorSampleLikelihoodHaloMassFunction)          :: self
    type            (inputParameters                          )          :: parameters
    type            (varying_string                           )          :: fileName           , massFunctionType , &
         &                                                                  errorModel
    double precision                                                     :: redshift           , massRangeMinimum , &
         &                                                                  massParticle
    integer                                                              :: binCountMinimum
    logical                                                              :: environmentAveraged
    class           (cosmologyFunctionsClass                  ), pointer :: cosmologyFunctions_
    class           (cosmologyParametersClass                 ), pointer :: cosmologyParameters_
    class           (cosmologicalMassVarianceClass            ), pointer :: cosmologicalMassVariance_
    class           (criticalOverdensityClass                 ), pointer :: criticalOverdensity_
    class           (darkMatterHaloScaleClass                 ), pointer :: darkMatterHaloScale_
    class           (darkMatterProfileClass                   ), pointer :: darkMatterProfile_
    class           (haloEnvironmentClass                     ), pointer :: haloEnvironment_

    !# <inputParameter>
    !#   <name>fileName</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The name of the file containing the halo mass function.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>redshift</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The redshift at which to evaluate the halo mass function.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>massRangeMinimum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The minimum halo mass to include in the likelihood evaluation.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>binCountMinimum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The minimum number of halos per bin required to permit bin to be included in likelihood evaluation.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>massFunctionType</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The type of mass function () model to use.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>errorModel</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The error model to use for the halo mass function.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>massParticle</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The N-body particle mass.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>   
    !# <inputParameter>
    !#   <name>environmentAveraged</name>
    !#   <cardinality>1</cardinality>
    !#   <description>If true, the mass function will ve averaged over all environments.</description>
    !#   <source>parameters</source>
    !#   <type>boolean</type>
    !# </inputParameter>   
    !# <objectBuilder class="cosmologyFunctions"       name="cosmologyFunctions_"       source="parameters"/>
    !# <objectBuilder class="cosmologyParameters"      name="cosmologyParameters_"      source="parameters"/>
    !# <objectBuilder class="cosmologicalMassVariance" name="cosmologicalMassVariance_" source="parameters"/>
    !# <objectBuilder class="criticalOverdensity"      name="criticalOverdensity_"      source="parameters"/>
    !# <objectBuilder class="darkMatterHaloScale"      name="darkMatterHaloScale_"      source="parameters"/>
    !# <objectBuilder class="darkMatterProfile"        name="darkMatterProfile_"        source="parameters"/>
    !# <objectBuilder class="haloEnvironment"          name="haloEnvironment_"         source="parameters"/>
    self=posteriorSampleLikelihoodHaloMassFunction(char(fileName),redshift,massRangeMinimum,binCountMinimum,char(massFunctionType),enumerationHaloMassFunctionErrorModelEncode(char(errorModel),includesPrefix=.false.),massParticle,environmentAveraged,cosmologyFunctions_,cosmologyParameters_,cosmologicalMassVariance_,criticalOverdensity_,darkMatterHaloScale_,darkMatterProfile_,haloEnvironment_)
    !# <inputParametersValidate source="parameters"/>
    return
  end function haloMassFunctionConstructorParameters

  function haloMassFunctionConstructorInternal(fileName,redshift,massRangeMinimum,binCountMinimum,massFunctionType,errorModel,massParticle,environmentAveraged,cosmologyFunctions_,cosmologyParameters_,cosmologicalMassVariance_,criticalOverdensity_,darkMatterHaloScale_,darkMatterProfile_,haloEnvironment_) result(self)
    !% Constructor for ``haloMassFunction'' posterior sampling likelihood class.
    use IO_HDF5
    use Galacticus_Error
    use Memory_Management
    use Galacticus_Display
    implicit none
    type            (posteriorSampleLikelihoodHaloMassFunction)                                :: self
    character       (len=*                                    ), intent(in   )                 :: fileName                      , massFunctionType
    double precision                                           , intent(in   )                 :: redshift                      , massRangeMinimum , &
         &                                                                                        massParticle
    integer                                                    , intent(in   )                 :: binCountMinimum               , errorModel
    logical                                                    , intent(in   )                 :: environmentAveraged
    class           (cosmologyFunctionsClass                  ), intent(in   ), target         :: cosmologyFunctions_
    class           (cosmologyParametersClass                 ), intent(in   ), target         :: cosmologyParameters_
    class           (cosmologicalMassVarianceClass            ), intent(in   ), target         :: cosmologicalMassVariance_
    class           (criticalOverdensityClass                 ), intent(in   ), target         :: criticalOverdensity_
    class           (darkMatterHaloScaleClass                 ), intent(in   ), target         :: darkMatterHaloScale_
    class           (darkMatterProfileClass                   ), intent(in   ), target         :: darkMatterProfile_
    class           (haloEnvironmentClass                     ), intent(in   ), target         :: haloEnvironment_
    double precision                                           , allocatable  , dimension(:  ) :: eigenValueArray               , massOriginal     , &
         &                                                                                        massFunctionOriginal
    double precision                                           , allocatable  , dimension(:,:) :: massFunctionCovarianceOriginal
    character       (len=12                                   )                                :: redshiftLabel                 , typeLabel
    type            (hdf5Object                               )                                :: massFunctionFile              , massFunctionGroup, &
         &                                                                                        analysisGroup
    integer                                                                                    :: i                             , j                , &
         &                                                                                        ii                            , jj               , &
         &                                                                                        massCountReduced
    double precision                                                                           :: massIntervalLogarithmic
    type            (matrix                                   )                                :: eigenVectors
    type            (vector                                   )                                :: eigenValues
    !# <constructorAssign variables="fileName, redshift, massRangeMinimum, massFunctionType, errorModel, massParticle, environmentAveraged, *cosmologyFunctions_, *cosmologyParameters_, *cosmologicalMassVariance_, *criticalOverdensity_, *darkMatterHaloScale_, *darkMatterProfile_, *haloEnvironment_"/>
    
    ! Convert redshift to time.
    self%time=self%cosmologyFunctions_ %cosmicTime                (          &
         &    self%cosmologyFunctions_%expansionFactorFromRedshift (         &
         &                                                          redshift &
         &                                                         )         &
         &                                                        )
    ! Read the halo mass function file.
    write (redshiftLabel,'(f6.3)') redshift
    select case (trim(massFunctionType))
    case ("regular" )
       typeLabel="halo"
    case ("isolated")
       typeLabel="isolatedHalo"
    case default
       call Galacticus_Error_Report('unknown mass function type'//{introspection:location})
    end select
    !$omp critical(HDF5_Access)
    call massFunctionFile %openFile(trim(fileName),readOnly=.true.)
    analysisGroup    =massFunctionFile%openGroup('analysis'                                               )
    massFunctionGroup=analysisGroup   %openGroup(trim(typeLabel)//'MassFunctionZ'//trim(adjustl(redshiftLabel)))
    call massFunctionGroup%readDataset("mass"                  ,massOriginal                  )
    call massFunctionGroup%readDataset("massFunction"          ,massFunctionOriginal          )
    call massFunctionGroup%readDataset("massFunctionCovariance",massFunctionCovarianceOriginal)
    call massFunctionGroup%close()
    call analysisGroup    %close()
    call massFunctionFile %close()
    !$omp end critical(HDF5_Access)
    ! Find a reduced mass function excluding any empty bins.
    massCountReduced=0
    do i=1,size(massOriginal)
       if (     massFunctionOriginal          (i  )  <= 0.0d0                                              ) cycle
       if (     massOriginal                  (i  )  <= massRangeMinimum                                   ) cycle
       if (sqrt(massFunctionCovarianceOriginal(i,i)) >= massFunctionOriginal(i)/sqrt(dble(binCountMinimum))) cycle
       massCountReduced=massCountReduced+1
    end do
    if (massCountReduced == 0) call Galacticus_Error_Report('no usable bins in mass function'//{introspection:location})  
    call allocateArray(self%mass            ,[massCountReduced                 ])
    call allocateArray(self%massFunction    ,[massCountReduced                 ])
    call allocateArray(self%covarianceMatrix,[massCountReduced,massCountReduced])
    ii=0
    do i=1,size(massOriginal)
       if (     massFunctionOriginal          (i  )  <= 0.0d0                                              ) cycle
       if (     massOriginal                  (i  )  <= massRangeMinimum                                   ) cycle
       if (sqrt(massFunctionCovarianceOriginal(i,i)) >= massFunctionOriginal(i)/sqrt(dble(binCountMinimum))) cycle
       ii=ii+1
       self%mass        (ii)=massOriginal        (i)
       self%massFunction(ii)=massFunctionOriginal(i)
       jj=0
       do j=1,size(massOriginal)
          if (     massFunctionOriginal          (j  )  <= 0.0d0                                              ) cycle
          if (     massOriginal                  (j  )  <= massRangeMinimum                                   ) cycle
          if (sqrt(massFunctionCovarianceOriginal(j,j)) >= massFunctionOriginal(j)/sqrt(dble(binCountMinimum))) cycle
          jj=jj+1
          self%covarianceMatrix(ii,jj)=massFunctionCovarianceOriginal(i,j)        
       end do
    end do
    ! Compute mass ranges for bins.
    massIntervalLogarithmic=+log(                                  &
         &                       +massOriginal(size(massOriginal)) &
         &                       /massOriginal(                 1) &
         &                      )                                  &
         &                  /dble(                                 &
         &                        +size(massOriginal)              &
         &                        -1                               &
         &                       )
    call allocateArray(self%massMinimum,shape(self%mass))
    call allocateArray(self%massMaximum,shape(self%mass))
    do i=1,size(self%mass)
       self%massMinimum(i)=self%mass(i)*exp(-0.5d0*massIntervalLogarithmic)
       self%massMaximum(i)=self%mass(i)*exp(+0.5d0*massIntervalLogarithmic)
    end do
    ! Find the inverse covariance matrix.
    self%covariance       =self%covarianceMatrix
    self%inverseCovariance=self%covariance      %invert()
    ! Symmetrize the inverse covariance matrix.
    call self%inverseCovariance%symmetrize()
    ! Get eigenvalues and vectors of the inverse covariance matrix.
    allocate(eigenValueArray(size(self%mass)))
    call self%inverseCovariance%eigenSystem(eigenVectors,eigenValues)
    eigenValueArray=eigenValues
    if (any(eigenValueArray < 0.0d0)) call Galacticus_Display_Message('WARNING: inverse covariance matrix is not semi-positive definite')
    deallocate(eigenValueArray               )
    deallocate(massOriginal                  )
    deallocate(massFunctionOriginal          )
    deallocate(massFunctionCovarianceOriginal)
    return
  end function haloMassFunctionConstructorInternal
  
  subroutine haloMassFunctionDestructor(self)
    !% Destructor for ``haloMassFunction'' posterior sampling likelihood class.
    implicit none
    type(posteriorSampleLikelihoodHaloMassFunction), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyFunctions_"      />
    !# <objectDestructor name="self%cosmologyParameters_"     />
    !# <objectDestructor name="self%cosmologicalMassVariance_"/>
    !# <objectDestructor name="self%criticalOverdensity_"     />
    !# <objectDestructor name="self%darkMatterHaloScale_"     />
    !# <objectDestructor name="self%darkMatterProfile_"       />
    !# <objectDestructor name="self%haloEnvironment_"         />
    return
  end subroutine haloMassFunctionDestructor
  
  double precision function haloMassFunctionEvaluate(self,simulationState,modelParametersActive_,modelParametersInactive_,simulationConvergence,temperature,logLikelihoodCurrent,logPriorCurrent,logPriorProposed,timeEvaluate,logLikelihoodVariance)
    !% Return the log-likelihood for the halo mass function likelihood function.
    use MPI_Utilities
    use Posterior_Sampling_State
    use Models_Likelihoods_Constants
    use Posterior_Sampling_Convergence
    use Galacticus_Error
    use Halo_Mass_Functions
    use Statistics_NBody_Halo_Mass_Errors
    implicit none
    class           (posteriorSampleLikelihoodHaloMassFunction), intent(inout)               :: self
    class           (posteriorSampleStateClass                ), intent(inout)               :: simulationState
    type            (modelParameterList                       ), intent(in   ), dimension(:) :: modelParametersActive_          , modelParametersInactive_
    class           (posteriorSampleConvergenceClass          ), intent(inout)               :: simulationConvergence
    double precision                                           , intent(in   )               :: temperature                     , logLikelihoodCurrent   , &
         &                                                                                      logPriorCurrent                 , logPriorProposed
    real                                                       , intent(inout)               :: timeEvaluate
    double precision                                           , intent(  out), optional     :: logLikelihoodVariance
    double precision                                           , allocatable  , dimension(:) :: stateVector                     , massFunction
    double precision                                           , parameter                   :: errorFractionalMaximum    =1.0d1
    class           (nbodyHaloMassErrorClass                  ), pointer                     :: nbodyHaloMassError_
    class           (haloMassFunctionClass                    ), pointer                     :: haloMassFunctionRaw_            , haloMassFunctionAveraged_, &
         &                                                                                      haloMassFunctionConvolved_
    type            (vector                                   )                              :: difference
    integer                                                                                  :: i
    !GCC$ attributes unused :: simulationConvergence, temperature, timeEvaluate, logLikelihoodCurrent, logPriorCurrent, modelParametersInactive_

    ! There is no variance in our likelihood estimate.
    if (present(logLikelihoodVariance)) logLikelihoodVariance=0.0d0
    ! Do not evaluate if the proposed prior is impossible.
    if (logPriorProposed <= logImpossible) then
       haloMassFunctionEvaluate=0.0d0
       return
    end if
    ! Build the halo mass function object.
    stateVector=simulationState%get()
    do i=1,size(stateVector)
       stateVector(i)=modelParametersActive_(i)%modelParameter_%unmap(stateVector(i))
    end do
    ! Construct the raw mass function.
    allocate(haloMassFunctionShethTormen :: haloMassFunctionRaw_)
    select type (haloMassFunctionRaw_)
    type is (haloMassFunctionShethTormen)
       haloMassFunctionRaw_=haloMassFunctionShethTormen(                                   &
            &                                           self%cosmologyParameters_        , &
            &                                           self%cosmologicalMassVariance_   , &
            &                                           self%criticalOverdensity_        , &
            &                                           stateVector                   (1), &
            &                                           stateVector                   (2), &
            &                                           stateVector                   (3)  &
            &                                          )
    end select
    ! If averaging over environment, build the averager.
    if (self%environmentAveraged) then
       allocate(haloMassFunctionEnvironmentAveraged :: haloMassFunctionAveraged_)
       select type (haloMassFunctionAveraged_)
       type is (haloMassFunctionEnvironmentAveraged)
          haloMassFunctionAveraged_=haloMassFunctionEnvironmentAveraged(                           &
               &                                                             haloMassFunctionRaw_, &
               &                                                        self%haloEnvironment_    , &
               &                                                        self%cosmologyParameters_  &
               &                                                       )
       end select
    else
       haloMassFunctionAveraged_ => haloMassFunctionRaw_
    end if
    ! If convolving with an error distribution, build the error model.
    select case (self%errorModel)
    case (haloMassFunctionErrorModelNone                )
       if (size(stateVector) /= 3 )                                                                   &
            & call Galacticus_Error_Report(                                                           & 
            &                              '3 parameters are required for this likelihood function'// &
            &                              {introspection:location}                                   &
            &                             )
       haloMassFunctionConvolved_ => haloMassFunctionAveraged_
    case (haloMassFunctionErrorModelPowerLaw            )
       if (size(stateVector) /= 6 )                                                                   &
            & call Galacticus_Error_Report(                                                           & 
            &                              '6 parameters are required for this likelihood function'// &
            &                              {introspection:location}                                   &
            &                             )
       allocate(nbodyHaloMassErrorPowerLaw :: nbodyHaloMassError_)
       select type (nbodyHaloMassError_)
       type is (nbodyHaloMassErrorPowerLaw)
          nbodyHaloMassError_=nbodyHaloMassErrorPowerLaw(                &
               &                                         stateVector(4), &
               &                                         stateVector(5), &
               &                                         stateVector(6)  &
               &                                        )
       end select
       allocate(haloMassFunctionErrorConvolved :: haloMassFunctionConvolved_)
       select type (haloMassFunctionConvolved_)
       type is (haloMassFunctionErrorConvolved)
          haloMassFunctionConvolved_   =haloMassFunctionErrorConvolved(                              &
               &                                                       haloMassFunctionAveraged_   , &
               &                                                       self%cosmologyParameters_   , &
               &                                                       nbodyHaloMassError_         , &
               &                                                       errorFractionalMaximum        &
               &                                                      )
       end select
       nullify(nbodyHaloMassError_)
    case (haloMassFunctionErrorModelSphericalOverdensity)
       if (size(stateVector) /= 3 )                                                                   &
            & call Galacticus_Error_Report(                                                           & 
            &                              '3 parameters are required for this likelihood function'// &
            &                              {introspection:location}                                   &
            &                             )
       ! Use a mass function convolved with an error model for spherical overdensity algorithm errors.
       allocate(nbodyHaloMassErrorSOHaloFinder :: nbodyHaloMassError_)
       select type (nbodyHaloMassError_)
       type is (nbodyHaloMassErrorSOHaloFinder)
          nbodyHaloMassError_=nbodyHaloMassErrorSOHaloFinder(                           &
               &                                             self%darkMatterHaloScale_, &
               &                                             self%darkMatterProfile_  , &
               &                                             self%massParticle          &
               &                                            )
       end select
       allocate(haloMassFunctionErrorConvolved :: haloMassFunctionConvolved_)
       select type (haloMassFunctionConvolved_)
       type is (haloMassFunctionErrorConvolved)
          haloMassFunctionConvolved_=haloMassFunctionErrorConvolved(                              &
               &                                                    haloMassFunctionAveraged_   , &
               &                                                    self%cosmologyParameters_   , &
               &                                                    nbodyHaloMassError_         , &
               &                                                    errorFractionalMaximum        &
               &                                                   )
       end select
       nullify(nbodyHaloMassError_)
    case (haloMassFunctionErrorModelTrenti2010          )
       if (size(stateVector) /= 3 )                                                                   &
            & call Galacticus_Error_Report(                                                           & 
            &                              '3 parameters are required for this likelihood function'// &
            &                              {introspection:location}                                   &
            &                             )
       ! Use a mass function convolved with the error model from Trenti et al. (2010).
       allocate(nbodyHaloMassErrorTrenti2010 :: nbodyHaloMassError_)
       select type (nbodyHaloMassError_)
       type is (nbodyHaloMassErrorTrenti2010)
          nbodyHaloMassError_=nbodyHaloMassErrorTrenti2010(                  &
               &                                           self%massParticle &
               &                                          )
       end select
       allocate(haloMassFunctionErrorConvolved :: haloMassFunctionConvolved_)
       select type (haloMassFunctionConvolved_)
       type is (haloMassFunctionErrorConvolved)
          haloMassFunctionConvolved_=haloMassFunctionErrorConvolved(                              &
               &                                                    haloMassFunctionAveraged_   , &
               &                                                    self%cosmologyParameters_   , &
               &                                                    nbodyHaloMassError_         , &
               &                                                    errorFractionalMaximum        &
               &                                                   )
       end select
       nullify(nbodyHaloMassError_)
    end select
    ! Compute the mass function.
    allocate(massFunction(size(self%mass)))
    do i=1,size(self%mass)
       massFunction(i)=+haloMassFunctionAveraged_%integrated(                     &
            &                                                self%time          , &
            &                                                self%massMinimum(i), &
            &                                                self%massMaximum(i)  &
            &                                               )                     &
            &          /log(                                                      &
            &                                               +self%massMaximum(i)  &
            &                                               /self%massMinimum(i)  &
            &              )
    end do
    ! Evaluate the log-likelihood.
    difference              =massFunction-self%massFunction
    haloMassFunctionEvaluate=-0.5d0*(difference*(self%inverseCovariance*difference))
    ! Clean up.
    deallocate(stateVector )
    deallocate(massFunction)
    return    
  end function haloMassFunctionEvaluate

  subroutine haloMassFunctionFunctionChanged(self)
    !% Respond to possible changes in the likelihood function.
    implicit none
    class(posteriorSampleLikelihoodHaloMassFunction), intent(inout) :: self
    !GCC$ attributes unused :: self

    return
  end subroutine haloMassFunctionFunctionChanged