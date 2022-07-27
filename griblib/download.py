""" functions"""
from pathlib import Path
from typing import Iterator
from datetime import datetime
from shutil import copyfileobj
import warnings

from requests import Session, HTTPError
import pandas as pd


def _google_api_hrrr_grib2_data(start: datetime, end: datetime) -> Iterator[str]:
    """
    url generator function for googleapis high-resolution-rapid-refresh dataset
    """
    base_url = "https://storage.googleapis.com/high-resolution-rapid-refresh/"
    date_range = pd.date_range(start, end, freq="h")
    yield from base_url + date_range.strftime("hrrr.%Y%m%d/conus/hrrr.t%Hz.wrfnatf00.grib2")


def hrrr(start: datetime, end: datetime, path: Path) -> None:
    """
    base_url = https://storage.googleapis.com/high-resolution-rapid-refresh/

    iterate over urls and save files to a Path directory
    """
    # request context manager
    with Session() as session:
        # iteratate over the generator function
        for url in _google_api_hrrr_grib2_data(start=start, end=end):
            # add the filename to the path object
            save_to = path / ".".join(url.replace("hrrr.", "").split("/")[-3:])

            try:
                # make a http get request to the url
                res = session.get(url, stream=True)
                # on non 200 status code raise HTTPError
                res.raise_for_status()
                # save the file to the directory
                with save_to.open("wb") as fileout:
                    copyfileobj(res.raw, fileout)
                print("grib2 file saved at ", save_to)

            except HTTPError:
                warnings.warn(f"Warning: failed to download {url}")
