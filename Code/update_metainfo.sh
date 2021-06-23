#!/bin/bash

## update meta data for old cells which have been generated without  metadata
OUTPUT_FOLDER=$1
SWC_FILE_NAME=$2

if [ -z "$1" -o -z "$2" ];  then
   echo "Usage: $(basename $0) CELL_ARCHIVE_FOLDER_CONTAINING_VRN_ARCHIVE_FILE (folder with .vrn file) SWC_FILE_NAME (without .swc suffix)"
   exit 1
fi

mkdir $OUTPUT_FOLDER
cp "${SWC_FILE_NAME}.vrn" $OUTPUT_FOLDER
cd $OUTPUT_FOLDER
unzip "${SWC_FILE_NAME}.vrn"
cat MetaInfo.json
head -n -2 MetaInfo.json > MetaInfo.json.new
mv MetaInfo.json.new MetaInfo.json

cp ../add_metainfo.sh .
cp ../add_metainfo.awk .

./add_metainfo.sh $SWC_FILE_NAME >> MetaInfo.json

echo "}" >> MetaInfo.json

zip -9 -j -x "*_wo_attachments.ugx" -x "*vrn" -x "*sh" -x "*awk" -r ${SWC_FILE_NAME}.vrn MetaInfo.json *ugx
