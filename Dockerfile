# syntax=docker/dockerfile:1
# [DOWNLOAD ARCHIVES]
FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye as compiler


RUN export DEBIAN_FRONTEND=noninteractive; apt-get update && \
    apt-get install -y --no-install-recommends cmake gfortran build-essential sqlite3

ARG PROJ_LOCAL="/usr/local/proj"
ARG GDAL_LOCAL="/usr/local/gdal"
ARG GEOS_LOCAL="/usr/local/geos"
ARG ECCODES_LOCAL="/usr/local/eccodes"
# __________________________________________________________________________________________________________________
ARG PROJ="proj-6.3.2" 
# https://proj.org
#
# PROJ is a generic coordinate transformation software that transforms geospatial coordinates from one coordinate reference system (CRS) to another. 
# This includes cartographic projections as well as geodetic transformations. PROJ is released under the X/MIT open source license
WORKDIR /build/proj
RUN wget https://download.osgeo.org/proj/${PROJ}.tar.gz && tar -xf ${PROJ}.tar.gz && cd ${PROJ} && \
    ./configure --with-python=python3
    
RUN cd ${PROJ} && cmake . -DCMAKE_INSTALL_PREFIX=${PROJ_LOCAL} && make && ctest && make install
# __________________________________________________________________________________________________________________
ARG GEOS="geos-3.10.3" 
# https://libgeos.org/
#
# GEOS is a C/C++ library for computational geometry with a focus on algorithms used in geographic information systems (GIS) software. 
# It implements the OGC Simple Features geometry model and provides all the spatial functions in that standard as well as many others. 
# GEOS is a core dependency of PostGIS, QGIS, GDAL, and Shapely.
WORKDIR /build/geos
RUN wget https://download.osgeo.org/geos/${GEOS}.tar.bz2 && tar -xf ${GEOS}.tar.bz2 && cd ${GEOS} && \
    ./configure --with-python=python3
RUN cd ${GEOS} && cmake . -DCMAKE_INSTALL_PREFIX=${GEOS_LOCAL} && make && ctest && make install
# RUN cmake /geos-3.10.3 -DCMAKE_INSTALL_PREFIX="$GEOS_DIR"
# # install and test
# RUN make && ctest && make install
# .tar.bz2
# RUN cmake /geos-3.10.3 -DCMAKE_INSTALL_PREFIX="$GEOS_DIR"
# # install and test
# RUN make && ctest && make install


# __________________________________________________________________________________________________________________

RUN python3  -m pip install numpy
# https://gdal.org/build_hints.html
ARG GDAL="gdal-3.5.0"
#  GDAL is a translator library for raster and vector geospatial data formats that is released under an MIT style Open Source License by the Open Source Geospatial Foundation. 
#  As a library, it presents a single raster abstract data model and single vector abstract data model to the calling application for all supported formats. 
#  It also comes with a variety of useful command line utilities for data translation and processing. The NEWS page describes the May 2022 GDAL/OGR 3.5.0 release.
WORKDIR /tmp/gdal
RUN wget https://download.osgeo.org/gdal/3.5.0/${GDAL}.tar.gz && tar -xf ${GDAL}.tar.gz
RUN cd ${GDAL} && mkdir build/ && cd build/ && cmake .. && cmake --build . && \
    cmake --build . --target install
# RUN cd ${GDAL} && ./configure --prefix=${GDAL_LOCAL} --with-python=python3 --with-proj=${PROJ_LOCAL} && \
#     cmake . -DCMAKE_INSTALL_PREFIX=${GDAL_LOCAL} && \
#     make && ctest && make install
    # cmake . -DCMAKE_INSTALL_PREFIX=${GDAL_LOCAL}
# RUN 
# RUN wget https://download.osgeo.org/gdal/3.5.0/${GDAL}.tar.gz && tar -xf ${GDAL}.tar.gz && cd ${GDAL} && \
#     ./configure --with-python=python3 --with-proj=${PROJ_LOCAL} && \
#     cmake . -DCMAKE_INSTALL_PREFIX=${GDAL_LOCAL} && \
#     make && ctest && make install

FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bullseye
ARG PROJ_LOCAL="/usr/local/proj"
ARG GEOS_LOCAL="/usr/local/geos"
ARG GDAL_LOCAL="/usr/local/gdal"
ARG ECCODES_LOCAL="/usr/local/eccodes"
COPY --from=compiler $PROJ_LOCAL $PROJ_LOCAL
COPY --from=compiler $GEOS_LOCAL $GEOS_LOCAL
COPY --from=compiler $GDAL_LOCAL $GDAL_LOCAL
# tar -xf gdal-3.5.0.tar.gz -C . && rm -rf gdal-3.5.0.tar.gz