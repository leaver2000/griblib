import urllib.parse
from collections import ChainMap
from enum import Enum, EnumMeta, auto
from typing import TypeVar, Iterable, Generator, NewType

import numpy as np
import pandas as pd


Names = TypeVar("Names", str, list[str], tuple[str])
StrGenerator = NewType("Generator[str, ...]", Generator[str, None, None])


class StrEnum(str, Enum):
    name: str
    value: str

    def __iter__(self: type[Enum]) -> StrGenerator:
        yield from super().__iter__()


def _urlencode(items: Iterable["QueryEnum"]) -> str:
    return urllib.parse.urlencode(tuple((member.__query_name__, member.value) for member in items))


class QueryMap(ChainMap):
    def __str__(self) -> str:
        return _urlencode(super().__iter__())

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}({', '.join(member.__repr__() for member in super().__iter__())})"

    def __and__(self, __o: "QueryMap") -> str:
        return str(QueryMap(__o, self))
        

class QueryEnumMeta(EnumMeta):
    def __values(self: type[StrEnum]) -> StrGenerator:
        yield from (member.value for member in super().__iter__())

    def __names(self: type[StrEnum]) -> StrGenerator:
        yield from (member.name for member in super().__iter__())

    def __string_contains(self, __o: str) -> bool:
        return __o in self.__values() or __o in self.__names()

    def names(self) -> tuple[str, ...]:
        return tuple(self.__names())

    def values(self) -> tuple[str, ...]:
        return tuple(self.__values())

    def __str__(self) -> str:
        return _urlencode(super().__iter__())

    def __getitem__(self, names: Names) -> QueryMap:
        if not isinstance(names, list):
            names = (names,)
        return QueryMap(tuple(self._member_map_[name] for name in names))

    def __contains__(self, __o: object) -> bool:
        if isinstance(__o, str):
            return self.__string_contains(__o)
        return super().__contains__(__o)

    def __eq__(self, __o: object) -> bool:
        if isinstance(__o, str):
            return self.__string_contains(__o)
        return super().__eq__(__o)

    def __and__(self, __o: StrEnum) -> QueryMap:
        return QueryMap(self, __o)

    def __hash__(self) -> int:
        return super().__hash__()

class QueryEnum(StrEnum, metaclass=QueryEnumMeta):
    def _generate_next_value_(self, *_) -> str:
        return self

    def __repr__(self):
        return f"{self.__query_name__}={self.value}"

    @classmethod
    def __lt__(cls, __o: "QueryEnum") -> bool:
        return cls.__query_name__ < __o.__query_name__

    @classmethod
    @property
    def __query_name__(cls) -> str:
        return cls.__name__.lower()


class Models(QueryEnum):
    GALWEM = auto()
    NAM = auto()
    GFS = auto()
    WRF_17K = "WRF-1.7k"


class Parameters(QueryEnum):
    wind_direction = auto()
    wind_speed = auto()
    wind_gust = auto()
    visibility = auto()
    present_wx = auto()
    ten_meter_temp = "10_m_temp"


localhost = "http://localhost:8080"


def main():

    # inherited methods
    assert Parameters("10_m_temp") == Parameters.ten_meter_temp
    assert Parameters.ten_meter_temp == "10_m_temp"
    assert Parameters.ten_meter_temp.upper() == "10_M_TEMP"
    # __str__
    assert (
        f"{localhost}?{QueryMap(Parameters,Models)}"
        == f"{localhost}?{Parameters & Models}"
        == f"{localhost}?{Models}&{Parameters}"
        == "http://localhost:8080?models=GALWEM&models=NAM&models=GFS&models=WRF-1.7k&parameters=wind_direction&parameters=wind_speed&parameters=wind_gust&parameters=visibility&parameters=present_wx&parameters=10_m_temp"
    )
    # __eq__ __contains__
    assert "GALWEM" in Models
    assert Models.GALWEM in Models
    assert Models in ("GALWEM", "NAM")

    assert "BAD_USER_REQUEST" not in Models

    assert f"{localhost}?{Models & Parameters}" == f"{localhost}?{QueryMap(Models,Parameters)}"
    # 3rd party libs
    # numpy
    a = np.array(Models & Parameters, dtype=object)
    mask = (a == "GALWEM") | (a == "NAM") | (a == "wind_speed")
    assert f"{localhost}?{QueryMap(a[mask])}" == "http://localhost:8080?parameters=wind_speed&models=GALWEM&models=NAM"
    # pandas
    s = pd.Series(tuple(Parameters), index=Parameters.names())
    assert (
        f"{localhost}?{QueryMap(s[s.str.contains('wind')])}"
        == "http://localhost:8080?parameters=wind_direction&parameters=wind_speed&parameters=wind_gust"
    )
    print(
        f"""
__getitem__() __and__()
{localhost}?{Models['GALWEM'] &  Parameters}

{localhost}?{Models[['GALWEM', 'NAM']] & Parameters}

{localhost}?{Models[['GALWEM', 'NAM']] & Parameters['wind_direction']}
numpy
{a}
pandas
{s}
    """
    )

    print(f"""
    littering and...

    {Models & Parameters}

    {Models and Parameters}
    
    
    """)


if __name__ == "__main__":
    main()
