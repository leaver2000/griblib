import uuid
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Literal, Union

import aiohttp
import xarray as xr
import pandas as pd

TMP = Path("/tmp")
GMGSIProducts = Literal["GMGSI_LW", "GMGSI_SSR", "GMGSI_SW", "GMGSI_VIS", "GMGSI_WV"]
TimeLike = Union[str, datetime, pd.Timestamp]


def get_url_template(prod: GMGSIProducts) -> str:
    bucket = {
        "GMGSI_LW": "GLOBCOMPLIR_nc",
        "GMGSI_SSR": "GLOBCOMPSSR_nc",
        "GMGSI_SW": "GLOBCOMPSIR_nc",
        "GMGSI_VIS": "GLOBCOMPVIS_nc",
        "GMGSI_WV": "GLOBCOMPWV_nc",
    }
    return f"https://noaa-gmgsi-pds.s3.amazonaws.com/{prod}/%Y/%m/%d/%H/{bucket[prod]}.%Y%m%d%H"


async def _tmppath(data: bytes) -> Path:
    tmp_file = TMP / str(uuid.uuid1())
    with tmp_file.open("wb") as tmp:
        tmp.write(data)
    return tmp_file


async def fetch_path(session: aiohttp.ClientSession, url: list[str]) -> Union[Path, None]:
    async with session.get(url) as r:
        if r.status == 200:
            data = await r.read()
            if data:
                return await _tmppath(data)
            else:
                print(f"error downloading {url}")


async def fetch_all_paths(session: aiohttp.ClientSession, urls: list[str]) -> list[Path]:
    tasks = []
    for url in urls:
        if task := asyncio.create_task(fetch_path(session, url)):
            tasks.append(task)

    return await asyncio.gather(*tasks)


async def _main(urls: list[str]) -> list[Path]:
    async with aiohttp.ClientSession() as session:
        return await fetch_all_paths(session, urls)


def gmgsi(start: TimeLike, stop: TimeLike, product: GMGSIProducts = "GMGSI_WV"):
    """
    Global Mosaic of Geostationary Satellite Imagery
    """
    urls = pd.date_range(start, stop, freq="H").strftime(get_url_template(product))
    paths = asyncio.run(_main(urls))  # [path for path in asyncio.run(_main(urls)) if path]
    paths = [path for path in paths if path]
    # return paths
    # if not paths:
    #     return None

    ds = xr.open_mfdataset(paths, engine="netcdf4", concat_dim="time", combine="nested")
    for path in paths:
        path.unlink()
    return ds
