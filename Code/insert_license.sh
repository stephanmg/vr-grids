#!/bin/bash
##
### What: Insert license header strings into source files
### Usage: insert_license.sh PATH_TO_SOURCE_FILES PATH_TO_LICENSE_TEXT_FILE
### Note: Need to make script executable via `chmod u+x insert_license.sh`.
##
## Additional information:
## 1. Will skip files which contain already a license header.
## 2. To detect if a license is already present in a given file with name
## say A.cs we check if the string "C2M2 license" can be found in file A.cs,
## if not, then the license header will be prepended to the file's content.
## 3. The license text is taken from the license.txt file and might be adapted.

# check for parameters
if [ $# -ne 2 ]; then
   echo "Usage: $(basename $0) SOURCE_DIRECTORY PATH_TO_LICENSE_TEXT_FILE"
   exit 
fi

# path to the source files (typically the project root directory contains sources)
SOURCE_DIRECTORY=$1

# contains license text
LICENSE_TEXT_FILE=$2

# insert the license header
EXTENSION="cs"
FILES=$(find "${SOURCE_DIRECTORY}" -iname "*.${EXTENSION}")
NUMBER_OF_FILES=$(wc -l <<< "${FILES}")

i=1
for file in $(find "${SOURCE_DIRECTORY}" -iname "*.cs"); do
   if grep -q "C2M2 license" "$file"; then
      echo "File ($i/${NUMBER_OF_FILES}): ${file} contains already license text. Skipping."
   else
      echo "File ($i/${NUMBER_OF_FILES}): ${file} inserting license text."
      cat ${LICENSE_TEXT_FILE} ${file} > ${file}.new
      mv ${file}.new ${file}
   fi
   i=$(($i+1))
done
