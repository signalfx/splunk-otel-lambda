#!/bin/bash

DISTRO_DIR=layer-wrapper/build/distributions
OTEL_JAVA_DIR=../opentelemetry-lambda/java

echo "Building OTel Lambda java"
pushd $OTEL_JAVA_DIR
./gradlew clean
otel=$?
popd

echo "Building Splunk wrapper"
./gradlew clean build
splunk=$?
mkdir -p $OTEL_JAVA_DIR/layer-wrapper/build/extensions
cp ./build/libs/*.jar $OTEL_JAVA_DIR/layer-wrapper/build/extensions

echo "Building OTEL wrapper"
pushd $OTEL_JAVA_DIR
./gradlew build
wrapper=$?

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
cp ../scripts/* $OTEL_JAVA_DIR/$DISTRO_DIR/

# ZIP IT
echo "Creating layer ZIP"
cd $OTEL_JAVA_DIR/$DISTRO_DIR
zip -qr opentelemetry-java-wrapper.zip *
zip=$?

if [[ "$otel" -ne 0 || "$splunk" -ne 0 || "$wrapper" -ne 0 || "$zip" -ne 0 ]] ; then
  echo "Could not build layer"; exit 1
else
  echo "Layer has been prepared"; exit 0
fi
