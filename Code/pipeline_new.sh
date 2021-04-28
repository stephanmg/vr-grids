#!/bin/bash
## tested with the following revisions:
##  -  7b6a6e25ccf4f5ea211ab297d08e6a40ec100351 of ugcore (master)
##  -  d256617e50ee98ab12756347df6b894be9a96c20 of neuro_collection (meshFixes)
##  -  193dbb5374ec1e9ad783c93cb7dc8b017c66237b of neuro_collection (fixMapping)

## mesh generation parameters (do change)
INFLATIONS=1
REFINEMENTS=2
SEGMENT_LENGTH=6
SWC_FILE=cylinder
BINARY=/home/stephan/Code/git/ug4/bin/ugshell 
OUTPUT_FOLDER=example
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 

## create outout folder
mkdir -p "${OUTPUT_FOLDER}"

# create inflations of 3d mesh
for (( inflation=1; ref < ${INFLATIONS}; ref++)); do 
   # create the 3d coarse mesh
   $BINARY -call "${SCRIPT_3D_VR}(\"${SWC_FILE}.swc\", false, 0.3, true, $SEGMENT_LENGTH, 0, true, $inflation, \"user\", $SEGMENT_LENGTH)"

   # create the 3d refinements and write the 1d meshes (Lua script)
cat << EOF > ${OUTPUT_FOLDER}/geom.lua
-- init ug
ug_load_script("ug_util.lua")
ug_load_script("util/load_balancing_util.lua")
InitUG(3, AlgebraType("CPU", 1))

-- load domain
dom = Domain()
dom:create_additional_subset_handler("projSH")
LoadDomain(dom, "after_selecting_boundary_elements_with_projector.ugx")

-- create refinements of the 3d meshes
axialMarker = NeuriteAxialRefinementMarker(dom)
refiner = HangingNodeDomainRefiner(dom)
for ref=0, $((REFINEMENTS-1)) do
   SaveGridLevelToFile(dom:grid(), dom:subset_handler(), ref, "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_3d_x${inflation}_ref_" .. ref .. ".ugx")
   axialMarker:mark(refiner)
   refiner:refine()
end

-- create 1d meshes from 3d meshes
AddMappingAttachmentHandlerToGrid(dom)
for ref=0, $((REFINEMENTS-1)) do
   Write3dMeshTo1d(dom, ref)
end
EOF
   # execute ugshell
   $BINARY -ex ${OUTPUT_FOLDER}/geom.lua

   # copy 1d meshes to output folder
   for (( ref=0; ref < ${REFINEMENTS}; ref++)); do
      cp 1dmesh_${ref}.ugx ${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_1d_ref_${ref}.ugx
   done

   # remove attachments
   for (( ref=0; ref < ${REFINEMENTS}; ref++)); do
      sed '/.*vertex_attachment.*/d' "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_3d_x${inflation}_ref_${ref}.ugx" > "${FOLDERNAME}/${SWC_FILE%*.swc}_3d_x${inflation}_ref_${ref}_wo_attachments.ugx" 
   done
done

cat << EOF > ${OUTPUT_FOLDER}/MetaInfo.json
{
    "geom1d" : [
EOF

for (( ref=0;  ref < ${REFINEMENTS}; ref++)); do
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
         { "name" : "${SWC_FILE}_segLength=${segLength1D}_1d_ref_${ref}.ugx", "description": "1d mesh coarse mesh", "refinement": "$ref",
           "inflations" : [
EOF
for (( inflation=1; ref < $INFLATIONS; ref++)); do 
inflation=${INFLATIONS[$idx]}
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
               { "name" : "${SWC_FILE}_segLength=${segLength1D}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" },
EOF
done
inflation=$INFLATIONS
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
               { "name" : "${SWC_FILE}_segLength=${segLength1D}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" }
EOF

lastRef=$REFINEMENTS
if [ "$lastRef" = "$ref" ]; then
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
           ]
         }
EOF
else
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
           ]
         },
EOF
fi

done
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
      ]
}
EOF

cd ${OUTPUT_FOLDER}
zip -j -x "*_wo_attachments.ugx" -r ${SWC_FILE}.vrn MetaInfo.json *ugx
cd ../../
