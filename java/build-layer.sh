#!/bin/bash

DISTRO_DIR=layer-wrapper/build/distributions
OTEL_JAVA_DIR=../opentelemetry-lambda/java

pushd $OTEL_JAVA_DIR
./gradlew clean
popd

echo "Building Splunk wrapper"
./gradlew clean build
mkdir -p $OTEL_JAVA_DIR/layer-wrapper/build/extensions
cp ./build/libs/*.jar $OTEL_JAVA_DIR/layer-wrapper/build/extensions

echo "Building OTEL wrapper"
pushd $OTEL_JAVA_DIR
./gradlew build

echo "Preparing Splunk layer"
cd $DISTRO_DIR
unzip -qo opentelemetry-java-wrapper.zip
rm opentelemetry-java-wrapper.zip
mv otel-handler otel-handler-upstream
mv otel-stream-handler otel-stream-handler-upstream
mv otel-proxy-handler otel-proxy-handler-upstream
popd

# copy Splunk scripts (delegating to OTEL ones)
cp ./scripts/* $OTEL_JAVA_DIR/$DISTRO_DIR/

# ZIP IT
echo "Creating layer ZIP"
cd $OTEL_JAVA_DIR/$DISTRO_DIR
zip -qr opentelemetry-java-wrapper.zip *
