"""abstract base class for the grib wrapper"""
from abc import ABC, abstractmethod
from typing import Literal


class DocStrings(ABC):
    """the abstract base class"""

    @abstractmethod
    def isothermal(self):
        """
        ### coordinates:
            units : degrees_north
            standard_name :latitude

            units : degrees_east
            standard_name : longitude
            valid_time : datetime64[ns, utc]
            standard_name : valid_time

        ### Data variables:
            GRIB_name : Derived radar reflectivity
            GRIB_shortName : refd
            GRIB_units : dB


        ##
        filter_by_keys={'stepType': 'instant', 'typeOfLevel': 'isothermal'}
        filter_by_keys={'stepType': 'max', 'typeOfLevel': 'isothermal'}
        """

    @abstractmethod
    def atmosphere(self):
        """
        ### coordinates:
            units : degrees_north
            standard_name :latitude

            units : degrees_east
            standard_name : longitude

            valid_time : datetime64[ns, utc]
            standard_name : valid_time

        ### Data variables:

        name : Maximum/Composite radar reflectivity
        shortName : refc
        units : dB

        name : Vertically-integrated liquid
        shortName : veril
        units : kg m**-1

        GRIB_name : Hail
        GRIB_shortName : hail
        GRIB_units : m

        GRIB_name : Total Cloud Cover
        GRIB_shortName : tcc
        GRIB_units : %
        """

    @abstractmethod
    def hybrid(self):
        """
        ### coordinates:
            units : degrees_north
            standard_name :latitude

            units : degrees_east
            standard_name : longitude

            valid_time : datetime64[ns, utc]
            standard_name : valid_time

        Data variables:
            name : Pressure
            units : Pa
            shortName : pres

            name : Cloud mixing ratio
            units : kg kg**-1
            shortName : clwmr

            name : unknown
            units : unknown
            shortName : unknown

            name : Rain mixing ratio
            units : kg kg**-1
            shortName : rwmr

            name : Snow mixing ratio
            units : kg kg**-1
            shortName : snmr

            name : Graupel (snow pellets)
            units : kg kg**-1
            shortName : grle

            name : Particulate matter (fine)
            units : (10**-6 g) m**-3
            shortName : pmtf

            name : Particulate matter (coarse)
            units : (10**-6 g) m**-3
            shortName : pmtc

            name : Fraction of cloud cover
            units : (0 - 1)
            shortName : cc

            name : Geopotential Height
            units : gpm
            shortName : gh

            name : Temperature
            units : K
            shortName : t

            name : Specific humidity
            units : kg kg**-1
            shortName : q

            name : U component of wind
            units : m s**-1
            shortName : u

            name : V component of wind
            units : m s**-1
            shortName : v

            name : Vertical velocity
            units : Pa s**-1
            shortName : w

            name : Turbulent kinetic energy
            units : J kg**-1
            shortName : tke
        """

    @abstractmethod
    def derived_radar_reflectivity(self):
        """
        name : Derived radar reflectivity
        units : dB
        shortName : refd

        latitude : float64
        longitude : float64
        valid_time : datetime64[ns]
        """

    @abstractmethod
    def pressure(self):
        """hello radar"""

    @abstractmethod
    def mixing_ratio(self):
        """
        name : Cloud mixing ratio
        units : kg kg**-1
        shortName : clwmr

        name : Rain mixing ratio
        units : kg kg**-1
        shortName : rwmr

        name : Snow mixing ratio
        units : kg kg**-1
        shortName : snmr

        latitude : float64
        longitude : float64
        valid_time : datetime64[ns]
        """

    @abstractmethod
    def unknown(self):
        """hello radar"""

    @abstractmethod
    def graupel(self):
        """hello radar"""

    @abstractmethod
    def particulate_matter(self, kind: Literal["fine", "coarse"] = "fine"):
        """hello radar"""

    @abstractmethod
    def fraction_of_cloud_cover(self):
        """hello radar"""

    @abstractmethod
    def temperature(self):
        """hello radar"""

    @abstractmethod
    def specific_humidity(self):
        """hello radar"""

    def u_component_of_wind(self):
        """hello radar"""

    def v_component_of_wind(self):
        """hello radar"""

    def vertical_velocity(self):
        """hello radar"""

    def turbulent_kinetic_energy(self):
        """hello radar"""
