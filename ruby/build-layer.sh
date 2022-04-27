#!/bin/bash -e

# cleanup
rm -rf build

echo "Preparing build dir..."
mkdir -p build/ruby/lib
mkdir -p build/ruby/gems

echo "Installing dependencies..."
bundle install --path=build

echo "Coping gems to layer structure..."
mv -f build/ruby/2.7.0 build/ruby/gems/ && cp -r cached-gems/2.7.0 build/ruby/gems/

echo "Optimizing size..."
rm -rf build/ruby/gems/2.7.0/cache
rm -rf build/ruby/gems/2.7.0/gems/google-protobuf-3.19.3-x86_64-darwin
rm -rf build/ruby/gems/2.7.0/specifications/google-protobuf-3.19.3-x86_64-darwin.gemspec

echo "Copying scripts..."
cp ../scripts/* build/
cp scripts/* build/

echo "Copying wrapper sources..."
cp src/*.rb build/ruby/lib

echo "Packaging dependencies into zip archive..."
cd build
zip -qr9 ruby.zip *

echo "Layer has been prepared"; exit 0