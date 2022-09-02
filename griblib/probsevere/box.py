from pathlib import Path
from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Callable, Iterable, Generator, Literal

try:
    from cudf import DataFrame, read_parquet
    import cupy as cp
except ModuleNotFoundError:
    from cudf import DataFrame, read_parquet
    import numpy as cp

import numpy as np
import nvector as nv
from numpy.typing import NDArray


class CUDArray(NDArray):
    def get(self) -> np.ndarray:
        ...


class CaseInsensiveSTR(str):
    def __eq__(self, __other: str):
        return self.casefold() == __other.casefold()


@contextmanager
def parquet_session(
    files: Iterable[Path], *, engine: str = "cudf", index: list[str] = ["VALIDTIME", "ID"]
) -> Generator[DataFrame, None, None]:
    """

    context manager to remove the dataframe from the gpu memory
    """
    try:
        gdf = read_parquet(files, engine=engine).set_index(index).sort_index()
        yield gdf
    finally:
        del gdf


def enforce_literal(exc: Exception = Exception, case_insensitive: bool = True):
    """
    decorator function to inforce Litteral type hint annotations on keyword arguments
    """

    def __generate(_func_kwargs: dict[str, any]):
        for k, v in _func_kwargs.items():
            if v.__class__.__name__ == "_LiteralGenericAlias":
                yield k, tuple(
                    _v if case_insensitive and not isinstance(_v, str) else CaseInsensiveSTR(_v) for _v in v.__args__
                )

    def wraps(func: Callable):
        enforce = tuple(__generate(func.__annotations__))

        def inner(*args, **kwargs):
            for k, v in enforce:
                if not kwargs[k] in v:
                    raise exc
            return func(*args, **kwargs)

        return inner

    return wraps


@dataclass(frozen=True)
class BoundingBox:
    """
    Nominatim API
    Nominatim API returns a boundingbox property of the form:

    south Latitude, north Latitude, west Longitude, east Longitude
    For example, Greater London in JSON format:

    "boundingbox":["51.2867602","51.6918741","-0.5103751","0.3340155"]


    ```
    bbox = BoundingBox(20.005, 54.995, -129.995, -60.005, shape=(7000, 2500))
    with gpu_session(files) as gdf:
        gdf["X"] = bbox.fit_array(gdf["X"].values, axis=0)
        gdf["Y"] = bbox.fit_array(gdf["Y"].values, axis=1)
    ```
    """

    south: float
    north: float
    east: float
    west: float
    shape: tuple[int, int]
    frame_e: nv.FrameE = field(repr=False, default=nv.FrameE(name="WGS84"))

    @property
    def latitudes(self) -> CUDArray:
        _, y_num = self.shape
        return cp.linspace(
            self.south,  # south lat
            self.north,  # north lat
            y_num,  # points in between
            dtype=cp.float32,
        )

    @property
    def longitudes(self) -> CUDArray:
        x_num, _ = self.shape
        return cp.linspace(
            self.west,  # west lon
            self.east,  # east lon
            x_num,  # points in between
            dtype=cp.float32,
        )

    @property
    def matrix(self) -> CUDArray:
        return cp.array(cp.meshgrid(self.latitudes, self.longitudes), dtype=cp.float32).T

    @property
    def latrange(self) -> tuple[float, float]:
        return self.north, self.south

    @property
    def lonrange(self) -> tuple[float, float]:
        return self.west, self.east

    @property
    def y_dist(self) -> CUDArray:

        return self.__calculate_step(
            self.longitudes,
            self.latrange,
            len(self.latitudes),
        )

    @property
    def x_dist(self) -> CUDArray:

        return self.__calculate_step(
            self.latitudes,
            self.lonrange,
            len(self.longitudes),
        )

    def __calculate_step(self, target: CUDArray, step_range: tuple[float, float], count: int) -> CUDArray:
        """
        calculates the geometric distance within the bounding box

        ```
        array_west, array_east = np.array(list([bbox.lonrange]) * len(bbox.lattitudes)).T

        ecef_west = bbox.frame_e.GeoPoint(bbox.lattitudes.get(), array_west, degrees=True).to_ecef_vector()

        ecef_east = bbox.frame_e.GeoPoint(bbox.lattitudes.get(), array_east, degrees=True).to_ecef_vector()

        ecef_delta = ecef_east - ecef_west

        return cp.array(ecef_delta.length) / len(bbox.longitudes)
        ```
        """

        array_a, array_b = np.array([[step_range]] * len(target)).T

        ecef_a = self.frame_e.GeoPoint(target.get(), array_a, degrees=True).to_ecef_vector()

        ecef_b = self.frame_e.GeoPoint(target.get(), array_b, degrees=True).to_ecef_vector()

        ecef_delta = ecef_a - ecef_b

        return cp.array(ecef_delta.length) / count

    @enforce_literal(KeyError)
    def fit_array(self, values: CUDArray, axis: Literal["x", "y"]) -> CUDArray:
        target = getattr(self, {"x": "longitudes", "y": "latitudes"}[axis.lower()])
        return target[cp.argmin(abs(target - values[:, cp.newaxis]), axis=1)]
