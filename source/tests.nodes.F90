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

!% Contains a program which tests the \glspl{node} implementation.

program Test_Nodes
  !% Tests the \glspl{node} implementation.
  use :: Array_Utilities   , only : Array_Reverse
  use :: Galacticus_Display, only : Galacticus_Verbosity_Level_Set, verbosityStandard
  use :: Galacticus_Error  , only : Galacticus_Error_Report
  use :: Galacticus_Nodes  , only : nodeClassHierarchyFinalize    , nodeClassHierarchyInitialize, nodeComponent       , nodeComponentBasic, &
          &                         nodeComponentPosition         , propertyTypeAll             , treeNode
  use :: ISO_Varying_String, only : varying_string                , assignment(=)               , char
  use :: Input_Parameters  , only : inputParameters
  use :: Test_Nodes_Tasks  , only : Test_Node_Task
  use :: Unit_Tests        , only : Assert                        , Unit_Tests_Begin_Group      , Unit_Tests_End_Group, Unit_Tests_Finish
  implicit none
  type            (treeNode                     )                                     :: thisNode
  type            (treeNode                     )                           , pointer :: hostNode
  class           (nodeComponent                )                           , pointer :: thisComponent
  double precision                               , parameter                          :: propertyValueSet=1.23456789d0
  double precision                                            , dimension(2)          :: serializedArray
  double precision                               , allocatable, dimension(:)          :: propertyArray
  double precision                                                                    :: propertyValueGet
  type            (varying_string               )                                     :: parameterFile
  type            (inputParameters              )                                     :: parameters

  ! Set verbosity level.
  call Galacticus_Verbosity_Level_Set(verbosityStandard)
  ! Open the parameter file.
  parameterFile='testSuite/parameters/nodes/nodes.xml'
  parameters=inputParameters(parameterFile)
  call parameters%markGlobal()

  ! Begin unit tests.
  call Unit_Tests_Begin_Group("Nodes")

  ! Initialize the Galacticus nodes objects module.
  call nodeClassHierarchyInitialize(parameters)

  ! Ensure tree node has the correct type.
  call Assert('Node has type "treeNode"',char(thisNode%type()),'treeNode')

  ! Get the basic component of thisNode - assert that it is of the generic "nodeComponent" type since it has yet to be created.

  ! Create basic and spheroid components in thisNode.
  call thisNode%basicCreate   ()
  call thisNode%spheroidCreate()

  ! Get the basic component of the node - assert that it is of the expected type.
  thisComponent => thisNode%basic()
  call Assert('Created basic component has type "nodeComponent:basic:standard"',char(thisComponent%type()),'nodeComponent:basic:standard')

  ! Set and get a property (total mass) value.
  select type  (thisComponent)
     class is (nodeComponentBasic)
     call thisComponent%massSet(propertyValueSet)
     propertyValueGet=thisComponent%mass()
     call Assert('Set followed by get returns expected value',propertyValueGet,propertyValueSet)
     class default
     call Galacticus_Error_Report('component is of incorrect class'//{introspection:location})
  end select

  ! Get the spheroid component of the node - assert that it is of the expected type.
  thisComponent => thisNode%spheroid()
  call Assert('Created spheroid component has type "nodeComponent:spheroid:standard"',char(thisComponent%type()),'nodeComponent:spheroid:standard')

  ! Test setting and getting of 1-D arrays, with automatic allocation.
  thisComponent => thisNode%position(autoCreate=.true.)
  select type  (thisComponent)
  class is (nodeComponentPosition)
     call thisComponent%velocitySet([1.0d0,3.0d0,-12.3d0])
     propertyArray=thisComponent%velocity()
     call Assert('1D array property get/set consistency',propertyArray,[1.0d0,3.0d0,-12.3d0])
  class default
     call Galacticus_Error_Report('component is of incorrect class'//{introspection:location})
  end select

  ! Destroy the node.
  call thisNode%destroy()

  ! Create basic component automatically by getting it - assert that it is has the expected type.
  thisComponent => thisNode%basic(autoCreate=.true.)
  select type  (thisComponent)
     class is (nodeComponentBasic)
     call Assert('Auto-created basic component has type "nodeComponent:basic:standard"',char(thisComponent%type()),'nodeComponent:basic:standard')
     ! Ensure that the size of a scalar property is correctly reported.
     call Assert('Scalar property size',thisComponent%massCount(),1)
     class default
     call Galacticus_Error_Report('component is of incorrect class'//{introspection:location})
  end select

  ! Get the basic component from the spheroid component - assert that it has the expected type.
  hostNode      => thisComponent%host ()
  thisComponent => hostNode     %basic()
  call Assert('Basic component retrieved via spheroid component has type "nodeComponent:basic:standard"',char(thisComponent%type()),'nodeComponent:basic:standard')

  ! Get the tree node from the basic component - assert that it has the expected type.
  hostNode => thisComponent%host()
  call Assert('Node retrieved via basic component has type "treeNode"',char(hostNode%type()),'treeNode')

  ! Destroy the spheroid component.
  call thisNode%spheroidDestroy()

  !
  ! Test serialization functions.
  !

  ! Check that total count of properties is correct.
  call Assert('Total count of properties in tree node',thisNode%serializeCount(propertyTypeAll),2)

  ! Serialize values to and from an array - assert consistency between serialized and deserialized values.
  select type  (thisComponent)
  class is (nodeComponentBasic)
     call thisComponent%massSet(1.0d0)
     call thisComponent%timeSet(2.0d0)
     call thisNode%serializeValues  (serializedArray,propertyTypeAll)
     serializedArray=Array_Reverse  (serializedArray                )
     call thisNode%deserializeValues(serializedArray,propertyTypeAll)
     call Assert('Serialize/deserialize values consistency',[thisComponent%mass(),thisComponent%time()],[2.0d0,1.0d0])
  class default
     call Galacticus_Error_Report('component is of incorrect class'//{introspection:location})
  end select

  ! Check that we can create and retrieve instances of a component.
  thisComponent => thisNode%basic(instance=2)

  ! Execute an example  task.
  call Test_Node_Task(thisNode)

  ! Finalize the objects module. (Not strictly necessary, but it cleans up some allocations which otherwise get reported by
  ! Valgrind.)
  call nodeClassHierarchyFinalize()

  ! Clean up allocations to avoid them being reported by Valgrind.
  call parameterFile%destroy()

  ! End unit tests.
  call Unit_Tests_End_Group()
  call Unit_Tests_Finish   ()

end program Test_Nodes
