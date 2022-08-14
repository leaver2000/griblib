import json
from pathlib import Path

import pytest

from griblib.probsevere.typed import FeatureCollection

mock_file = Path("tests/data/MRMS_PROBSEVERE_20220720_000000.json")


@pytest.fixture(autouse=True)
def feature_collection() -> FeatureCollection:
    with mock_file.open("rt") as f:
        return json.load(f)
