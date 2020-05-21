#!/bin/bash

# TODO: make these options, potentially with bash getopt
FOLDERNAME=FileUpload4
CREATE_3D=true
CREATE_1D=true
REORDER=true
WRITEMATRIX=false
SMOOTH=false
# SCRIPT_3D=test_import_swc_general_var
SCRIPT_3D=test_import_swc_general_var_for_vr_2
FILE_PATTERN=$1

# check user demanding for help or not
if [ "$1" = "-h" -o -z "$1" ]; then 
  echo "Usage: $(basename $0) FILE_PATTERN CREATE_3D CREATE_1D REORDER WRITEMATRIX" && exit
fi

# function to check exit status
function check_exit() {
    if [ $1 -eq 0 ]; then 
      echo " done!" 
    else
      echo " failed!"
    fi
}

# process each file
for file in $FILE_PATTERN; do
#for file in 44-4.CNG_original.swc; do
# for file in *_original.swc; do
# for file in 0-2a_original.swc; do
  FILENAME=${file%*.swc}
  echo "Processing file ${FILENAME} now..."
  if [ "${CREATE_1D}" = true ]; then
    mkdir "${FOLDERNAME}/${FILENAME}" &> /dev/null
    echo -n "Coarsening 1d grid..."
    ./coarsen.sh "$file"  &> /dev/null
    check_exit $?
    # cp "${FILENAME}_collapsed.ugx" "${FOLDERNAME}/${FILENAME}/"
    # cp "${FILENAME}_collapsed_and_split.ugx" "${FOLDERNAME}/${FILENAME}/"
    # cp "${FILENAME}_collapsed_split_and_smoothed.ugx" "${FOLDERNAME}/${FILENAME}/"
    # cp "${FILENAME}_collapsed_and_split.swc"  "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.swc"
    if [ "${SMOOTH}" = true ]; then
      cp "${FILENAME}_collapsed_split_and_smoothed.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.ugx"
    else
      cp "${FILENAME}_collapsed_and_split.ugx"  "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.ugx"
    fi

    echo -n "Refining 1d grid four times..."
    ./refine_var.sh "${FILENAME}_collapsed_and_split.swc" "$REORDER" "$WRITEMATRIX" &> /dev/null
    check_exit $?
    cp "${FILENAME}_collapsed_and_split_1st_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_1st_ref.ugx"
    cp "${FILENAME}_collapsed_and_split_2nd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_2nd_ref.ugx"  
    cp "${FILENAME}_collapsed_and_split_3rd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_3rd_ref.ugx"
    cp "${FILENAME}_collapsed_and_split_4th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_4th_ref.ugx"
    cp "$file" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.swc"
  fi
   
  if [ "${CREATE_3D}" = true ]; then
    for inflation in {1,2,3,4,5}; do 
      echo -n "Inflating mesh with factor $inflation..."
      if [ "${SMOOTH}" = true ]; then
        ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_split_and_smoothed.swc\", false, 0.5, true, 8, 0, true, $inflation)" 
      else
        ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_and_split.swc\", false, 0.5, true, 8, 0, true, $inflation)" 
      fi
      check_exit $?
      # ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}.swc\", false, 0.5, true, 8, 0, true, $inflation)"
      #  cp cleaned_up.swc "${FOLDERNAME}/${FILENAME}/cleaned_up.swc"
      # ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_and_split.swc\", false, 0.5, true, 8, 0, true, 1.0, true, false)"
      cp after_selecting_boundary_elements_tris.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_3d_tris_x$inflation.ugx"
      cp after_selecting_boundary_elements.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_3d_x$inflation.ugx"
      # cp cleaned_up.swc "${FOLDERNAME}/${FILENAME}/${FILENAME}_cleaned_up.swc"
    done
  fi
done



