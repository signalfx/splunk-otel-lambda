#!/bin/bash

echo "Building the wrapper"
npm install --unsafe-perm
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
