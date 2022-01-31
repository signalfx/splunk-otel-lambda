#!/bin/bash

DISTRO_DIR=build
SOURCES_DIR=otel/otel_sdk
OTEL_PYTHON_DIR=../opentelemetry-lambda/python/src

echo "Modify dependencies and script for Splunk integration"
pushd "$OTEL_PYTHON_DIR/$SOURCES_DIR"

sed -i 's/^opentelemetry-distro.*/splunk-opentelemetry[all]==1.4.0/g' requirements.txt
sed -i 's/^docker run --rm/docker run/g'  ../../build.sh
sed -i 's/opentelemetry-instrument/splunk-py-trace/g'  otel-instrument

echo "Modified python wrapper requirements:"
cat requirements.txt

popd

echo "Building OTel Lambda python"
pushd $OTEL_PYTHON_DIR
./build.sh
otel=$?

echo "Preparing Splunk layer"
cd $DISTRO_DIR
docker cp `docker ps --all | grep aws-otel-lambda-python-layer | cut -d' ' -f1 | head -1`:/out/layer.zip .
unzip -qo layer.zip && rm layer.zip

# poor man's size optimisation
rm -rf python/opentelemetry/exporter/jaeger python/opentelemetry-exporter-jaeger-thrift* python/thrift* python/six*

mv otel-instrument otel-instrument-upstream

popd
# copy Splunk scripts (delegating to OTEL ones)
cp otel-instrument $OTEL_PYTHON_DIR/$DISTRO_DIR/
cp ../scripts/* $OTEL_PYTHON_DIR/$DISTRO_DIR/
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
