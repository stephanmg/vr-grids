#!/bin/bash

scriptName=test_import_swc_general_var

for file in smith/*.swc; do
  fname=${file%*.swc}
  fname=${fname#smith/}
  echo $file
  ../bin/ugshell -call "$scriptName(\"$file\", false, 0.5, true, 16, 0, true)"
  #cp after_regularize.ugx after_"regularize/${fname}.ugx"
done
