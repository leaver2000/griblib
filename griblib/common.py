"""common grib object"""
from typing import Callable, Literal, Iterator, overload
import xarray as xr


class GribBase:
    """base grib class"""

    def __init__(self, files: list[str]) -> None:
        self._file_list = files

    def __repr__(self):
        props = ", ".join(attr for attr in self.__dir__() if not attr.startswith("_"))
        return f"{self.__class__.__name__}.properties({props})"

    def iterfiles(self) -> Iterator[str]:
        """file iterator"""
        yield from self._file_list


def filter_by_level(level: str):
    """decorator"""

    lat_lon_vt = {"latitude", "longitude", "valid_time"}

    def generator(grib: GribBase, **kwargs):
        for file in grib.iterfiles():
            with xr.open_dataset(
                file,
                engine="cfgrib",
                **kwargs,
            ) as ds:
                if lat_lon_vt.issubset(ds.coords):
                    yield ds.drop_vars(coord for coord in ds.coords if coord not in lat_lon_vt)

    def func_wrapper(func: Callable[["GribBase"], dict[str, str] | None]):
        """the func() is the returned value from the function"""

        @overload
        def key_filter(
            self: "GribBase",
            name: str = ...,
            stepType: Literal["max", "instant"] = ...,
            shortName: str = ...,
            standard_name: str = ...,
            **kwargs: str,
        ) -> xr.Dataset:
            ...

        def key_filter(grib: "GribBase", **kwargs: str) -> xr.Dataset:
            """the wrapped func"""

            default_return = func(grib)

            if not default_return:
                filter_by_keys = {"typeOfLevel": level} | kwargs
            else:
                filter_by_keys = {"typeOfLevel": level} | default_return | kwargs

            objs = generator(
                grib,
                filter_by_keys=filter_by_keys,
                chunks={},
            )
            return xr.concat(objs, dim="valid_time")

        return key_filter

    return func_wrapper
