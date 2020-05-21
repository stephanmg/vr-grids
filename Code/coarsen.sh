#!/bin/bash

if [ ! -e "$1" -a ! -e "$1" ]; then
  exit
fi

FACTOR=$2
FILENAME=${1%*.swc}
if [ -z "$FACTOR" ]; then FACTOR=2.0; fi
../bin/ugshell -call "coarsen_1d_grid(\"${FILENAME}.swc\", $FACTOR)"
