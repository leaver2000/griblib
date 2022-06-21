# syntax=docker/dockerfile:1
# [COMPILER]
FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye as compiler
# temp build directory & suppress debconf questions.
RUN export DEBIAN_FRONTEND=noninteractive; apt-get update && \
    apt-get install -y --no-install-recommends cmake gfortran build-essential sqlite3
# add the source files
ADD ./bin/eccodes-2.24.2-Source.tar.gz /
ADD ./bin/geos-3.10.3.tar.bz2 /
ADD ./bin/gdal-3.5.0.tar.gz /
ADD ./bin/proj-6.0.0.tar.gz /
# [ECCODES] https://confluence.ecmwf.int/display/ECC
ARG ECCODES_DIR="/usr/src/eccodes"
WORKDIR /build/eccodes
# compile
RUN cmake /eccodes-2.24.2-Source -DCMAKE_INSTALL_PREFIX="$ECCODES_DIR" -DENABLE_JPG=ON
# install and test
RUN make && ctest && make install

# [GEOS] https://trac.osgeo.org/geos/
ARG GEOS_DIR="/usr/src/geos"
WORKDIR /build/geos
# compile
RUN cmake /geos-3.10.3 -DCMAKE_INSTALL_PREFIX="$GEOS_DIR"
# install and test
RUN make && ctest && make install


#[PROJ] https://proj.org/install.html https://github.com/OSGeo/gdal/blob/master/docker/ubuntu-small/Dockerfile
ARG PROJ_INSTALL_PREFIX=/usr/src/proj
WORKDIR /build/proj 
RUN cd proj-6.0.0 && ./configure --prefix=${PROJ_INSTALL_PREFIX} --disable-static && \
    CFLAGS='-DPROJ_RENAME_SYMBOLS -O2' CXXFLAGS='-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2' \
    cmake . \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${PROJ_INSTALL_PREFIX} \
        -DBUILD_TESTING=OFF && \
    make -j4 && \
    make install 
# RUN echo ls
# RUN make -j4 && make install
# RUN make -j4 && make install
# RUN git clone https://github.com/OSGeo/proj.4 /proj && cd /proj && ./autogen.sh

# RUN export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2" && \
#     export CXXFLAGS="$CFLAGS -DPROJ_INTERNAL_CPP_NAMESPACE" && \
#     ./configure --prefix=/my/install/prefix --disable-static && \
#     make -j4 && \
#     make install && \
#     cd /my/install/prefix/lib
# Rename the library to libinternalproj
# mv libproj.so.19.1.0 libinternalproj.so.19.1.0
# ln -s libinternalproj.so.19.1.0 libinternalproj.so.19
# ln -s libinternalproj.so.19.1.0 libinternalproj.so
# rm -f libproj.*
# # Install the patchelf package
# apt install patchelf
# patchelf --set-soname libinternalproj.so libinternalproj.so


# [GDAL] https://gdal.org/
# ARG GDAL_DIR="/usr/src/gdal"
# WORKDIR /build/gdal
# ENV PROJ_LIBRARY=/usr/src/proj/lib
# ENV PROJ_INCLUDE_DIR=/usr/src/proj/include
# # ADD ./gdal-3.5.0.tar.gz /
# # # compile
# # # https://trac.osgeo.org/gdal/wiki/BuildingOnUnixGDAL25dev
# RUN cmake /gdal-3.5.0 -DCMAKE_INSTALL_PREFIX="$GDAL_DIR"
# # install and test
# RUN make && ctest && make install
# #
# FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye

# ARG ECCODES_DIR="/usr/src/eccodes"
# COPY --from=compiler $ECCODES_DIR $ECCODES_DIR
# ENV ECCODES_DIR="$ECCODES_DIR"

# ARG GEOS_DIR="/usr/src/geos"
# COPY --from=compiler $GEOS_DIR $GEOS_DIR

# ARG GDAL_DIR="/usr/src/gdal"
# COPY --from=compiler $GDAL_DIR $GDAL_DIR
# ENV GDAL_DIR="$GDAL_DIR"

# ARG VIRTUAL_ENV="/opt/venv"
# RUN python3 -m venv "$VIRTUAL_ENV"

# ENV PATH="$VIRTUAL_ENV/bin:$GEOS_DIR/bin:$PATH"
# # upgrade pip
# RUN python3 -m pip install --upgrade pip && pip install wheel
# # COPY ./requirements-${BUILD_SIZE}.txt ./requirements.txt 
# # install the requirements
# RUN pip install numpy cfgirb eccodes shapely pygeos 