#!/bin/bash
function download_cartopy(){
    # rm -rf cartopy
    mkdir ./cartopy-0.20.2-Source/;
    # clone the cartopy git repo the move into it and checkout version0.20.x
    git clone https://github.com/SciTools/cartopy.git && cd cartopy && git checkout v0.20.x;
    # copy the 
    mv lib/ requirements/ tools/ README.md INSTALL MANIFEST.in pyproject.toml setup.py ../cartopy-0.20.2-Source/ && cd ../;
    VERSION='''
{
    "dirty": false,
    "error": null,
    "full-revisionid": "178a15e39d085758832d30aa9f77f34f708a7d1e",
    "version": "0.20.2"
}
    '''
    echo """
import json
import sys

version_json = '''$VERSION'''  # END VERSION_JSON


def get_versions():
    return json.loads(version_json)
""" > ./cartopy-0.20.2-Source/lib/cartopy/_version.py;

    # tar -czvf cartopy-0.20.2-Source.tar.gz ./cartopy-0.20.2-Source/;
    # rm -rf ./cartopy/ ./cartopy-0.20.2-Source/;
}


download_cartopy


# function 