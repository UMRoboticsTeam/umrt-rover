#!/usr/bin/bash

# Removes the tags from a sym file that Python cantools doesn't like

SYMBOL_FILE="$1"
OUTPUT_FILE="$2"

echo "Stripping problematic sym file tags"
echo "Reading from '${SYMBOL_FILE}'"

# Strip "/slot:" tags, cantools doesn't like it
sed -E "s|/slot:[0-9]+||g" < "${SYMBOL_FILE}" | \
sed -E "s|IDMask=[0-9A-F]+h||g" > "${OUTPUT_FILE}"