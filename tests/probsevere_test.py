from pathlib import Path
import shutil
import pandas as pd
import requests

import griblib.probsevere as ps
from griblib.probsevere.io import URL_TEMPLATE, VALIDTIME_TEMPLATE
from griblib.probsevere.typed import FeatureCollection


mock_file = Path("tests/data/MRMS_PROBSEVERE_20220720_000000.json")


def test_archive_retrevial(requests_mock: requests, feature_collection: FeatureCollection) -> None:
    start = "2022-01-01T00:00"
    end = "2022-01-01T00:02"
    dr = pd.date_range(start=start, end=end, freq="2min")
    tmp_dir = Path("/tmp/griblib/tests/probsevere")

    if tmp_dir.exists():
        shutil.rmtree(tmp_dir)

    for time, url in zip(dr.strftime(VALIDTIME_TEMPLATE.replace("%Z", "UTC")), dr.strftime(URL_TEMPLATE)):
        feature_collection["validTime"] = time
        requests_mock.get(url, json=feature_collection)
    #  return noithing
    assert not ps.download2parquet(tmp_dir, start=start, end=end)
    # all everything in the directory
    for f in tmp_dir.glob("*"):
        # is a file
        assert f.is_file()
        # that ends with ".pq"
        assert f.suffix == ".pq"
    
