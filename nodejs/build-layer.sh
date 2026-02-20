#!/bin/bash -e

echo "Preparing build dir"
rm -rf build
mkdir build
ls -al

echo "Building the wrapper"
npm install --unsafe-perm

# optimise the size
echo "Performing automated size optimisations"
npm prune --json --production
# FIXME prune is removing necessary files (e.g., doc/directives.js) from the yaml parser and
# various attempts to --except it have not worked, so just not pruning for now
#npm exec node-prune

echo "Preparing Splunk layer"
cp nodejs-otel-handler ./build/
cp loader.mjs ./build/
cp ../scripts/* ./build/
mkdir -p build/nodejs
mv node_modules ./build/nodejs/

cd build
echo "Performing manual size optimisations"

# remove SOURCE FILES
find . \( -name "*.map" -o -name "*.ts" \) -type f -delete
# remove PACKAGES (CAREFUL!)
rm -rf ./nodejs/node_modules/graphql ./nodejs/node_modules/bson
# remove various folders (modules, protobuf definitions)
find . -name "protos" -type d -prune -exec rm -rf {} \;
find . -name "esm" -type d \
  -not -path "./nodejs/node_modules/import-in-the-middle/*" \
  -not -path "./nodejs/node_modules/require-in-the-middle/*" \
  -prune -exec rm -rf {} \;
# optimize PROTOBUF
find . -path "./nodejs/node_modules/protobufjs/*" \( -name "bin" -o -name "cli" -o -name "dist" -o -name "scripts" \) -type d -prune -exec rm -rf {} \;
# optimize SPLUNK
rm -rf ./nodejs/node_modules/@splunk/otel/prebuilds && rm -rf ./nodejs/node_modules/@splunk/otel/src
# optimize PAKO
find . -path "./nodejs/node_modules/pako/*" \( -name "dist" \) -type d -prune -exec rm -rf {} \;

# ZIP IT
echo "Creating layer ZIP"
zip -qr9 layer.zip ./*

echo "Layer has been prepared"; exit 0
