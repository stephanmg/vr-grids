#!/bin/bash

for file in testfiles/*.swc; do
  fname=${file%*.swc}
  fname=${fname#smith/}
  echo $file
  ../bin/ugshell -call "test_import_swc_general(\"$file\", false, 0.5, true, 0.5, 0, true)"
 # cp after_regularize.ugx after_"regularize/${fname}.ugx"
done
