apt-get install cmake
mkdir -p gromacs
cd gromacs

export GROMACS_DOWNLOAD_SUM=c82634a31d0ec7dc8a128f404149440e
export GROMACS_PKG_VERSION=2018.3
curl -o gromacs-$GROMACS_PKG_VERSION.tar.gz -fsSL http://ftp.gromacs.org/pub/gromacs/gromacs-$GROMACS_PKG_VERSION.tar.gz
echo "$GROMACS_DOWNLOAD_SUM  gromacs-$GROMACS_PKG_VERSION.tar.gz" | md5sum -c --strict - 
tar xfz gromacs-$GROMACS_PKG_VERSION.tar.gz
cd gromacs-$GROMACS_PKG_VERSION

mkdir -p build-gromacs
cd build-gromacs
cmake .. -DGMX_OPENMP=ON -DGMX_GPU=ON -DGMX_MPI=ON -DGMX_BUILD_OWN_FFTW=ON -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-10.0 -DCMAKE_BUILD_TYPE=Release -DGMX_BUILD_UNITTESTS=OFF
make
make install
export PATH=/usr/local/gromacs/bin:$PATH
