#!/bin/bash -e

DISTRO_DIR=build
SOURCES_DIR=otel/otel_sdk
OTEL_PYTHON_DIR=../opentelemetry-lambda/python/src

echo "Modify dependencies and script for Splunk integration"
pushd "$OTEL_PYTHON_DIR"

cd "$SOURCES_DIR"
sed -i 's/^opentelemetry-distro.*/splunk-opentelemetry[all]==2.3.0/g' requirements.txt
# Even if these regexes do nothing, leave these lines in to make later updates easier
sed -i 's/0.54b1/0.53b1/g' nodeps-requirements.txt
sed -i 's/0.54b1/0.53b1/g' requirements.txt
sed -i 's/1.33.1/1.32.1/g' requirements.txt
sed -i 's/^docker run --rm/docker run/g'  ../../build.sh
sed -i '2isource /opt/splunk-default-config' otel-instrument

cd ../..

# FIXME no good way to specify python version requirement to pip; use 3.8 runtime/setuptools image
# This block can be removed once python 3.8 reaches "no updates" aws deprecation status in March 2025
sed -i 's/runtime=python3.*/runtime=python3.8/' otel/Dockerfile
echo "Modified Dockerfile:"
cat otel/Dockerfile
echo "----"


echo "Building OTel Lambda python"
rm -rf build
./build.sh
cd $DISTRO_DIR
docker cp "$(docker ps --all | grep aws-otel-lambda-python-layer | cut -d' ' -f1 | head -1)":/out/opentelemetry-python-layer.zip ./layer.zip
unzip -qo layer.zip && rm layer.zip

popd

echo "Preparing Splunk layer"
# copy Splunk scripts (delegating to OTEL ones)
cp ../scripts/* $OTEL_PYTHON_DIR/$DISTRO_DIR/
cp -r ./src/* $OTEL_PYTHON_DIR/$DISTRO_DIR/python/
cd $OTEL_PYTHON_DIR/$DISTRO_DIR

echo "Performing manual size optimizations"
# J-T exporter
rm -rf python/opentelemetry/exporter/jaeger python/opentelemetry_exporter_jaeger_thrift* python/thrift*
# J-T exporter
rm -rf python/opentelemetry/exporter/otlp/proto/grpc python/opentelemetry_exporter_otlp_proto_grpc* python/grpc*
# additional libs
rm -rf python/six* python/*setuptools
# cached bytecode
find . -name __pycache__ -type d -prune -exec rm -rf {} \;


# ZIP IT
echo "Creating layer ZIP"
zip -qr layer.zip ./*

echo "Layer has been prepared"; exit 0
