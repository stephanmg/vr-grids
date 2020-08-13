#!/bin/bash

if [ ! -e "$1" -a ! -e "$1" ]; then
  exit
fi

FILENAME=${1%*.ugx}
../bin/ugshell -call "refine_swc_grid(\"${FILENAME}.ugx\",\"${FILENAME}_1st_ref.ugx\")"
#../bin/ugshell -call "refine_swc_grid(\"${FILENAME}_1st_ref.ugx\",\"${FILENAME}_2nd_ref.ugx\")"
#../bin/ugshell -call "refine_swc_grid(\"${FILENAME}_2nd_ref.ugx\",\"${FILENAME}_3rd_ref.ugx\")"
#../bin/ugshell -call "refine_swc_grid(\"${FILENAME}_3rd_ref.ugx\",\"${FILENAME}_4th_ref.ugx\")"
