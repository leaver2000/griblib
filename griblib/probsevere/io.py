# """input output for probsevere data"""
# __all__ = ["download2parquet","PROBSEVERE_URL_TEMPLATE","VALIDTIME_TEMPLATE"]
from pathlib import Path
from warnings import warn
from datetime import datetime
from typing import Callable, Union, Iterable, Iterator

import pandas as pd
import numpy as np
import dask.dataframe as dd
from dask.dataframe.core import DataFrame as DaskDataFrame
from geopandas import GeoDataFrame
from requests import Session, HTTPError

from griblib.probsevere.typed import FeatureCollection

URL_TEMPLATE = "https://mtarchive.geol.iastate.edu/%Y/%m/%d/mrms/ncep/ProbSevere/MRMS_PROBSEVERE_%Y%m%d_%H%M00.json"
VALIDTIME_TEMPLATE = "%Y%m%d_%H%M%S %Z"

TimeLike = Union[datetime, str, pd.Timestamp]


def __iterdaterange(
    start: TimeLike, end: TimeLike, *, freq: str = "2min"
) -> Iterator[tuple[pd.Timestamp, pd.DataFrame]]:
    """yields the probsevere urls grouped by dates

    Parameters
    ----------
    start : str or datetime-like
        Left bound for generating dates.
    end : str or datetime-like
        Right bound for generating dates.
    freq : str or DateOffset, by default '2min'


    Yields
    ------
    Iterator[tuple[pd.Timestamp, pd.DataFrame]]
        _description_
    """
    dr = pd.date_range(start=start, end=end, freq=freq)
    urls = dr.strftime(URL_TEMPLATE)
    yield from pd.DataFrame({"date": dr, "urls": urls}).set_index(dr).groupby(pd.Grouper(key="date", freq="D", axis=0))


def __generate_from_features(session: Session, *, urls: Iterable[str]) -> Iterable[pd.DataFrame]:
    for url in urls:
        try:
            # with our session make a get request, r is a response object
            r = session.get(url, stream=True)
            # in the event of a non 200 status code we'll raise a HTTPError and trigger the except block
            r.raise_for_status()
        # if there was an error downloading, continue
        except (ConnectionError, HTTPError):
            warn(f"error downloading {url}")
            continue
        fc: FeatureCollection = r.json()

        features = fc["features"]
        # in the event no storms were record, continue
        if not features:
            # warn(f"url contained no features: {url}")
            continue

        df = GeoDataFrame.from_features(features)
        # validtime = datetime.strptime(fc["validTime"], "%Y%m%d_%H%M%S %Z")
        df["VALIDTIME"] = datetime.strptime(fc["validTime"], VALIDTIME_TEMPLATE)
        yield df


def __wrangle_geometry(df: GeoDataFrame) -> pd.DataFrame:
    # to keep thins consistent uppercase all of the bounds
    df[df.bounds.columns.str.upper()] = df.bounds
    point = df.representative_point()
    df["X"] = point.x
    df["Y"] = point.y
    return df


def __wrangle_dtypes(
    ddf: DaskDataFrame,
) -> DaskDataFrame:
    float32_cols = [
        "EBSHEAR",
        "MEANWIND_1-3kmAGL",
        "MESH",
        "VIL_DENSITY",
        "FLASH_DENSITY",
        "MOTION_EAST",
        "MOTION_SOUTH",
        "MAXLLAZ",
        "P98LLAZ",
        "P98MLAZ",
        "WETBULB_0C_HGT",
        "PWAT",
        "LJA",
        "MINX",
        "MINY",
        "MAXX",
        "MAXY",
        "X",
        "Y",
    ]
    int32_cols = [
        "MLCIN",
    ]
    uint32_cols = [
        "MUCAPE",
        "MLCAPE",
        "SRH01KM",
        "FLASH_RATE",
        "CAPE_M10M30",
        "SIZE",
        "ID",
    ]
    # 0 - 255
    uint8_cols = [
        "PS",
    ]

    ddf[float32_cols] = ddf[float32_cols].astype(np.float32)
    # 32-bit signed integer (``-2_147_483_648`` to ``2_147_483_647``)
    ddf[int32_cols] = ddf[int32_cols].astype(np.int32)
    # 32-bit unsigned integer (``0`` to ``4_294_967_295``)
    ddf[uint32_cols] = ddf[uint32_cols].astype(np.uint32)
    # numpy.uint8`: 8-bit unsigned integer (``0`` to ``255``)
    ddf[uint8_cols] = ddf[uint8_cols].astype(np.uint8)
    return ddf


def __to_dask(df: pd.DataFrame, *, chunk_size: int) -> DaskDataFrame:
    return dd.from_pandas(df, chunksize=chunk_size).pipe(__wrangle_dtypes)  # type: ignore


def __name_function(time: datetime) -> Callable[[int], str]:
    yymmdd = time.strftime("%Y-%m-%d")
    return lambda n: f"{n}-{yymmdd}.pq"


def download2parquet(
    path: Path,
    *,
    start: TimeLike,
    end: TimeLike,
    freq: str = "2min",
    chunk_size: int = 256,
) -> None:
    """download and save probsevere data

    Parameters
    ----------
    path : Path
        path to where the file should be save
    start : str or datetime-like
        Left bound for generating dates.
    end : str or datetime-like
        Right bound for generating dates.
    freq : str
        string to step the urls
    name_function : `(n:int) -> str`
        ...
    chunk_size : int; defualt 256
        passed to dask, ...
    """
    drop_columns = ["MAXRC_EMISS", "MAXRC_ICECF", "AVG_BEAM_HGT", "geometry"]
    with Session() as session:
        for timestamp, values in __iterdaterange(start, end, freq=freq):
            # create the inital pandas dataframe
            (
                # download data
                pd.concat(__generate_from_features(session, urls=values["urls"]))
                # wrangle the geometry
                .pipe(__wrangle_geometry)
                .drop(columns=drop_columns)
                .pipe(__to_dask, chunk_size=chunk_size)
                .to_parquet(  # type: ignore
                    path,
                    engine="pyarrow",
                    append=True,
                    name_function=__name_function(timestamp),
                    ignore_divisions=True,
                )
            )
