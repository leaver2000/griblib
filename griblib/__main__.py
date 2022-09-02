from pathlib import Path
from .probsevere.box import BoundingBox, parquet_session


def main(files: tuple[Path, ...]):
    bbox = BoundingBox(20.005, 54.995, -129.995, -60.005, shape=(7000, 2500))
    with parquet_session(files[:10]) as gdf:
        print(gdf)
        gdf["Y"] = bbox.fit_array(gdf["Y"].values, axis="Y")
        gdf["X"] = bbox.fit_array(gdf["X"].values, axis="X")
        df = gdf.to_pandas()
    print(df)


if __name__ == "__main__":
    ps_data = Path.cwd() / "data-bucket"
    all_files = tuple(ps_data.rglob("*.pq"))
    assert len(all_files) == 8612
    bbox = BoundingBox(20.005, 54.995, -129.995, -60.005, shape=(7000, 2500))

    main(all_files)
