#!/bin/bash
### This version should be used to create 1d refined meshes, 3d meshes and blowups
## This pipeline is to conduct a comparison for 1d/3d geometries where an edge
## might be split or not depending on the FORCE_SPLIT_EDGE parameter (true/false)
## The best way to achieve this is, to chose the desired edge length well above
## the minimum distance of fragments (branching point to branching point)

SCRIPT_3D=test_import_swc_general_var_for_vr_var 

usage() { 
  echo "Usage: $(basename $0) -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D>"
  echo -e "\t\t\t [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c2 <CREATE_3D>]"
  echo -e "\t\t\t [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>]"
  echo -e "\t\t\t [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]" 1>&2; 
  exit 1; 
}

FILE_PATTERN= # input files
FOLDERNAME= # output folder
segLength1D="6" # desired seg length in 1d structure
segLength3D="-1" # desired seg length in 3d st ructure
CREATE_3D=false # should 3d grids be generated
CREATE_1D=true # should 1d grids be generated 
METHOD_3D="identity" # method identity usually for VR use case
METHOD_1D="user" # either user or mimum for VR use case
REMOVE_ATTACHMENTS=true # remove attachments for ProMesh versions incompatible
PRESMOOTH=true # pre smooth the whole structure 
REFINE=true # refine the mesh by powers of 2: 1, 2,4,8,16,32,64,128
FORCE=true # split edge if only one edge between branching points?
INFLATE=true # inflate the mesh with factors 1,2,3,4,5

while getopts ":i:l:m1:m2:s1:s2:a:p:r:f:o:c1:c2:b" o; do
    case "${o}" in
        b)
            INFLATE=${OPTARG}
            ;;
        i)
            FILE_PATTERN=${OPTARG}
            ;;
        c1)
            CREATE_1D=${OPTARG}
            ;;
        c3)
            CREATE_3D=${OPTARG}
            ;;
        o)
            FOLDERNAME=${OPTARG}
            ;;
        f)
            FORCE=${OPTARG}
            ;;
        r)
            REFINE=${OPTARG}
            ;;
        p)
            PRESMOOTH=${OPTARG}
            ;;
        s1)
            segLength1D=${OPTARG}
            ;;
        s2)
            segLength3D=${OPTARG}
            ;;
        p)
            PRESMOOTH=${OPTARG}
            ;;
        m1)
            METHOD_3D=${OPTARG}
            ;;
        m2)
            METHOD_1D=${OPTARG}
            ;;
        a)
            REMOVE_ATTTACHMENTS=${OPTARG}
             ;;
        *)
           usage
           ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${i}" ] || [-z "${o}" ] || [ -z "${s1}"]; then
    usage
fi

# function to check exit status
function check_exit() {
    if [ $1 -eq 0 ]; then 
      echo " successful."
    else
      echo " failed!"
    fi
}

# process each file
#for file in $FILE_PATTERN; do
#for file in 44-4.CNG_original.swc; do
for file in *_original.swc; do
#for file in 0-2a_original.swc; do
  FILENAME=${file%*.swc}
  # Create 1D
  echo "Processing file ${FILENAME} now..."
  if [ "${CREATE_1D}" = true ]; then
    # Presmoothing
    if [ "${PRESMOOTH}" = true ]; then
       echo -n "Coarsening 1d grid..."
       ./coarsen.sh "$file"  &> /dev/null
       check_exit $?
    else
      cp "$file" "${FILENAME}_collapsed_split_and_smoothed.swc"
    fi

    # Coarse grid generation (Re-sampling the spline)
    echo -n "Step 1/3: Creating 1D coarse grid..."
    mkdir "${FOLDERNAME}/${FILENAME}" &> /dev/null
    if [ "${METHOD_1D}" = "min" ]; then
       ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", -1, \"min\", 0, ${FORCE})" > log
    else
       ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", 0, ${FORCE})" > log
    fi
    cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d.swc"
    cp new_strategy_statistics.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_NEW.csv"
    cp statistics_edges_original.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_OLD.csv"
    check_exit $?
    
    # Refining
    echo -n "Step 2/3: Creating refinements..."
    numRef=0
    if [ "${METHOD_1D}" = "min" ]; then
      MIN=$(bc -l <<< "$(grep -ir "min seg length" log | cut -d ":" -f 3 | tr -d ' ')")
      segLength1D=$MIN
    fi
    if [ "${REFINE}" = true ]; then
     for ref in {1,2,4,8,16,32,64,128}; do 
        if [ "${METHOD_1D}" = "min" ]; then
          ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$MIN\", \"user\", \"$ref\", ${FORCE})" > log_$ref.log
        else
          ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", \"$ref\", ${FORCE})" > log_$ref.log 
        fi
        cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_${numRef}.swc"
        numRef=$(($numRef+1))
      done
      check_exit $?
    fi
  fi
   
  # Create 3D
  if [ "${CREATE_3D}" = true ]; then
    echo "Step 3/3 Creating 2D grids and inflations..."
    for inflation in {1,2,3,4,5}; do
      if [ "${inflate}" = true ] || [ "${inflation}" = 1 ]; then
        echo -n "Inflating mesh with factor $inflation..."
        ../bin/ugshell -call "${SCRIPT_3D}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d.swc\", false, 0.5, true, 8, 0, true, $inflation, \"$METHOD_3D\", \"$segLength3D\")"  
        check_exit $?
        cp after_selecting_boundary_elements_tris.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x$inflation.ugx"
        cp after_selecting_boundary_elements.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x$inflation.ugx"
        if [ "${REMOVE_ATTACHMENTS}" = true ]; then
          sed '/.*vertex_attachment.*/d' "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x${infl    ation}_wo_attachments.ugx"$
          sed '/.*vertex_attachment.*/d' "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x${inflation}_wo_attachments.ugx"
        fi
      fi
    done
  fi
done
