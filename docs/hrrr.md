# [Rapid Refresh (RAP) and High Resolution Rapid Refresh (HRRR) Model Development](https://rapidrefresh.noaa.gov/hrrr/)
The HRRR is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model, initialized by 3km grids with 3km radar assimilation. Radar data is assimilated in the HRRR every 15 min over a 1-h period adding further detail to that provided by the hourly data assimilation from the 13km radar-enhanced Rapid Refresh .
HRRR implementations at NCEP

![compositeReflectivity](https://user-images.githubusercontent.com/76945789/178105288-815033f4-725d-4910-aa29-abfbadb315d4.png)

![image](https://user-images.githubusercontent.com/76945789/178105183-de6d2fbf-f740-447f-be1f-bf3523dc3143.png)

Reading a multiple GRIB2 files and accessing a single variable.

```python
import xarray as xr

files = sorted(glob("/workspaces/griblib/data/hrrr/*.grib2"))[:2]
xr.open_mfdataset(
    files,
    concat_dim="valid_time",
    combine="nested",
    engine="cfgrib",
    filter_by_keys={
        "typeOfLevel": "isothermal",
        "stepType": "instant",
        "name": "Derived radar reflectivity",
    },
    chunks={"valid_time": 1, "x": 1799, "y": 1059},
)["refd"]
```
![dataArray](https://user-images.githubusercontent.com/76945789/178107015-0a7580cd-43c5-4745-8ecf-4d2ec0cb49dc.png)



## [AWS HRRR Zarr Archive Managed by MesoWest](https://mesowest.utah.edu/html/hrrr/)

MesoWest has a system that manages the archiving of "HRRR model output to access only the data needed for common **machine-learning** applications". 

This significantly increases read times of HRRR data by reducing I/O overhead that comes from accessing many GRIB2 files.

### links

#### HRRR GRIB2 Archive
- [aws-s3bucket](https://noaa-hrrr-bdp-pds.s3.amazonaws.com/index.html)
- [gcp-googleapi](https://console.cloud.google.com/storage/browser/high-resolution-rapid-refresh)

#### HRRR ZARR Archive
- [aws-s3bucket](https://hrrrzarr.s3.amazonaws.com/index.html)
