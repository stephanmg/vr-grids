#!/bin/bash

FOLDERNAME=FileUpload2
CREATE_3D=true
CREATE_1D=true
#SCRIPT_3D=test_import_swc_general_var
SCRIPT_3D=test_import_swc_general_var_for_vr_2

for file in *original.swc; do
  FILENAME=${file%*.swc}
  echo "Processing file ${FILENAME} now..."
  if [ "${CREATE_1D}" = true ] ; then
    ./coarsen.sh "$file"
    mkdir "${FOLDERNAME}/${FILENAME}"
    cp "${FILENAME}_collapsed.ugx" "${FOLDERNAME}/${FILENAME}/"
    cp "${FILENAME}_collapsed_and_split.ugx" "${FOLDERNAME}/${FILENAME}/"
    cp "${FILENAME}_collapsed_split_and_smoothed.ugx" "${FOLDERNAME}/${FILENAME}/"
    cp "${FILENAME}_collapsed_and_split.swc"  "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d.swc"
    ./refine_var.sh "${FILENAME}_collapsed_and_split.swc" 
    cp "${FILENAME}_collapsed_and_split_1st_ref.swc" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_1st_ref.swc"
    cp "${FILENAME}_collapsed_and_split_2nd_ref.swc" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_2nd_ref.swc"  
    cp "${FILENAME}_collapsed_and_split_3rd_ref.swc" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_3rd_ref.swc"
    cp "${FILENAME}_collapsed_and_split_4th_ref.swc" "${FOLDERNAME}/${FILENAME}/${FILENAME}_1d_4th_ref.swc"
  fi

  if [ "${CREATE_3D}" = true ] ; then
    ../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed_and_split.swc\", false, 0.5, true, 8, 0, true, 1.0)"
    #../bin/ugshell -call "${SCRIPT_3D}(\"${FILENAME}_collapsed.swc\", false, 0.5, true, 8, 0, true, 1.0, true, false)"
    cp after_selecting_boundary_elements_tris.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_3d_tris.ugx"
    cp after_selecting_boundary_elements.ugx "${FOLDERNAME}/${FILENAME}/${FILENAME}_3d.ugx"
  fi
done
