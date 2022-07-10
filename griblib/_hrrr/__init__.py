import json
import pandas as pd
from pathlib import Path
from os.path import dirname
idx:slice = pd.IndexSlice
_table_path = Path(dirname(__file__)).absolute() / "table.json"
def pythonic_long_name(df:pd.DataFrame)->pd.DataFrame:
    df["parameter_long_name"] = df["parameter_long_name"].str.replace(" ","_").str.lower()
    
    return df
with open(_table_path, "rt") as f:
    ZArrTable: pd.DataFrame = (
        pd.DataFrame(**json.load(f))
        .pipe(pythonic_long_name)
        .set_index(
            [
                "analysis_or_forecast",
                "parameter_long_name",
            ]
        )
        .loc[idx[("both", "fcst", "anl"), :], :]
    )
