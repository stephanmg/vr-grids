#!/bin/bash
## removes attachments

for file in $FILE_PATTERN; do
  sed '/.*vertex_attachment.*/d' "$FILE" > tmp.file && mv tmp.file "$FILE"
done
