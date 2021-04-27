#!/bin/bash
## tested with the following revisions:
##  -  7b6a6e25ccf4f5ea211ab297d08e6a40ec100351 of ugcore (master)
##  -  d256617e50ee98ab12756347df6b894be9a96c20 of neuro_collection (meshFixes)
##  -  193dbb5374ec1e9ad783c93cb7dc8b017c66237b of neuro_collection (fixMapping)

## mesh generation parameters (do change)
INFLATIONS=1
REFINEMENTS=1
SEGMENT_LENGTH=6
FILENAME=cylinder
BINARY=/home/stephan/Code/git/ug4/bin/ugshell 
FOLDERNAME=example

## fixed ug configuration parameters (do not change)
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
ug_load_script("ug_util.lua")
ug_load_script("util/load_balancing_util.lua")
InitUG(3, AlgebraType("CPU", 1))

mkdir -p example

# create inflations of 3d mesh
for (( inflation=1; ref < ${INFLATIONS}; ref++)); do 
   # create the 3d coarse mesh
   $BINARY -call "${SCRIPT_3D_VR}(\"${FILENAME}.swc\", false, 0.3, true, $SEGMENT_LENGTH, 0, true, $INFLATION, \"user\", $SEGMENT_LENGTH)"$
   mv after_selecting_boundary_elements.ugx example/${FILENAME%*.swc}_3d.ugx
   mv after_selecting_boundary_elements_tri.ugx example/${FILENAME%*.swc}_3d_tris.ugx

   ## TODO: translate this section to Lua
   dom = Domain()
   dom:create_additional_subset_handler("projSH")
   LoadDomain(dom, "after_selecting_boundary_elements.ugx")

   # create refinements of the 3d meshes and write corresponding 1d meshes
   axialMarker = NeuriteAxialRefinementMarker(dom)
   refiner = HangingNodeDomainRefiner(dom)
   for (( ref=0;  ref < ${REFINEMENTS}; ref++)); do
      SaveGrid(dom:grid(), example/${FILENAME%*.swc}_3d_x${inflation}_ref_${ref}.ugx)
      Write3dMeshTo1d(dom, $ref)
      mv 1dmesh.ugx example/${FILENAME%*.swc}_1d_ref_${ref}.ugx
      axialMarker:mark(refiner)
      refiner:refine()
   done
   ## TODO: translate this section to Lua
done

cat << EOF > ${FOLDERNAME}/MetaInfo.json
{
    "geom1d" : [
EOF

for (( ref=0;  ref < ${REFINEMENTS}; ref++)); do
cat << EOF >> ${FOLDERNAME}/MetaInfo.json
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_${ref}.ugx", "description": "1d mesh coarse mesh", "refinement": "$ref",
           "inflations" : [
EOF
for (( inflation=1; ref < $INFLATIONS; ref++)); do 
inflation=${INFLATIONS[$idx]}
cat << EOF >> ${FOLDERNAME}/MetaInfo.json
               { "name" : "${FILENAME}_segLength=${segLength1D}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" },
EOF
done
inflation=$INFLATIONS
cat << EOF >> ${FOLDERNAME}/MetaInfo.json
               { "name" : "${FILENAME}_segLength=${segLength1D}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" }
EOF

lastRef=$REFINEMENTS
if [ "$lastRef" = "$ref" ]; then
cat << EOF >> ${FOLDERNAME}/MetaInfo.json
           ]
         }
EOF
else
cat << EOF >> ${FOLDERNAME}/MetaInfo.json
           ]
         },
EOF
fi

done
cat << EOF >> ${FOLDERNAME}/${FILENAME}/MetaInfo.json
      ]
}
EOF

cd ${FOLDERNAME}
zip -j -x "*_wo_attachments.ugx" -x "*_3d_x*.ugx" -r ${FILENAME}.vrn MetaInfo.json *ugx
cd ../../
