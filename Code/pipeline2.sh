#!/bin/bash
FOLDERNAME=FileUpload10 # was FileUpload10
CREATE_3D=true
CREATE_1D=true
REORDER=true
WRITEMATRIX=false
SMOOTH=true
SCRIPT_3D=test_import_swc_general_var_for_vr_var # vr current
FILE_PATTERN=$1
option=3
METHOD_3D="auto" # was identity
METHOD_1d="user"
segLength="32" # was "auto"

REMOVE_ATTACHMENTS=true

# check user demanding for help or not
if [ "$1" = "-h" ]; then
  echo "Usage: $(basename $0) FILE_PATTERN CREATE_3D CREATE_1D REORDER WRITEMATRIX" && exit
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
#for file in *_original.swc; do
for file in 0-2a_original.swc; do
  FILENAME=${file%*.swc}
  # Create 1D
  echo "Processing file ${FILENAME} now..."
  if [ "${CREATE_1D}" = true ]; then
   # echo -n "Coarsening 1d grid..."
   # ./coarsen.sh "$file"  &> /dev/null
   # check_exit $?

    echo -n "Step 1/3: Creating 1D coarse grid..."
    mkdir "${FOLDERNAME}/${FILENAME}" &> /dev/null
    cp "$file" "${FILENAME}_collapsed_split_and_smoothed.swc"
     ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"${segLength}\", \"user\", 0, true)" > log
 #    ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\")" > log
    #cp "${FILENAME}.swc" new_strategy.swc
    grep "min seg" log
    grep "dist:" log
    cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_1d.swc"
    exit
    check_exit $?
    echo -n "Step 2/3: Creating refinements..."
    numRef=0
    MIN=$(bc -l <<< "$(grep -ir "min seg length" log | cut -d ":" -f 3 | tr -d ' ')")
    for ref in {1,2,4,8,16,32}; do
    #for ref in {1,2,4,8,16,32,64,128}; do 
      ../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}_collapsed_split_and_smoothed.swc\", \"$MIN\", \"user\", \"$ref\", true)" > log_$ref.log
      cp new_strategy.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_1d_ref_${numRef}.swc"
      numRef=$(($numRef+1))
    done
    check_exit $?
  fi
   
  # Create 3D
  if [ "${CREATE_3D}" = true ]; then
    echo "Step 3/3 Creating 2D grids and inflations..."
    for inflation in {1,2}; do
    #for inflation in {1,2,3,4,5}; do 
      echo -n "Inflating mesh with factor $inflation..."
 #     ../bin/ugshell -call "${SCRIPT_3D}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_1d_ref_0.swc\", false, 0.5, true, 8, 0, true, $inflation, \"identity\", -1)"  
      ../bin/ugshell -call "${SCRIPT_3D}(\"${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_1d.swc\", false, 0.5, true, 8, 0, true, $inflation, \"identity\", -1)"  
      check_exit $?
      cp after_selecting_boundary_elements_tris.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_tris_x$inflation.ugx"
      cp after_selecting_boundary_elements.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_x$inflation.ugx"
      if [ "${REMOVE_ATTACHMENTS}" = true ]; then
        grep -vwE attachment "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_tris_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_tris_x${inflation}_wo_attachments.ugx"
        grep -vwE attachment "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_x$inflation.ugx" > "${FOLDERNAME}/${FILENAME}/${FILENAME}_segLength=${segLength}_3d_x${inflation}_wo_attachments.ugx"
      fi
    done
  fi
done
