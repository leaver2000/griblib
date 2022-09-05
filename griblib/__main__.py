from pathlib import Path
from ._bbox import BoundingBox
from .probsevere._pq import parquet_session


def main(files: tuple[Path, ...]):
    bbox = BoundingBox(20.005, 54.995, -60.005, -129.995, shape=(7000, 2500))
    with parquet_session(files) as gdf:
        gdf["Y"] = bbox.fit_array(gdf["Y"].values, axis="Y")
        gdf["X"] = bbox.fit_array(gdf["X"].values, axis="X")
        print(gdf)


if __name__ == "__main__":
    ps_data = Path.cwd() / "data-bucket"
    all_files = tuple(ps_data.rglob("*.pq"))
    assert len(all_files) == 8612
    bbox = BoundingBox(20.005, 54.995, -129.995, -60.005, shape=(7000, 2500))
    main(all_files[: len(all_files) // 40])
