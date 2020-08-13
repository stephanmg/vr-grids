#!/bin/bash

scriptName=test_import_swc_general_var

for file in files/*.swc; do
  fname=${file%*.swc}
  fname=${fname#smith/}
  echo "Processing file: $file now..."
  ../bin/ugshell -call "$scriptName(\"$file\", false, 0.5, true, 0.5, 0, true)" > file_tmp.log
  cat file_tmp.log >> file_tmp_complete.log
  tail -n 1 file_tmp.log >> benchmark.log
done
