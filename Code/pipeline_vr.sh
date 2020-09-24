#!/bin/bash
### This version should be used to create regularized and refined 1d meshes
### as well as inflated 3d meshes. For the VR and non-VR use-case the provided
### pipeline script should be used to create all geometries and bundle them 
### into the custom container format (.vrn) for simulations in Unity or ug4.
### A variety of options are offered, see below. In particular one can create
### geometries  where the edge between branching point is kept as-is or an 
### additional discretizatio point is introduced (FORCE_SPLIT_EDGE=true). 
### Best geometries are generated by chosing  a desired edge length for 1d mesh 
### regularization which is above the mimimum segment length between any two
### branching points. For sample usage see the associated README.md file.

### Prerequisite (Retrieve from NeuroMorpho.org): python get_swc.py --name 44.4 
### Basic usage: ./pipeline2new.sh -i 44-4.CNG.swc -o OutputFolder

# scripts for VR and non-VR use case
SCRIPT_3D_VR=test_import_swc_general_var_for_vr_var 
SCRIPT_3D=test_import_swc_general_var
BINARY=../bin/ugshell # path to ugshell or simply ugshell if UGROOT path set

# invocation options specified by the user
echo -n "Mesh generation invoked via: "
tput bold 
echo -n "$(basename $0) $@"
tput sgr0 
echo -n " (See if options suitable via "
tput bold
echo -n "$(basename $0) --help [-h]"
tput sgr0
echo ")"

# usage message
usage() { 
  echo "Usage: $(basename $0) -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D> [-c <BUNDLE>]"
  echo -e "\t\t\t [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c3 <CREATE_3D>] [-d <DEBUG>] [-q <QUIET>]"
  echo -e "\t\t\t [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>] [-v <FOR_VR>]"
  echo -e "\t\t\t [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]" 1>&2; 
  exit 1; 
}

# provide error messages to the user
fail() {
   local status=$1
   case $status in
      0)
      echo "Grid generation successful."
      ;;
      2) 
      echo "Regularization failed."
      ;;
      3)
      echo "Invalid branching pattern."
      ;;
      4)
      echo "Mesh contains cycles. Disallowed since physiologically not sensible."
      ;;
      5)
      echo "Cylinder-cylinder intersection detected."
      ;;
      6)
      echo "Start cylinders of neurites overlap at soma surface."
      ;;
      7)
      echo "Tetrahedralization failed."
      ;;
      8)
      echo "Branching point optimization failed."
      ;;
      9)
      echo "No permissble render vector could be found."
      ;;
      *)
      echo "Unknown or unexpected runtime error."
      ;;
esac

# actual parameters and options
FILE_PATTERN= # input files matching FILE_PATTERN
FOLDERNAME= # output folder where grid files are written to
segLength1D="8" # desired segment length in 1d structure
segLength3D="-1" # desired segment length in 3d st ructure
CREATE_3D=true # indicate that 3d meshes should be generated
CREATE_1D=true # indicate that 1d meshes should be generated
METHOD_3D="identity" # method identity usually for VR use-case (evaluation at spline support nodes)
METHOD_1D="user" # either user or minimum (segLength1D=-1) for VR use-case or auto (segLength1D=-1) or angle for GQ's angle length criterion
REMOVE_ATTACHMENTS=true # remove attachments when viewing in non-compatible ProMesh versions
PRESMOOTH=false # pre smooth the whole structure (usually not a good idea as it moves bps too heavily)
REFINE=true # refine the mesh by powers of 2
FORCE=false # split edge if only one edge between branching points
INFLATE=true # inflate the mesh with factors with given factors
VR=true # indicate that VR use-case is desired (default) or ug4 use-case
QUIET=false # output only warnings
DEBUG=true # output all warnings and debug statements 
BUNDLE_ONLY=false # if true, then only bundle .vrn file is created, no geometries are generated
REFINEMENTS=(1 2 4 8 16) # how many refinements (4)
INFLATIONS=(1 2 3 4 5) # how many inflations (4)
MAX_INFLATION=$(echo "${INFLATIONS[*]}" | sort -nr | head -n1) # max inflation factor

# Parse CLI options
while getopts ":i:l:m1:m2:s1:s2:a:p:r:f:o:c1:c3:b:v:d:q:c:" o; do
    case "${o}" in
        c)
            BUNDLE_ONLY=${OPTARG}
            ;;
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
      exit 2
    fi
}

if [ ! -z "${BUNDLE_ONLY}" ]; then
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
          check_exit $? >&3
       else
         cp "$file" "${FILENAME}_collapsed_split_and_smoothed.swc"
       fi
      
       # Coarse grid generation (Re-sampling the spline)
       echo -n "Step 1/3: Creating 1D coarse grid..." >&3
       mkdir -p "${FOLDERNAME}/${FILENAME}" 
       if [ "${METHOD_1D}" = "min" ]; then
          $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", -1, \"min\", 0, ${FORCE}, true)" 
       elif [ "${METHOD_1D}" = "angle" ]; then
          $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", 0, ${FORCE}, true, $MAX_INFLATION)"  
       else
          $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", 0, ${FORCE}, true)"  
       fi
       check_exit $? >&3
    
       cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d.swc"
       cp new_strategy_statistics.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_NEW.csv"
       cp statistics_edges_original.csv "${FOLDERNAME}/${FILENAME}/${FILENAME}_statistics_OLD.csv"
       check_exit $? >&3
       
       # Refining
       echo -n "Step 2/3: Creating refinements..." >&3
       numRef=0
       if [ "${METHOD_1D}" = "min" ]; then
         MIN=$(bc -l <<< "$(grep -ir "min seg length" log | cut -d ":" -f 3 | tr -d ' ')")
         segLength1D=$MIN
       fi
       if [ "${REFINE}" = "true" ]; then
        for ref in "${REFINEMENTS[@]}"; do
           if [ "${METHOD_1D}" = "min" ]; then
           segLength1D=min
             $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$MIN\", \"user\", \"$ref\", ${FORCE}, true)" > log_$ref.log
           else
             $BINARY -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$segLength1D\", \"$METHOD_1D\", \"$ref\", ${FORCE}, true)" > log_$ref.log 
           fi
             cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_${numRef}.swc" 
             # copy coarse grid
            if [ "${numRef}" -eq 0 ]; then
               cp new_strategy.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_0.ugx"
            else 
               cp new_strategy.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_${numRef}.ugx"
            fi
           numRef=$(($numRef+1))
         done
         check_exit $? >&3
       fi
     fi
      
     # Create 3D
     if [ "${CREATE_3D}" = "true" ]; then
       echo "Step 3/3 Creating 2D grids and inflations..." >&3
        for inflation in "${INFLATIONS[@]}"; do
         if [ "${INFLATE}" = "true" ] || [ "${inflation}" -eq 1 ]; then
           echo -n "Inflating mesh with factor $inflation..." >&3
           if [ "${VR}" = "true" ]; then
             ERROR_CODE=$($BINARY -call "${SCRIPT_3D_VR}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_0.swc\", false, 0.5, true, 8, 0, true, $inflation, \"$METHOD_3D\", \"$segLength3D\")")
             fail "$ERROR_CODE"
           else
             $BINARY -call "${SCRIPT_3D}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength1D}_1d_ref_0.swc\", false, 0.5, true, 8, 0, true, $inflation, false, false, \"$METHOD_3D\", \"$segLength3D\")" &> /dev/null
           fi
         
           check_exit $? >&3
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
fi

## bundle
for file in $FILE_PATTERN; do
 FILENAME=${file%*.swc}
cat << EOF > ${FOLDERNAME}/${FILENAME}/MetaInfo.json
{
    "geom1d" : [
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_0.ugx", "description": "1d mesh coarse mesh", "refinement": "0" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_1.ugx", "description": "1d mesh coarse mesh", "refinement": "1" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_2.ugx", "description": "1d mesh coarse mesh", "refinement": "2" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_3.ugx", "description": "1d mesh coarse mesh", "refinement": "3" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_1d_ref_4.ugx", "description": "1d mesh coarse mesh", "refinement": "4" }
    ],
   
    "geom2d": [
         { "name" : "${FILENAME}_segLength=${segLength1D}_3d_tris_x1.ugx", "description": "2d surface mesh", "inflation" : "1.0" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_3d_tris_x2.ugx", "description": "2d surface mesh", "inflation" : "2.0" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_3d_tris_x3.ugx", "description": "2d surface mesh", "inflation" : "3.0" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_3d_tris_x4.ugx", "description": "2d surface mesh", "inflation" : "4.0" },
         { "name" : "${FILENAME}_segLength=${segLength1D}_3d_tris_x5.ugx", "description": "2d surface mesh", "inflation" : "5.0" }
     ]
}
EOF

cd ${FOLDERNAME}/${FILENAME}
zip -j -x "*_wo_attachments.ugx" -x "*_3d_x*.ugx" -r ${FILENAME}.vrn MetaInfo.json *ugx
cd ../../
done

# shell variable GOOGLE_DRIVE_OAUTH_TOKEN must be set 
function() get_my_token {
  echo "$GOOGLE_DRIVE_OAUTH_TOKEN"
}

## upload to google drive (`get_my_token` gives us the OAUTH2 token to access google's API)
echo "Do you wish to upload your generated meshes into a cloud storage (Google Drive)?"
select yn in "Yes" "No"
case $yn in
    Yes ) 
   {for file in "$FILE_PATTERN"; do
    cd ${FOLDERNAME}/${FILENAME}
    FILENAME=${file%*.swc}
    curl -X POST -L \
     -H "Authorization: Bearer `get_my_token`" \
     -F "metadata={name : '${FILENAME}.vrn'};type=application/json;charset=UTF-8" \
     -F "file=@${FILENAME}.vrn;type=application/zip" \
      "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
   done
   } ;;
    No ) exit;;
esac
