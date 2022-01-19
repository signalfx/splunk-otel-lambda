#!/bin/bash

# cleanup
rm -rf build

echo "Preparing build dir..."
mkdir -p build/ruby/lib
mkdir -p build/ruby/gems

echo "Installing dependencies..."
bundle install --path=build
ruby=$?
# move gems to proper location
mv -f build/ruby/2.7.0 build/ruby/gems/ && cp -r cached-gems/2.7.0 build/ruby/gems/
copy=$?

echo "Optimizing size..."
rm -rf build/ruby/gems/2.7.0/cache
rm -rf build/ruby/gems/2.7.0/gems/google-protobuf-3.19.3-x86_64-darwin
rm -rf build/ruby/gems/2.7.0/specifications/google-protobuf-3.19.3-x86_64-darwin.gemspec

echo "Copying scripts..."
cp ../scripts/* build/
cp scripts/* build/
scripts=$?

echo "Copying wrapper sources..."
cp src/*.rb build/ruby/lib
src=$?

echo "Packaging dependencies into zip archive..."
cd build
zip -qr9 ruby.zip *
zip=$?

if [[ "$ruby" -ne 0 || "$copy" -ne 0 || "$scripts" -ne 0 || "$src" -ne 0 || "$zip" -ne 0 ]] ; then
  echo "Could not build layer"; exit 1
else
  echo "Layer has been prepared"; exit 0
fi
