#!/bin/bash

if [ ! -e "$1" -a ! -e "$1" ]; then
  exit
fi

FILENAME=${1%*.swc}
../bin/ugshell -call "test_import_swc_general_var(\"${FILENAME}.swc\", false, 0.5, true, 8, 0, true, 1.0, true, false)" |grep SWC > swcs.txt
#../bin/ugshell -call "test_import_swc_general_var(\"${FILENAME}.swc\", false, 0.5, true, 8, 0, true, 1.0, true, false)" 
# ./write_swc.pl --filename swcs.txt > swcs.swc 
cp after_selecting_boundary_elements_tris.ugx FileUpload/${FILENAME}_tris.ugx
cp after_selecting_boundary_elements.ugx FileUpload/${FILENAME}.ugx
cp swcs.swc FileUpload/${FILENAME}_1d.swc
