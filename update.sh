#!/bin/bash

# Remove previously generated code
/bin/rm -rf /home/winrid/dev/fastcomments/fastcomments-nim/client

if wget -q http://localhost:3001/js/swagger.json -O ./openapi.json; then
    echo "Downloaded OpenAPI spec from running server"
    SPEC_FILE="./openapi.json"
else
    echo "Server not running, using existing OpenAPI spec"
    SPEC_FILE="./openapi.json"
fi

java -jar ../openapi-generator/modules/openapi-generator-cli/target/openapi-generator-cli.jar generate \
    --additional-properties=useSingleRequestParameter=true \
    -i "$SPEC_FILE" \
    -g nim \
    -o ./client \
    -c config.json

echo "Generated Nim client in ./client"

# Generate markdown documentation
echo "Generating markdown documentation..."
/bin/rm -rf /home/winrid/dev/fastcomments/fastcomments-nim/docs
java -jar ../openapi-generator/modules/openapi-generator-cli/target/openapi-generator-cli.jar generate \
    --additional-properties=useSingleRequestParameter=true \
    -i "$SPEC_FILE" \
    -g markdown \
    -o ./docs

if [ $? -eq 0 ]; then
    echo "✓ Generated documentation in ./docs"
else
    echo "✗ Documentation generation failed!"
    exit 1
fi

echo "✓ Nim SDK generated successfully!"
