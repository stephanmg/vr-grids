#!/bin/bash
## builds ug meshes from created y structures

ER_SCALE_FACTOR=0.5
NUMREFS=3
BINARY=../bin/ugshell
FILE_PATTERN=unbranched*swc
for file in $FILE_PATTERN; do
    FILENAME=${file%*.swc}
    echo "filename: $FILENAME"
    echo -n "Processing file $file now..."
    "$BINARY" -call "create_two_way_branch_from_swc(\"$file\", \"$ER_SCALE_FACTOR\", \"$NUMREFS\")" &> /dev/null
    mv imported_y_structure.ugx "${FILENAME}_ref_0.ugx"
    for i in $(seq 1 $NUMREFS); do
      mv imported_y_structure_refined_${i}.ugx "${FILENAME}_ref_${i}.ugx"
    done
    echo " done." 
done
