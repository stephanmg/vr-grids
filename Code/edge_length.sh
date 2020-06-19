#!/bin/bash
# script used to regularize the 1d meshes with ug4 and copy statistics over to a folder

if [ -z "$1" ]; then
  echo "Usage: $(basename $0) FILENAME"
  exit 1
fi

FOLDER="/Users/stephan/Desktop/RA Network Simulations in VR/Edge Length Statistics/New Strategy"
FILE=$1

if [ ! -e "$1" -o ! -f "$1" ]; then
  echo "Usage: $(basename $0) FILENAME"
  exit 2
fi

if [ ! -d "$FOLDER" ]; then
  echo "$FOLDER does not exist, make sure the folder is on your filesystem or provide a folder"
  exit 2
fi

FILENAME=${FILE%*.swc}
#./bin/ugshell -call "test_import_swc_general_var_for_vr_2(\"${FILENAME}.swc\", false, 0.5, true, 8, 0, true, 1.0, 3)" > log
../bin/ugshell -call "test_import_swc_and_regularize(\"${FILENAME}.swc\", 1, 3)" > log
grep -ir "adjusted" log | cut -d ':' -f 3 |sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/,/g' > adjusted_edge_length.csv
cp statistics_edges_original.csv "${FOLDER}/${FILENAME}_old.csv"
cp new_strategy_statistics.csv "${FOLDER}/${FILENAME}_new.csv"
cp adjusted_edge_length.csv "${FOLDER}/${FILENAME}_edge_length.csv"
cp ${FILENAME}.swc "${FOLDER}"
cp new_strategy.ugx "${FOLDER}/${FILENAME}.ugx"
cp $FILE "${FOLDER}"
