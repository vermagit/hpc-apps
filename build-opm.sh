#!/bin/bash

NPROCS=40
OPM_DIR=opm
mkdir -p $OPM_DIR
pushd $OPM_DIR
CWD=$(pwd)


packages()
{
  sudo yum install -y epel-release
  sudo yum install -y gmp gmp-devel
  sudo yum install -y lapack lapack-devel
  sudo yum install -y suitesparse suitesparse-devel

  # Default path
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH-}:/usr/lib64:/usr/local/lib
  C_INCLUDE_PATH=${C_INCLUDE_PATH-}:/usr/local/include
}


OMPI_ROOT=openmpi-4.0.1
load_modules()
{
  # Following modules are available in the CentOS-HPC 7.6 VM image for Azure
  # Else, ensure some gcc and OpenMPI are available
  module load gcc-8.2.0
  module load mpi/$OMPI_ROOT
}


install_cmake()
{
  wget -nv https://github.com/Kitware/CMake/releases/download/v3.15.0-rc1/cmake-3.15.0-rc1-Linux-x86_64.sh
  mkdir -p cmake
  bash cmake-3.15.0-rc1-Linux-x86_64.sh --prefix=./cmake --skip-license
  export PATH=${PATH-}:$CWD/cmake/bin
}


PARMETIS_ROOT=parmetis-4.0.3
install_parmetis()
{
  wget -nv http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz
  tar xzf parmetis-4.0.3.tar.gz
  pushd $CWD/$PARMETIS_ROOT
  make config prefix=$CWD/$PARMETIS_ROOT
  make -j $NPROCS
  make install
  # Getting metis.h and libmetis.a
  cp $CWD/$PARMETIS_ROOT/metis/include/metis.h $CWD/$PARMETIS_ROOT/include/.
  cp $CWD/$PARMETIS_ROOT/build/Linux-x86_64/libmetis/libmetis.a $CWD/$PARMETIS_ROOT/lib/.
  popd
}


SUPERLU_ROOT=superlu_dist-6.1.1
install_superlu()
{
  wget -nv https://github.com/xiaoyeli/superlu_dist/archive/v6.1.1.tar.gz
  tar xzf v6.1.1.tar.gz
  pushd $CWD/$SUPERLU_ROOT
  mkdir -p build
  pushd build
  cmake .. -DTPL_PARMETIS_INCLUDE_DIRS=$CWD/$PARMETIS_ROOT/include -DTPL_PARMETIS_LIBRARIES="$CWD/$PARMETIS_ROOT/lib/libparmetis.a;$CWD/$PARMETIS_ROOT/lib/libmetis.a"
  make -j $NPROCS
  sudo make install
  popd
  popd
}


ZOLTAN_ROOT=Zoltan_v3.83
install_zoltan()
{
  wget -nv http://www.cs.sandia.gov/~kddevin/Zoltan_Distributions/zoltan_distrib_v3.83.tar.gz
  tar xzf zoltan_distrib_v3.83.tar.gz
  pushd $ZOLTAN_ROOT
  mkdir -p build
  pushd build

  ../configure \
  --prefix=$CWD/$ZOLTAN_ROOT/build \
  --disable-tests --disable-examples \
  --enable-mpi \
  --with-mpi=/opt/$OMPI_ROOT \
  --with-mpi-compilers=yes \
  --with-parmetis=yes \
  --with-parmetis-incdir=$CWD/$PARMETIS_ROOT/include \
  --with-parmetis-libdir=$CWD/$PARMETIS_ROOT/lib
  make -j $NPROCS everything
  make install

  popd
  popd
}


install_boost()
{
  wget -nv https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz
  tar xzf boost_1_70_0.tar.gz
  pushd boost_1_70_0
  ./bootstrap.sh --prefix=./
  echo "using mpi ;" >> project-config.jam
  ./b2 -j $NPROCS
  popd
}


install_dune()
{
  # this script downloads the necessary set of dune modules
  # to run the opm-autodiff blackoil simulator
  # change appropriately, i.e. 2.2, 2.3 or empty which refers to master
  DUNEVERSION=2.6.0
  FLAGS="-O3 -DNDEBUG"
  mkdir -p dune

  # say yes if you want to use the dune-cornerpoint module
  DUNECORNERPOINT=no
  DUNEMODULES="dune-common dune-istl"
  if [ "$DUNECORNERPOINT" != "" ] ; then
    DUNEMODULES=$DUNEMODULES" dune-geometry dune-grid dune-uggrid"
  fi
  # build flags for all DUNE and OPM modules
  # change according to your needs
  if ! test -f config.opts ; then
  echo "MAKE_FLAGS=-j$NPROCS \\
USE_CMAKE=yes \\
CONFIGURE_FLAGS=\"CXXFLAGS=\\\"$FLAGS\\\" \\
  --cache-file=../cache.config \\
  --disable-documentation \\
  --enable-shared \\
  --enable-parallel \\
  --disable-expressiontemplates \\
  --enable-experimental-grid-extensions \\
  --enable-fieldvector-size-is-method\" \\
CMAKE_FLAGS=\"-DCMAKE_INSTALL_PREFIX='./dune' \\
  -DHAVE_METIS_PARTGRAPHKWAY=1 \\
  -DHAVE_PARMETIS=1 \\
  -DMETIS_INCLUDE_DIR=$CWD/$PARMETIS_ROOT/include \\
  -DPARMETIS_INCLUDE_DIR=$CWD/$PARMETIS_ROOT/include \\
  -DMETIS_LIBRARY=$CWD/$PARMETIS_ROOT/build/lib \\
  -DPARMETIS_LIBRARY=$CWD/$PARMETIS_ROOT/lib\"" > config.opts
  fi
  DUNEBRANCH=
  if [ "$DUNEVERSION" != "" ] ; then
    DUNEBRANCH="-b releases/$DUNEVERSION"
  fi
  # get all dune modules necessary
  for MOD in $DUNEMODULES ; do
    #git clone $DUNEBRANCH http://gitlab.dune-project.org/core/$MOD
    wget -nv https://dune-project.org/download/$DUNEVERSION/$MOD-$DUNEVERSION.tar.gz
    tar xzf $MOD-$DUNEVERSION.tar.gz
  done
  # build all DUNE and OPM modules in the correct order
  ./dune-common-$DUNEVERSION/bin/dunecontrol --opts=config.opts all
  ./dune-common-$DUNEVERSION/bin/dunecontrol --opts=config.opts make install

  # Fail-safe, doing install's work
  for MOD in $DUNEMODULES ; do
    pushd $CWD/$MOD-$DUNEVERSION/build-cmake/dune
    cp -r bin/ lib/ lib64/ include/ share/ $CWD/dune/.
    popd
  done
}


install_ecl()
{
  echo "=== Cloning and building ecl"
  git clone https://github.com/Equinor/libecl
  pushd libecl
  mkdir -p build
  pushd build
  cmake .. -DERT_USE_OPENMP=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$CWD/ecl
  make -j $NPROCS
  make install
  popd
  popd
}


install_opm()
{
  # opm-upscaling seems to require either SuperLU or UMFPACK
  for repo in opm-common opm-material opm-grid ewoms opm-simulators #opm-upscaling
  do
    echo "=== Cloning and building module: $repo"
    git clone https://github.com/OPM/$repo.git
    mkdir -p $repo/build
    cd $repo/build
    cmake -DCMAKE_BUILD_TYPE=Release -DUSE_MPI=ON -DUSE_OPENMP=ON -DBLAS_LIBRARIES=/usr/lib64 -DBoost_INCLUDE_DIR=$CWD/boost_1_70_0 -DZOLTAN_INCLUDE_DIRS=$CWD/$ZOLTAN_ROOT/build/include -DZOLTAN_LIBRARIES=$CWD/$ZOLTAN_ROOT/build/lib/libzoltan.a -DMETIS_INCLUDE_DIRS=$CWD/$PARMETIS_ROOT/include -DMETIS_LIBRARIES=$CWD/$PARMETIS_ROOT/lib/libparmetis.a -DPARMETIS_INCLUDE_DIR=$CWD/$PARMETIS_ROOT/include -DCMAKE_PREFIX_PATH=$CWD/dune -DCMAKE_CXX_STANDARD_LIBRARIES="$CWD/$PARMETIS_ROOT/lib/libparmetis.a $CWD/$PARMETIS_ROOT/lib/libmetis.a" -DCMAKE_INSTALL_PREFIX=$CWD ..
    make -j $NPROCS
    cd ../..
  done
}


packages
load_modules
install_cmake
install_parmetis
install_superlu
install_zoltan
install_boost
install_dune
install_ecl
install_opm

mkdir -p packages
mv *.tar* packages/
popd
