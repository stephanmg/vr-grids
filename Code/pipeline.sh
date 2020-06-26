#!/bin/bash
## Option 3 (force @ swc points is good to generate real geometries for ug4 only if SMOOTHED sufficiently, might fail for smoothed and collapsed for different reasons, e.g. 3 branches not supported)
## Option 2 same as Option 3 needs also smoothing in the import method test_import_swc_general_var before processing the dendrites....
## Option 1 is good for vr usually 

# TODO: make these options, potentially with bash getopt
FOLDERNAME=FileUpload8 # was FileUpload5
CREATE_3D=false
CREATE_1D=true
REORDER=true
WRITEMATRIX=false
SMOOTH=true
# SCRIPT_3D=test_import_swc_general_var # general for ug4
SCRIPT_3D=test_import_swc_general_var_for_vr_var # vr current with all options available
FILE_PATTERN=$1
option="identity"

# check user demanding for help or not
if [ "$1" = "-h" ]; then
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
#for file in $FILE_PATTERN; do
#for file in 44-4.CNG_original.swc; do
for file in *_original.swc; do
#for file in 0-2a_original.swc; do
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
    if [ "${SMOOTH}" = true ]; then
      ./refine_var.sh "${FILENAME}_collapsed_split_and_smoothed.swc" "$REORDER" "$WRITEMATRIX" 
    else
      ./refine_var.sh "${FILENAME}_collapsed_and_split.swc" "$REORDER" "$WRITEMATRIX" 
    fi
    check_exit $?
    
    if [ "${SMOOTH}" = true ]; then
      cp "${FILENAME}_collapsed_split_and_smoothed_1st_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_1st_ref.ugx"
      cp "${FILENAME}_collapsed_split_and_smoothed_2nd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_2nd_ref.ugx"  
      cp "${FILENAME}_collapsed_split_and_smoothed_3rd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_3rd_ref.ugx"
      cp "${FILENAME}_collapsed_split_and_smoothed_4th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_4th_ref.ugx"
      cp "${FILENAME}_collapsed_split_and_smoothed_5th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_5th_ref.ugx"
      cp "${FILENAME}_collapsed_split_and_smoothed_6th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_6th_ref.ugx"
      cp "${FILENAME}_collapsed_split_and_smoothed_7th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_7th_ref.ugx"
    else
      cp "${FILENAME}_collapsed_and_split_1st_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_1st_ref.ugx"
      cp "${FILENAME}_collapsed_and_split_2nd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_2nd_ref.ugx"  
      cp "${FILENAME}_collapsed_and_split_3rd_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_3rd_ref.ugx"
      cp "${FILENAME}_collapsed_and_split_4th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_4th_ref.ugx"
      cp "${FILENAME}_collapsed_and_split_5th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_5th_ref.ugx"
      cp "${FILENAME}_collapsed_and_split_6th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_6th_ref.ugx"
      cp "${FILENAME}_collapsed_and_split_7th_ref.ugx" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_7th_ref.ugx"
    fi
    cp "$file" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.swc"
  fi
   
  if [ "${CREATE_3D}" = true ]; then
    for inflation in {1,2,3,4,5}; do 
      echo -n "Inflating mesh with factor $inflation..."
      if [ "${SMOOTH}" = true ]; then
         if [ "${SCRIPT_3D}" = "test_import_swc_general_var_for_vr_var" ]; then
          ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_split_and_smoothed.swc\", false, 0.5, true, 8, 0, true, $inflation, $option)" 
         else
          ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_split_and_smoothed.swc\", false, 0.5, true, 8, 0, true, $inflation, false, false, $option)" 
        fi
      else
         if [ "${SCRIPT_3D}" = "test_import_swc_general_var_for_vr_var" ]; then
          ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_and_split.swc\", false, 0.5, true, 8, 0, true, $inflation, $option)" 
        else
          ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_split_and_smoothed.swc\", false, 0.5, true, 8, 0, true, $inflation, false, false, $option)" 
        fi
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
