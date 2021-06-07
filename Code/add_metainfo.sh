#!/bin/bash
## gets meta data for file name via REST API

if [ -z "$1" ]; then
   echo "Usage: $(basename $0) SWC_FILE_NAME (without .swc suffix)"
   exit 1
fi

FILENAME=$1

json=$(curl -s -X GET "http://neuromorpho.org/api/neuron/name/$FILENAME")

ARCHIVE=$(sed -e 's/[{}]/''/g' <<< "$json" | awk -v k="archive" -f add_metainfo.awk | sed 's/"//g')
SPECIES=$(sed -e 's/[{}]/''/g' <<< "$json" | awk -v k="species" -f add_metainfo.awk | sed 's/"//g')
STRAIN=$(sed -e 's/[{}]/''/g' <<< "$json" | awk -v k="strain" -f add_metainfo.awk | sed 's/"//g')

echo "        \"ARCHIVE\": \"$ARCHIVE\","
echo "        \"SPECIES\": \"$SPECIES\","
echo "        \"STRAIN\": \"$STRAIN\""
