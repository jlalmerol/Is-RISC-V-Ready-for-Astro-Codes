#!/bin/bash

source /home/jlynn/newlibs-arm/setup_ompi5.0.6.sh

SOURCE_DIR="$HOME/iPIC3D-KTH"
BUILD_DIR="$SOURCE_DIR/build_arm_gcc"

# rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$SOURCE_DIR" \
  -DUSE_HDF5=OFF \
  -DUSE_OPENMP=ON \
  -DENABLE_VECTORIZATION=OFF \
  -DENABLE_ARM_VECTORIZATION=ON \
  -DARM_VECTOR_BITS=scalable

make VERBOSE=1 -j$(nproc) 2>&1 | tee build.log