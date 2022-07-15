import dataclasses
from abc import abstractmethod
from datetime import datetime, timedelta
from typing import Literal, Callable, TypeVar, ParamSpec, Iterator

import s3fs
import pandas as pd
import xarray as xr
from IPython.display import HTML

from griblib.hrrr._zarr import ZArrTable

T = TypeVar("T")
P = ParamSpec("P")
idx: slice = pd.IndexSlice


class SharedTable:
    __table = ZArrTable[["vertical_level", "parameter_short_name"]]

    @property
    def __model_type(self):
        if isinstance(self, Forecast):
            return "fcst", "both"
        elif isinstance(self, Analysis):
            return "anl", "both"
        else:
            return "fcst", "anl", "both"

    def __repr__(self) -> str:
        return self.table.__repr__()

    def _repr_html_(self) -> HTML:
        return self.table._repr_html_()

    @property
    def table(self) -> pd.DataFrame:
        return self.__table.loc[idx[self.__model_type, :], :].droplevel(0).copy()


class Base(SharedTable):
    def __init__(self, hrrr: "HRRR", level_type: Literal["sfc", "prs"]):
        model_type = "fcst" if isinstance(self, Forecast) else "anl"
        base_url = f"s3://hrrrzarr/{level_type}/" + hrrr.date_range.strftime(f"%Y%m%d/%Y%m%d_%Hz_{model_type}.zarr")

        def generate_urls():
            for long_name, (vlevel, short_name) in self.table.iterrows():
                base = base_url + f"/{vlevel}/{short_name}"
                yield (long_name, vlevel), tuple(zip(base, base + f"/{vlevel}"))

        self.hrrr = hrrr
        self._urldf = pd.DataFrame(dict(generate_urls()), index=hrrr.date_range)

    def iterload(self, long_name: str, vertical_level: str) -> Iterator[xr.Dataset]:
        for urls in self._urldf[long_name, vertical_level]:
            yield xr.open_mfdataset(
                (s3fs.S3Map(url, s3=self.hrrr.fs) for url in urls),
                engine="zarr",
            )


def loadermethod(func: Callable[P, T]) -> Callable[P, T]:
    # possible_levels = get_args(func.__annotations__["vertical_level"])
    anno = func.__annotations__.copy()
    anno.pop("return", None)
    # ds_callback = xr.Dataset in func.__annotations__.values()
    default: tuple[str, ...] = func.__defaults__
    if default:
        (default_value,) = default

    long_name = func.__name__

    def inner(self: "Base", vertical_level: str = default_value):
        return xr.concat(
            self.iterload(long_name, vertical_level),
            dim="valid_time",
            combine_attrs="override",
        )

    return inner


class Both(Base):
    @loadermethod
    @abstractmethod
    def temperature(
        self,
        vertical_level: Literal[
            "1000mb", "2m_above_ground", "500mb", "700mb", "850mb", "925mb", "surface"
        ] = "surface",
    ) -> xr.Dataset:
        ...

    @loadermethod
    @abstractmethod
    def hail(
        self, vertical_level: Literal["0.1_sigma_layer", "entire_atmosphere", "surface"] = "surface"
    ) -> xr.Dataset:
        ...

    @loadermethod
    @abstractmethod
    def vertical_velocity(self, vertical_level: Literal["0.5_0.8_sigma_layer", "700mb"] = "700mb") -> xr.Dataset:
        ...


class Forecast(Both):
    ...


class Analysis(Both):
    ...


# LevelType inherits the SharedTable the so the entire table can be viewed
class LevelType(SharedTable):
    def __init__(self, hrrr: "HRRR", level_type: Literal["sfc", "prs"]):
        self.__forecast = Forecast(hrrr, level_type)
        self.__analysis = Analysis(hrrr, level_type)

    @property
    def forecast(self) -> Forecast:
        """forecast property"""
        return self.__forecast

    @property
    def analysis(self) -> Analysis:
        """analysis property"""
        return self.__analysis


@dataclasses.dataclass
class HRRR:
    start_date: datetime
    hours: int
    date_range: pd.DatetimeIndex
    fs: s3fs.S3FileSystem

    @property
    def surface(self) -> LevelType:
        """surface property"""
        return LevelType(self, level_type="sfc")

    @property
    def pressure(self) -> LevelType:
        """pressure property"""
        return LevelType(self, level_type="prs")


def load_hrrr(start_date: datetime, hour_delta: int) -> HRRR:
    date_range = pd.date_range(start_date, start_date + timedelta(hours=hour_delta))
    return HRRR(start_date, hour_delta, date_range, s3fs.S3FileSystem(anon=True))
