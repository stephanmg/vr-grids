#!/bin/bash
### This version should be used to create 1d refined meshes, 3d meshes and blowups
## This pipeline is to conduct a comparison for 1d/3d geometries where an edge
## might be split or not depending on the FORCE_SPLIT_EDGE parameter (true/false)
## The best way to achieve this is, to chose the desired edge length well above
## the minimum distance of fragments (branching point to branching point)

SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
SCRIPT_3D=test_import_swc_general_var
BINARY=../bin/ugshell # or ugshell if in your PATH (as it should be typically)

# be kind to the user and show invocation options
echo -n "Mesh generation invoked via: "
tput bold 
echo -n "$(basename $0) $@"
tput sgr0 
echo -n " (See if options suitable via "
tput bold
echo -n "$(basename $0) --help [-h]"
tput sgr0
echo ")"

# usage
usage() { 
  echo "Usage: $(basename $0) -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D>"
  echo -e "\t\t\t [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c3 <CREATE_3D>] [-d <DEBUG>] [-q <QUIET>]"
  echo -e "\t\t\t [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>] [-v <FOR_VR>]"
  echo -e "\t\t\t [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]" 1>&2; 
  exit 1; 
}

FILE_PATTERN= # input files
FOLDERNAME= # output folder, some name
segLength1D="3" # desired seg length in 1d structure
segLength3D="-1" # desired seg length in 3d st ructure
CREATE_3D=true # should 3d grids be generated
CREATE_1D=true # should 1d grids be generated 
METHOD_3D="identity" # method identity usually for VR use case
METHOD_1D="user" # either user or mimimum (-1) for VR use case
REMOVE_ATTACHMENTS=true # remove attachments for ProMesh versions incompatible
PRESMOOTH=true # pre smooth the whole structure 
REFINE=true # refine the mesh by powers of 2: 1, 2,4,8,16,32,64,128
FORCE=false # split edge if only one edge between branching points?
INFLATE=true # inflate the mesh with factors 1,2,3,4,5
VR=true # for vr default
QUIET=false # only warnings are outputted if specified
DEBUG=true # debug 

# parse CLI options
while getopts ":i:l:m1:m2:s1:s2:a:p:r:f:o:c1:c3:b:v:d:q:" o; do
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
            REMOVE_ATTACHMENTS=${OPTARG}
             ;;
        v) 
            VR=${OPTARG}
            ;;
        d)
            DEBUG=${OPTARG}
            ;;
        q)
           QUIET=${OPTARG}
           ;;
        h)  
           usage
           ;;
    esac
done
shift $((OPTIND-1))

## check for empty file input pattern and empty folder name
if [ -z "${FILE_PATTERN}" ] || [ -z "${FOLDERNAME}" ]; then
    echo "File input pattern or output folder empty!"
    usage
## no seglength specified then user needs to use auto or min explicitly
elif [ -z "${segLength1D}" ] && [ "${METHOD_1D}" != "auto"]; then
    usage
fi

# if debugging is desired
if [ "${DEBUG}" = "false" ]; then
    exec 3>&1 &>/dev/null
fi

# if quiet is desired (only warnings)
if [ ! -z "${QUIET}" ]; then
    exec 3>&2
fi

# function to check exit status
function check_exit() {
    if [ $1 -eq 0 ]; then 
      echo " successful."
    else
      echo " failed!"
      exit $(($2+1))
    fi
}

### process each file
for file in $FILE_PATTERN; do
  FILENAME=${file%*.swc}
  # Create 1D
  echo "Processing file ${FILENAME} now..." >&3
  if [ "${CREATE_1D}" = "true" ]; then
    # Presmoothing
    if [ "${PRESMOOTH}" = "true" ]; then
       echo -n "Coarsening 1d grid..." >&3
       ./coarsen.sh "$file" &> /dev/null
       check_exit $? 0 >&3
    else
      cp "$file" "${FILENAME}_collapsed_split_and_smoothed.swc"
    fi

    # Coarse grid generation (Re-sampling the spline)
    echo -n "Step 1/3: Creating 1D coarse grid..." >&3
    mkdir -p "${FOLDERNAME}/${FILENAME}" 
    if [ "${METHOD_1D}" = "min" ]; then
       $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", -1, \"min\", 0, ${FORCE})" &> /dev/null
    else
       $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", 0, ${FORCE}, true)" &> /dev/null
    fi

    cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d.swc"
    cp new_strategy_statistics.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_NEW.csv"
    cp statistics_edges_original.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_OLD.csv"
    check_exit $? 1 >&3
    
    # Refining
    echo -n "Step 2/3: Creating refinements..." >&3
    numRef=0
    if [ "${METHOD_1D}" = "min" ]; then
      MIN=$(bc -l <<< "$(grep -ir "min seg length" log | cut -d ":" -f 3 | tr -d ' ')")
      segLength1D=$MIN
    fi
    if [ "${REFINE}" = "true" ]; then
     for ref in {1,2,4,8,16}; do
        if [ "${METHOD_1D}" = "min" ]; then
        segLength1D=min
          $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$MIN\", \"user\", \"$ref\", ${FORCE}, true)" > log_$ref.log
        else
          $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", \"$ref\", ${FORCE}, true)" > log_$ref.log 
        fi
         cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_${numRef}.swc" 
          # copy coarse grid
         if [ "${numRef}" -eq 0 ]; then
            cp new_strategy.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d.ugx"
         fi
        numRef=$(($numRef+1))
      done
      check_exit $? 2 >&3
    fi
  fi
   
  # Create 3D
  if [ "${CREATE_3D}" = "true" ]; then
    echo "Step 3/3 Creating 2D grids and inflations..." >&3
    for inflation in {1,2,3,4,5}; do
      if [ "${INFLATE}" = "true" ] || [ "${inflation}" -eq 1 ]; then
        echo -n "Inflating mesh with factor $inflation..." >&3
        if [ "${VR}" = "true" ]; then
          $BINARY -call "${SCRIPT_3D_VR}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_0.swc\", false, 0.5, true, 8, 0, true, $inflation, \"$METHOD_3D\", \"$segLength3D\")" &> /dev/null
        else
          $BINARY -call "${SCRIPT_3D}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_0.swc\", false, 0.5, true, 8, 0, true, $inflation, false, false, \"$METHOD_3D\", \"$segLength3D\")" &> /dev/null
        fi
      
        check_exit $? 3 >&3
        cp after_selecting_boundary_elements_tris.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x$inflation.ugx"
        cp after_selecting_boundary_elements.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x$inflation.ugx"
        if [ "${REMOVE_ATTACHMENTS}" = "true" ]; then
          sed '/.*vertex_attachment.*/d' "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_tris_x${inflation}_wo_attachments.ugx"
          sed '/.*vertex_attachment.*/d' "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_3d_x${inflation}_wo_attachments.ugx"
        fi
      fi
    done
  fi
done
