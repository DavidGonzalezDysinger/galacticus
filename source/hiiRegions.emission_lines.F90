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

!+    Contributions to this file made by:  Alex Merson.

!% Contains a module that provides functions for emission line calculations.

module HII_Region_Emission_Lines
  use :: ISO_Varying_String, only : varying_string
  implicit none
  private
  public :: emissionLineWavelength

  logical                                                     :: databaseInitialized=.false.
  type            (varying_string), allocatable, dimension(:) :: lineNames
  double precision                , allocatable, dimension(:) :: wavelengths

contains

  double precision function emissionLineWavelength(lineName)
    !% Return the wavelength of a named emission line.
    use :: Galacticus_Error  , only : Galacticus_Error_Report
    use :: ISO_Varying_String, only : operator(==)
    implicit none
    character(len=*), intent(in) :: lineName
    integer                      :: i

    ! Initialize the database.
    call emissionLineDatabaseInitialize()
    ! Locate the line in the database.
    do i=1,size(wavelengths)
       if (trim(lineName) == lineNames(i)) then
          emissionLineWavelength=wavelengths(i)
          return
       end if
    end do
    emissionLineWavelength=0.0d0
    call Galacticus_Error_Report('line "'//trim(lineName)//'" was not found in the database'//{introspection:location})
    return
  end function emissionLineWavelength

  subroutine emissionLineDatabaseInitialize()
    !% Initialize a database of emission line properties.
    use :: Galacticus_Paths  , only : galacticusPath, pathTypeDataStatic
    use :: IO_HDF5           , only : hdf5Object    , hdf5Access
    use :: ISO_Varying_String, only : char
    implicit none
    type   (hdf5Object) :: file   , lines, &
         &                 dataset
    integer             :: i

    if (.not.databaseInitialized) then
       !$omp critical (emissionLineDatabaseInitialize)
       if (.not.databaseInitialized) then
          !$ call hdf5Access%set()
          call file%openFile(char(galacticusPath(pathTypeDataStatic))//'hiiRegions/emissionLines.hdf5',readOnly=.true.)
          lines=file%openGroup("lines")
          call lines%datasets(lineNames)
          allocate(wavelengths(size(lineNames)))
          do i=1,size(lineNames)
             dataset=lines%openDataset(char(lineNames(i)))
             call dataset%readAttribute("wavelength",wavelengths(i))
             call dataset%close        (                           )
          end do
          call lines%close()
          call file %close()
          !$ call hdf5Access%unset()
          databaseInitialized=.true.
       end if
       !$omp end critical(emissionLineDatabaseInitialize)
    end if
    return
  end subroutine emissionLineDatabaseInitialize

end module HII_Region_Emission_Lines
