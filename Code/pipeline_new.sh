#!/bin/bash
## tested with the following revisions:
##  -  7b6a6e25ccf4f5ea211ab297d08e6a40ec100351 of ugcore (master)
##  -  d256617e50ee98ab12756347df6b894be9a96c20 of neuro_collection (meshFixes)
##  -  193dbb5374ec1e9ad783c93cb7dc8b017c66237b of neuro_collection (fixMapping)
## 
## relies on the following new functionalities in ug4/neuro_collection: 
##    NeuriteAxialRefinementMarker and MappingAttachmentHandler for 3d resp.
##    Write3dMeshTo1d and a correctly defined mapping for 1d mesh generation
## refines until geometry is isotropic, then refines the geometry globally.

## mesh generation parameters (do change)
INFLATIONS=1
REFINEMENTS=4
SEGMENT_LENGTH=6
SWC_FILE=single_branch
BINARY=/home/stephan/Code/git/ug4/bin/ugshell 
OUTPUT_FOLDER=example22

## fixed parameters (do not need to change usually)
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
MODE=identity # or identity / user

## create outout folder for meshes
mkdir -p "${OUTPUT_FOLDER}"

# create inflations of 3d mesh
for (( inflation=1; ref < ${INFLATIONS}; ref++)); do 
   # create the 3d coarse mesh
   $BINARY -call "${SCRIPT_3D_VR}(\"${SWC_FILE}.swc\", false, 0.3, true, $SEGMENT_LENGTH, 0, true, $inflation, \"$MODE\", $SEGMENT_LENGTH)"

   # create the 3d refinements and write the 1d meshes
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
offset = 0

-- required to propagate mapping attachments in refinements
--AddMappingAttachmentHandlerToGrid(dom)

-- axial refinements
for ref=0, $((REFINEMENTS-1)) do
   SaveGridLevelToFile(dom:grid(), dom:subset_handler(), ref, "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_" .. ref .. ".ugx")
   -- axialMarker:mark_exclusive_one(refiner, "Soma")
   if not pcall(function(ref_) axialMarker:mark(ref_) end, refiner) then
      offset=$((REFINEMENTS-1))-ref
      break
   else
      refiner:refine()
   end
end

-- global refinements, more axial refinements would make the geometry anistropic
delete(axialMarker)
for ref=offset, $((REFINEMENTS-1)) do
   refiner = GlobalDomainRefiner(dom)
   if not pcall(function() refiner:refine() end) then
      error("Global refinement #" .. $((REFINEMENTS-1))-ref .. " failed!")
   end
end

-- create 1d meshes from 3d meshes
for ref=0, $((REFINEMENTS-1))-offset do
   if not pcall(function() Write3dMeshTo1d(dom, ref) end) then
      error("Writing refinement # " .. ref .. " of 3d mesh to 1d mesh failed!")
   end
end
EOF

   # execute ugshell with generated meshing script
   $BINARY -ex ${OUTPUT_FOLDER}/geom.lua

   # copy 1d meshes to output folder
   for (( ref=0; ref < ${REFINEMENTS}; ref++)); do
      mv 1dmesh_${ref}.ugx "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGMENT_LENGTH}_1d_ref_${ref}.ugx"
   done
   
   # post process mesh for VR 
   for (( ref=0; ref < ${REFINEMENTS}; ref++)); do
      $BINARY -call "PostProcessMesh(\"${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_${ref}.ugx\")"
      mv test_new_tri.ugx "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_${ref}.ugx"
   done

   # remove attachments for visualization in ProMesh
   for (( ref=0; ref < ${REFINEMENTS}; ref++)); do
      sed '/.*vertex_attachment.*/d' "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_${ref}.ugx" > "${OUTPUT_FOLDER}/${SWC_FILE%*.swc}_segLength=${SEGLENGTH}_3d_x${inflation}_ref_${ref}_wo_attachments.ugx" 
   done
done

## bundle meshes to a .vrn archive
cat << EOF > ${OUTPUT_FOLDER}/MetaInfo.json
{
    "geom1d" : [
EOF

for (( ref=0;  ref < ${REFINEMENTS}; ref++)); do
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
         { "name" : "${SWC_FILE}_segLength=${SEGMENT_LENGTH}_1d_ref_${ref}.ugx", "description": "1d mesh coarse mesh", "refinement": "$ref",
           "inflations" : [
EOF
for (( inflation=1; inflation < $INFLATIONS; inflation++)); do 
inflation=${INFLATIONS[$idx]}
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
               { "name" : "${SWC_FILE}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" },
EOF
done
inflation=$INFLATIONS
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
               { "name" : "${SWC_FILE}_segLength=${SEGMENT_LENGTH}_3d_x${inflation}_ref_${ref}.ugx", "description": "2d surface mesh", "inflation" : "${inflation}" }
EOF

lastRef=$(($REFINEMENTS-1))
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
zip -9 -j -x "*_wo_attachments.ugx" -r ${SWC_FILE}.vrn MetaInfo.json *ugx
cd ../../
