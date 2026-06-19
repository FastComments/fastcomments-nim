#!/bin/bash
set -e

# FastComments openapi-generator build. The Nim generator now references model
# types by their declared (camelized) names, so no post-generation patching is
# needed. Just a jar; downloaded on demand.
JAR_URL="https://github.com/winrid/openapi-generator/releases/download/fastcomments-build-20260619/openapi-generator-cli.jar"
JAR_FILE="./openapi-generator-cli.jar"

[ -f "$JAR_FILE" ] || wget -q "$JAR_URL" -O "$JAR_FILE"

rm -rf ./client
wget -q http://localhost:3001/js/swagger.json -O ./openapi.json

java -jar "$JAR_FILE" generate \
    --additional-properties=useSingleRequestParameter=true \
    -i ./openapi.json \
    -g nim \
    -o ./client \
    -c config.json

echo "Generated Nim client in ./client"

rm -rf ./docs
java -jar "$JAR_FILE" generate \
    --additional-properties=useSingleRequestParameter=true \
    -i ./openapi.json \
    -g markdown \
    -o ./docs

echo "✓ Nim SDK generated successfully!"
