#!/bin/bash -e

DISTRO_DIR=layer-wrapper/build/distributions
OTEL_JAVA_DIR=../opentelemetry-lambda/java

echo "Building OTel Lambda java"
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
sed -i '2isource /opt/splunk-default-config' otel-handler
sed -i '2isource /opt/splunk-default-config' otel-stream-handler
sed -i '2isource /opt/splunk-default-config' otel-proxy-handler
sed -i '3isource /opt/splunk-java-config' otel-handler
sed -i '3isource /opt/splunk-java-config' otel-stream-handler
sed -i '3isource /opt/splunk-java-config' otel-proxy-handler
popd

# copy Splunk scripts (delegating to OTEL ones)
cp ./scripts/* $OTEL_JAVA_DIR/$DISTRO_DIR/
cp ../scripts/* $OTEL_JAVA_DIR/$DISTRO_DIR/

cd $OTEL_JAVA_DIR/$DISTRO_DIR
echo "Performing manual size optimisations"
pushd java/lib
# UNUSED metrics - seems to have disappeared from upstream?
# FIXME Make this silent for now, revisit in the future
rm -f opentelemetry-exporter-otlp-metrics-*.jar
popd

# ZIP IT
echo "Creating layer ZIP"
zip -qr opentelemetry-java-wrapper.zip ./*

echo "Layer has been prepared"; exit 0
