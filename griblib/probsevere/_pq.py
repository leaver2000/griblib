__all__ = ["parquet_session"]
from pathlib import Path
from contextlib import contextmanager
from typing import Iterable, Generator

try:
    from cudf import DataFrame, read_parquet

    ENGINE = "cudf"
except ModuleNotFoundError:
    from pandas import DataFrame, read_parquet

    ENGINE = "pyarrow"


@contextmanager
def parquet_session(
    files: Iterable[Path], *, engine: str = ENGINE, index: list[str] = ["VALIDTIME", "ID"]
) -> Generator[DataFrame, None, None]:
    """
    context manager to remove the dataframe from the gpu memory
    """
    try:
        gdf = read_parquet(files, engine=engine).set_index(index).sort_index()
        yield gdf
    finally:
        del gdf
