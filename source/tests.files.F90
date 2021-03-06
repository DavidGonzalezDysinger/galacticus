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

!% Contains a program to test file functions.

program Test_Files
  !% Tests that file functions work.
  use :: File_Utilities    , only : File_Exists
  use :: Galacticus_Display, only : Galacticus_Verbosity_Level_Set, verbosityStandard
  use :: Galacticus_Paths  , only : galacticusPath                , pathTypeExec
  use :: ISO_Varying_String, only : operator(//)
  use :: Unit_Tests        , only : Assert                        , Unit_Tests_Begin_Group  , Unit_Tests_End_Group, Unit_Tests_Finish
  implicit none
 
  call Galacticus_Verbosity_Level_Set(verbosityStandard                                                                                 )
  call Unit_Tests_Begin_Group        ("File utilities"                                                                                  )
  call Assert                        ('file exists'        ,File_Exists(galacticusPath(pathTypeExec)//'source/tests.files.F90' ),.true. )
  call Assert                        ('file does not exist',File_Exists(galacticusPath(pathTypeExec)//'source/tests.bork.crump'),.false.)
  call Unit_Tests_End_Group          (                                                                                                  )
  call Unit_Tests_Finish             (                                                                                                  )
end program Test_Files
