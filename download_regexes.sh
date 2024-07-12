#!/bin/bash

REGEXES_URL="https://raw.githubusercontent.com/ua-parser/uap-core/master/regexes.yaml"
DOWNLOAD_DIR="data"
REGEXES_FILE="regexes.yaml"

mkdir -p $DOWNLOAD_DIR

curl -L -o $DOWNLOAD_DIR/$REGEXES_FILE $REGEXES_URL

echo "Regexes file downloaded to $DOWNLOAD_DIR/$REGEXES_FILE"
