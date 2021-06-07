#!/bin/bash
## tested with the following revisions:
##  -  ugcore (master): HEAD
##  -  neuro_collection (meshFixes): HEAD
##  -  neuro_collection (fixMapping): HEAD 
##  Verify: fixMapping might be merged into meshFixes for 1d mesh generation.
## 
##  Note: Relies on the following new functionalities in ugcore/neuro_collection: 
##    NeuriteAxialRefinementMarker, MappingAttachmentHandler and PostProcessMesh
##    for VR 3d mesh generation respectively Write3dMeshTo1d and the corrected
##    mapping attachment (fixMapping) for 1d mesh generation based on the 3d mesh.
##
## Caveat: Refines until geometry is isotropic, then refines the geometry globally!

## mesh generation default parameter values
INFLATIONS=1
REFINEMENTS=1
SEGMENT_LENGTH=6
SWC_FILE=single_branch
OUTPUT_FOLDER=example
BINARY=/home/stephan/Code/ug4/bin/ugshell 

## fixed mesh generation parameters (do not change)
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
MODE=identity

## Parse CLI options
while getopts "i:o:n:m:l:" o; do
    case "${o}" in
        i)
            SWC_FILE=${OPTARG}
            ;;
        o)
            OUTPUT_FOLDER=${OPTARG}
            ;;
        n)
            INFLATIONS=${OPTARG}
            ;;
        m)
            REFINEMENTS=${OPTARG}
            ;;
        l)
            SEGMENT_LENGTH=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

## usage message
usage() { 
  echo -e "\t Usage: $(basename $0) -i <INPUT_FILE> -o <OUTPUT_FOLDER> -l <SEGMENT_LENGTH> [-n <NUMBER_OF_INFLATIONS> -m <NUMBER_OF_REFINEMENTS>]"
  exit 1;
}

## check for empty file input pattern and empty folder name
if [ -z "${SWC_FILE}" ]; then
   echo "No input file provided by the user:" && echo && usage
elif [ -z "${OUTPUT_FOLDER}" ]; then
   echo "No output folder provided by the user:" && echo && usage
elif [ -z "${SEGMENT_LENGTH}" ]; then
   echo "No input segment length provided by the user:" && echo && usage
fi

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
      ],
    "metadata" : {
EOF
   ./add_metainfo.sh "$SWC_FILE" >> ${OUTPUT_FOLDER}/MetaInfo.json
cat << EOF >> ${OUTPUT_FOLDER}/MetaInfo.json
   }
}
EOF

cd ${OUTPUT_FOLDER}
zip -9 -j -x "*_wo_attachments.ugx" -r ${SWC_FILE}.vrn MetaInfo.json *ugx
cd ../../
