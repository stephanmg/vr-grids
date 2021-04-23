#!/bin/bash
## tested with the following revisions:
##  -  7b6a6e25ccf4f5ea211ab297d08e6a40ec100351 of ugcore (master)
##  -  d256617e50ee98ab12756347df6b894be9a96c20 of neuro_collection (meshFixes)
##  -  193dbb5374ec1e9ad783c93cb7dc8b017c66237b of neuro_collection (fixMapping)

## mesh generation parameters (do change)
INFLATIONS=1
REFINEMENTS=1
SEGMENT_LENGTH=6
FILENAME=single_branch.swc
BINARY=../bin/ugshell 

## fixed ug configuration parameters (do not change)
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
ug_load_script("ug_util.lua")
ug_load_script("util/load_balancing_util.lua")
InitUG(3, AlgebraType("CPU", 1))

# create inflations of 3d mesh
for (( inflation=1; ref < ${INFLATIONS}; ref++)); do 
   # create the 3d coarse mesh
   $BINARY -call "${SCRIPT_3D_VR}(\"${FILENAME}.swc\", false, 0.3, true, $SEGMENT_LENGTH, 0, true, $INFLATION, \"user\", $SEGMENT_LENGTH)"$
   dom = Domain()
   dom:create_additional_subset_handler("projSH")
   LoadDomain(dom, "after_selecting_boundary_elements.ugx")
   mv after_selecting_boundary_elements.ugx ${FILENAME%*.swc}_3d.ugx

   # create refinements of the 3d meshes and write corresponding 1d meshes
   axialMarker = NeuriteAxialRefinementMarker(dom)
   refiner = HangingNodeDomainRefiner(dom)
   for (( ref=1;  ref < ${REFINEMETNS}; ref++)); do
      axialMarker:mark(refiner)
      refiner:refine()
      SaveGrid(dom:grid(), ${FILENAME%*.swc}_3d_${ref}.ugx)
      Write3dMeshTo1d(dom)
      mv 1dmesh.ugx ${FILENAME%*.swc}_1d_ref_${ref}.ugx
   done
done

# TODO: package all meshes into VRN archive
