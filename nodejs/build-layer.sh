#!/bin/bash

echo "Building the wrapper"
rm -rf node_modules
npm install --unsafe-perm
npm prune --production
[ ! -f node-prune ] && curl -sf https://gobinaries.com/tj/node-prune | PREFIX=. sh
node-prune
find node_modules -name "*.map" -type f -delete
find node_modules -path "*/platform/*" -name "browser" -type d -prune -exec rm -rf {} \;
wrapper=$?

echo "Preparing Splunk layer"
cp nodejs-otel-handler ./build/
cp ../scripts/* ./build/
mkdir -p build/nodejs
mv node_modules ./build/nodejs/
splunk=$?

# ZIP IT
echo "Creating layer ZIP"
cd build
zip -qr9 layer.zip *
zip=$?

if [[ "$wrapper" -ne 0 || "$splunk" -ne 0 || "$zip" -ne 0 ]] ; then
  echo "Could not build layer"; exit 1
else
  echo "Layer has been prepared"; exit 0
fi
