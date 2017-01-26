set -e -x

V8_VERSION=${V8_VERSION:-5.4}

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

# Build v8
make -j5 x64.release GYPFLAGS="-Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=0 -Dv8_enable_gdbjit=0 -Dtest_isolation_mode=noop"
for lib in `find out/x64.release/obj.target/src/ -name '*.a'`;
  do ar -t $lib | xargs ar rvs $lib.new && mv -v $lib.new $lib;
done

# Bundle v8
rm -rf ${WORKSPACE}/bundle
mkdir -p ${WORKSPACE}/bundle/libv8 ${WORKSPACE}/bundle/include
cp out/x64.release/obj.target/src/libv8_base.a ${WORKSPACE}/bundle/libv8/
cp out/x64.release/obj.target/src/libv8_libbase.a ${WORKSPACE}/bundle/libv8/
cp out/x64.release/obj.target/src/libv8_snapshot.a ${WORKSPACE}/bundle/libv8/
cp out/x64.release/obj.target/src/libv8_libsampler.a ${WORKSPACE}/bundle/libv8/
cp out/x64.release/obj.target/src/libv8_libplatform.a ${WORKSPACE}/bundle/libv8/
cp -r include/libplatform ${WORKSPACE}/bundle/include/
cp -r include/*.h ${WORKSPACE}/bundle/include/
ln -s . ${WORKSPACE}/bundle/include/include
tar -C ${WORKSPACE}/bundle -czf ${WORKSPACE}/v8-${V8_VERSION}-linux.tar.gz .

# List
ls -l ${WORKSPACE}
