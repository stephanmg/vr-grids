#!/bin/bash

if [ ! -e "$1" -a ! -e "$1" ]; then
  exit
fi

FILENAME=${1%*.swc}
# if we want the reorderd meshes, then we use temp_reordered.swc and temp_reordered.ugx
reorder=$2
writeMatrix=$3
TEMP_FILENAME=temp
if [ "$reorder" = true ]; then
  TEMP_FILENAME=temp_reordered_reordered
fi

../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}.swc\")"

../bin/ugshell -call "refine_swc_grid_variant(\"new_strategy.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp ${TEMP_FILENAME}_reordered_NEW.ugx "${FILENAME}_1st_ref.ugx" 
cp ${TEMP_FILENAME}.swc "${FILENAME}_1st_ref.swc" 

exit 0

../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_1st_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp ${TEMP_FILENAME}_reordered_NEW.ugx "${FILENAME}_2nd_ref.ugx"
cp ${TEMP_FILENAME}.swc "${FILENAME}_2nd_ref.swc"

../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_2nd_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp ${TEMP_FILENAME}_reordered_NEW.ugx "${FILENAME}_3rd_ref.ugx"
cp $TEMP_FILENAME.swc "${FILENAME}_3rd_ref.swc"


../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_3rd_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp ${TEMP_FILENAME}_reordered_NEW.ugx "${FILENAME}_4th_ref.ugx"
cp $TEMP_FILENAME.swc "${FILENAME}_4th_ref.swc"


../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_4th_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp $TEMP_FILENAME.ugx "${FILENAME}_5th_ref.ugx"
cp $TEMP_FILENAME.swc "${FILENAME}_5th_ref.swc"

../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_5th_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp $TEMP_FILENAME.ugx "${FILENAME}_6th_ref.ugx"
cp $TEMP_FILENAME.swc "${FILENAME}_6th_ref.swc"

../bin/ugshell -call "refine_swc_grid_variant(\"${FILENAME}_6th_ref.swc\",\"$TEMP_FILENAME.ugx\", $writeMatrix)"
cp $TEMP_FILENAME.ugx "${FILENAME}_7th_ref.ugx"
cp $TEMP_FILENAME.swc "${FILENAME}_7th_ref.swc"
