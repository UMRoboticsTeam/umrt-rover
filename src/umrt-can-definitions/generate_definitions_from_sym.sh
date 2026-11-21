#!/usr/bin/bash

# Generates C code from a sym file as well as a translation of it to DBC

SYMBOL_FILE="$1"
OUTPUT_FILE_BASENAME="$2"
OUTPUT_FOLDER="$3"
TRANSLATION_SCRIPT_PATH="$4"
DBC_OUTPUT_PATH="$5"

echo "Generating source from sym file"
echo "Reading from '${SYMBOL_FILE}'"

python3 -m cantools generate_c_source --database-name "${OUTPUT_FILE_BASENAME}" -o "${OUTPUT_FOLDER}" "${SYMBOL_FILE}"

python3 "${TRANSLATION_SCRIPT_PATH}" "${SYMBOL_FILE}" "${DBC_OUTPUT_PATH}"