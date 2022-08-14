from typing import Literal, TypedDict


class Properties(TypedDict):
    MUCAPE: int
    MLCAPE: int
    MLCIN: int
    EBSHEAR: float
    SRH01KM: int
    MESH: float
    VIL_DENSITY: float
    FLASH_RATE: int
    FLASH_DENSITY: float
    MAXLLAZ: float
    P98LLAZ: float
    P98MLAZ: float
    MAXRC_EMISS: str
    MAXRC_ICECF: str
    WETBULB_0C_HGT: float
    PWAT: float
    CAPE_M10M30: int
    LJA: float
    SIZE: int
    AVG_BEAM_HGT: str
    MOTION_EAST: float
    MOTION_SOUTH: float
    PS: int
    ID: int


class Geometry(TypedDict):
    type: Literal["Polygon"]
    coordinates: list[list[tuple[float, float]]]


class Feature(TypedDict):
    type: Literal["Feature"]
    geometry: Geometry
    models: dict[str, dict[str, str]]
    properties: Properties


class FeatureCollection(TypedDict):
    source: Literal["NOAA/NCEP Central Operations"]
    product: Literal["ProbSevere"]
    type: Literal["FeatureCollection"]
    validTime: str
    productionTime: str
    machine: str
    features: list[Feature]
