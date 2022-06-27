import xarray as xr
from typing import Literal
from griblib.common import GribBase, filter_by_level
from griblib._abc import DocStrings



class ByLevel(GribBase, DocStrings):

    @filter_by_level("atmosphere")
    def atmosphere(self):
        """returns all attributes at with the shared `atmosphere` level"""

    @filter_by_level("isothermal")
    def isothermal(self):
        """returns all attributes at with the shared `isothermal` level"""
        return {"stepType": "instant"}

    @filter_by_level("hybrid")
    def hybrid(self):
        """returns all attributes at with the shared `hybrid` level"""

    @filter_by_level("heightAboveGroundLayer")
    def height_above_ground_layer(self):
        """returns all attributes at with the shared `heightAboveGroundLayer` level"""


class HRRR(ByLevel):
    def geopotential_height(self, level="isothermal") -> xr.Dataset:
        match level:
            case "isothermal":
                return super().isothermal(name="Geopotential Height", stepType="instant")
            case "hybrid":
                return super().hybrid(name="Geopotential Height")

    def pressure(self) -> xr.Dataset:
        return super().hybrid(name="Pressure")

    def unknown(self) -> xr.Dataset:
        return super().hybrid(name="unknown")

    def mixing_ratio(self, kind: Literal["rain", "snow", "cloud"] = "rain") -> xr.Dataset:
        return super().hybrid(name=f"{kind.title()} mixing ratio")

    def graupel(self) -> xr.Dataset:
        return super().hybrid(name="Graupel (snow pellets)")

    def particulate_matter(self, kind: Literal["fine", "coarse"] = "fine") -> xr.Dataset:
        return super().hybrid(name=f"Particulate matter ({kind})")

    def fraction_of_cloud_cover(self) -> xr.Dataset:
        return super().hybrid(name="Fraction of cloud cover")

    def temperature(self) -> xr.Dataset:
        return super().hybrid(name="Temperature")

    def specific_humidity(self) -> xr.Dataset:
        return super().hybrid(name="Specific humidity")

    def u_component_of_wind(self) -> xr.Dataset:
        return super().hybrid(name="U component of wind")

    def v_component_of_wind(self):
        return super().hybrid(name="V component of wind")

    def vertical_velocity(self) -> xr.Dataset:
        return super().hybrid(name="Vertical velocity")

    def turbulent_kinetic_energy(self) -> xr.Dataset:
        return super().hybrid(name="Turbulent kinetic energy")

    def derived_radar_reflectivity(self, step_type: Literal["max", "instant"] = "instant") -> xr.Dataset:
        return super().isothermal(name="Derived radar reflectivity", stepType=step_type)
