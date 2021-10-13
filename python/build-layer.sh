#!/bin/bash

DISTRO_DIR=build
SOURCES_DIR=otel/otel_sdk
OTEL_PYTHON_DIR=../opentelemetry-lambda/python/src

echo "Modify dependencies for Splunk integration"
pushd "$OTEL_PYTHON_DIR/$SOURCES_DIR"
sed -i 's/^opentelemetry-distro.*/splunk-opentelemetry[all]==1.0.0/g' requirements.txt
popd

echo "Building OTel Lambda python"
pushd $OTEL_PYTHON_DIR
./build.sh
otel=$?

echo "Preparing Splunk layer"
cd $DISTRO_DIR
unzip -qo layer.zip && rm layer.zip
mv otel-instrument otel-instrument-upstream
popd
# copy Splunk scripts (delegating to OTEL ones)
cp otel-instrument $OTEL_PYTHON_DIR/$DISTRO_DIR/
splunk=$?

# ZIP IT
echo "Creating layer ZIP"
cd $OTEL_PYTHON_DIR/$DISTRO_DIR
zip -qr layer.zip *
zip=$?

if [[ "$otel" -ne 0 || "$splunk" -ne 0 || "$zip" -ne 0 ]] ; then
  echo "Could not build layer"; exit 1
else
  echo "Layer has been prepared"; exit 0
fi
