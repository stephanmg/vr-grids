#!/bin/bash
# use a for loop around this to process all files

file=$1
echo "Processing file: ${file%%.swc} now"
FILENAME=${file%%.swc}
python edges_original.py -i "${FILENAME}_old.csv" 
python edges.py -i "${FILENAME}_new.csv" -a
