#!/bin/bash

scriptName=test_import_swc_general_var

if [ -z "$1" ]; then
  echo "Usage: $(basename $0) RADIUS_FACTOR"
  exit 1
fi

radiusFactor=$1
count=0
numFiles=$(ls -1q files/*.swc | wc -l)

for file in files/*.swc; do
  echo "Processing file: $file"
  intersection=$(../bin/ugshell -call "$scriptName(\"$file\", false, 0.5, true, 8, 0, true, $radiusFactor, true)" | grep "Root neurites intersect")
  echo "intersection: $intersection"
  if [ ! -z "$intersection" ]; then
    count=$(($count+1))
  fi
done

echo "$count, $numFiles, $radiusFactor" >> intersect_data.csv
