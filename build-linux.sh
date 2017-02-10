set -e -x

V8_VERSION=$(go run ./get-version.go -delta ${DEV_DELTA:-0})

# make workspace
rm -rf ./build
mkdir -p ./build
cd ./build
WORKSPACE="${PWD}"

# Install depot_tools
export PATH="$PWD/depot_tools:$PATH"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ./depot_tools
gclient

# Fetch v8
fetch v8
cd ./v8
git checkout -b ${V8_VERSION} -t branch-heads/${V8_VERSION}
gclient sync

# Disable tests
cp gypfiles/all.gyp gypfiles/all.gyp.tmp
cat gypfiles/all.gyp.tmp | grep -v '/test' > gypfiles/all.gyp
rm gypfiles/all.gyp.tmp

# Build v8
make -j5 x64.release GYPFLAGS="-Dv8_use_external_startup_data=0 -Dv8_enable_gdbjit=0"
for lib in `find out/x64.release/obj.target/third_party/icu/ -name '*.a'`;
  do ar -t $lib | xargs ar rvs $lib.new && mv -v $lib.new $lib;
done
for lib in `find out/x64.release/obj.target/src/ -name '*.a'`;
  do ar -t $lib | xargs ar rvs $lib.new && mv -v $lib.new $lib;
done
ls -l out/x64.release/obj.target/third_party/icu/

# Bundle v8
rm -rf ${WORKSPACE}/bundle
mkdir -p ${WORKSPACE}/bundle/libv8 ${WORKSPACE}/bundle/include ${WORKSPACE}/dist/${TRAVIS_BUILD_NUMBER}
cp out/x64.release/obj.target/third_party/icu/*.a ${WORKSPACE}/bundle/libv8/
cp out/x64.release/obj.target/src/*.a             ${WORKSPACE}/bundle/libv8/
cp -r include/libplatform ${WORKSPACE}/bundle/include/
cp -r include/*.h ${WORKSPACE}/bundle/include/
tar -C ${WORKSPACE}/bundle -czf ${WORKSPACE}/dist/${TRAVIS_BUILD_NUMBER}/v8-${V8_VERSION}-linux.tar.gz .

# List
ls -l ${WORKSPACE}
