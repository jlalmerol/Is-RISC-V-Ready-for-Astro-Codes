#!/bin/bash
source /home/jlynn/newlibs/setup_newlibs.sh

SOURCE_DIR="$HOME/iPIC3D-KTH"
BUILD_DIR="$SOURCE_DIR/build_x86_gcc"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$SOURCE_DIR" \
  -DCMAKE_C_COMPILER=mpicc \
  -DCMAKE_CXX_COMPILER=mpicxx \
  -DUSE_HDF5=OFF \
  -DUSE_OPENMP=ON \
  -DENABLE_VECTORIZATION=ON \
  -DX86_VECTOR_ISA=avx2 \
  -DMPI_CXX_COMPILER=mpicxx \
  -DMPI_C_COMPILER=mpicc \
  -DCMAKE_CXX_FLAGS="-UPHDF5 -DOMPI_ENABLE_MPI1_COMPAT=1" \
  -DCMAKE_C_FLAGS="-DOMPI_ENABLE_MPI1_COMPAT=1"

make VERBOSE=1 -j$(nproc) 2>&1 | tee build.log