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

!% Contains a program to test root finding routines.

program Test_Root_Finding
  !% Tests that routine finding routines work.
  use :: Galacticus_Display         , only : Galacticus_Verbosity_Level_Set, verbosityStandard
  use :: Galacticus_Error           , only : errorStatusDivideByZero
  use :: Root_Finder                , only : rangeExpandAdditive           , rangeExpandMultiplicative, rangeExpandSignExpectPositive, rootFinder
  use :: Test_Root_Finding_Functions, only : Root_Function_1               , Root_Function_2          , Root_Function_2_Both         , Root_Function_2_Derivative, &
          &                                  Root_Function_3               , Root_Function_4          , Root_Function_4_Both         , Root_Function_4_Derivative
  use :: Unit_Tests                 , only : Assert                        , Unit_Tests_Begin_Group   , Unit_Tests_End_Group         , Unit_Tests_Finish
  implicit none
  type            (rootFinder)               :: finder1, finder2
  double precision                           :: xGuess , xRoot
  double precision            , dimension(2) :: xRange
  integer                                    :: status

  ! Set verbosity level.
  call Galacticus_Verbosity_Level_Set(verbosityStandard)

  ! Begin unit tests.
  call Unit_Tests_Begin_Group("Root finding")

  ! Test root finding.
  xRange=[-1.0d0,+1.0d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunction(Root_Function_1)
  xRoot=finder1%find(rootRange=xRange)
  call Assert('root of f(x)=x',xRoot,0.0d0,absTol=1.0d-6,relTol=1.0d-6)

  xRange=[-1.0d0,+1.0d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunction(Root_Function_2)
  xRoot=finder1%find(rootRange=xRange)
  call Assert('root of f(x)=x² - 5x + 1 in range -1 < x <  1',xRoot,0.5d0*(5.0d0-sqrt(21.0d0)),absTol=1.0d-6,relTol=1.0d-6)

  xRange=[-1.0d0,+1.0d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunctionDerivative(Root_Function_2,Root_Function_2_Derivative,Root_Function_2_Both)
  xRoot=finder1%find(rootRange=xRange)
  call Assert('root of f(x)=x² - 5x + 1 in range -1 < x <  1 [using derivative]',xRoot,0.5d0*(5.0d0-sqrt(21.0d0)),absTol=1.0d-6,relTol=1.0d-6)

  xRange=[2.0d0,10.0d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunction(Root_Function_2)
  xRoot=finder1%find(rootRange=xRange)
  call Assert('root of f(x)=x² - 5x + 1 in range  2 < x < 10',xRoot,0.5d0*(5.0d0+sqrt(21.0d0)),absTol=1.0d-6,relTol=1.0d-6)

  xRange=[-1.0d0,+1.0d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunction(Root_Function_3)
  xRoot=finder1%find(rootRange=xRange)
  call Assert('root of f(x)=x × exp(-x) + 1',xRoot,-0.567143d0,absTol=1.0d-6,relTol=1.0d-6)

  ! Test with root bracketing.
  xGuess=0.0d0
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rangeExpand(rangeExpandUpward=0.1d0,rangeExpandDownward=-0.1d0,rangeExpandType=rangeExpandAdditive)
  call finder1%rootFunction(Root_Function_3)
  xRoot=finder1%find(rootGuess=xGuess)
  call Assert('root of f(x)=x × exp(-x) + 1; with bracketing',xRoot,-0.567143d0,absTol=1.0d-6,relTol=1.0d-6)

  ! Test with root bracketing and limit.
  xGuess=0.0d0
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rangeExpand(rangeExpandUpward=0.1d0,rangeExpandDownward=-0.1d0,rangeExpandType=rangeExpandAdditive,rangeUpwardLimit=1.0d0,rangeDownwardLimit=-5.0d0)
  call finder1%rootFunction(Root_Function_3)
  xRoot=finder1%find(rootGuess=xGuess)
  call Assert('root of f(x)=x × exp(-x) + 1; with bracketing + limit',xRoot,-0.567143d0,absTol=1.0d-6,relTol=1.0d-6)

  ! Test root-finding of function with zero derivative using deriative based solver and error handling.
  xRange=[-2.0d0,-1.5d0]
  call finder1%tolerance(1.0d-6,1.0d-6)
  call finder1%rootFunctionDerivative(Root_Function_4,Root_Function_4_Derivative,Root_Function_4_Both)
  xRoot=finder1%find(rootRange=xRange,status=status)
  call Assert('root of f(x)=1 for |x|>1, x otherwise; in range -2 < x <  -1.5 [using derivative; divide-by-zero error expected]',status,errorStatusDivideByZero)

  ! Test regressions.
  xRange=[+2.0d0,+4.0d0]
  call finder2%tolerance(1.0d-6,1.0d-6)
  call finder2%rootFunction(Root_Function_2)
  call finder2%rangeExpand(rangeExpandUpward=2.0d0,rangeExpandUpwardSignExpect=rangeExpandSignExpectPositive,rangeExpandType=rangeExpandMultiplicative)
  xRoot=finder2%find(rootRange=xRange)
  call Assert('root of f(x)=x² - 5x + 1 in range  2 < x < 10 expand range upward only',xRoot,0.5d0*(5.0d0+sqrt(21.0d0)),absTol=1.0d-6,relTol=1.0d-6)

  ! End unit tests.
  call Unit_Tests_End_Group()
  call Unit_Tests_Finish()

end program Test_Root_Finding
