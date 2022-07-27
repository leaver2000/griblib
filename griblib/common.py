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

    def multi_file_dataset(self) -> list[str]:
        """multi-file dataset"""
        return self._file_list


def filter_by_level(
    level: str,
    chunks={"valid_time": 1, "x": 1799, "y": 1059},
    target_coordinates: tuple[str] = ("latitude", "longitude", "valid_time"),
):
    """decorator function around xarray.open_mfdataset"""

    def func_wrapper(func: Callable[["GribBase"], dict[str, str] | None]):
        """intermediate func wrapper contains the callback which returns the default return when called"""

        @overload
        def key_filter(
            self: GribBase,
            name: str = ...,
            stepType: Literal["max", "instant"] = ...,
            shortName: str = ...,
            standard_name: str = ...,
            data_vars: str = "all",
            **kwargs: str,
        ) -> xr.Dataset:
            ...

        def key_filter(grib: GribBase, **kwargs: str) -> xr.Dataset:
            """concatenates multiple grib files along the temporal dimension"""

            default_return = func(grib)

            if not default_return:
                filter_by_keys = {"typeOfLevel": level} | kwargs
            else:
                filter_by_keys = {"typeOfLevel": level} | default_return | kwargs

            ds: xr.Dataset = xr.open_mfdataset(
                grib.multi_file_dataset(),
                concat_dim="valid_time",
                combine="nested",
                engine="cfgrib",
                filter_by_keys=filter_by_keys,
                chunks=chunks,
            )
            return ds.drop_vars(coord for coord in ds.coords if coord not in target_coordinates)

        return key_filter

    return func_wrapper
