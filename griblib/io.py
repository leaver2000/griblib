

# """input output for probsevere data"""
__all__ = ["iterdaterange"]
from datetime import datetime
from typing import  Iterator, Union
import pandas as pd


TimeLike = Union[datetime, str, pd.Timestamp]

def iterdaterange(
    start: TimeLike, end: TimeLike, *, freq: str = "2min", url_pattern:str=...
) -> Iterator[tuple[pd.Timestamp, pd.DataFrame]]:
    """yields the probsevere urls grouped by dates

    Parameters
    ----------
    start : str or datetime-like
        Left bound for generating dates.
    end : str or datetime-like
        Right bound for generating dates.
    freq : str or DateOffset, by default '2min'


    Yields
    ------
    Iterator[tuple[pd.Timestamp, pd.DataFrame]]
        _description_
    """
    dr = pd.date_range(start=start, end=end, freq=freq)
    urls = dr.strftime(url_pattern)
    yield from pd.DataFrame({"date": dr, "urls": urls}).set_index(dr).groupby(pd.Grouper(key="date", freq="D", axis=0))