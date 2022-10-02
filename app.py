from enum import Enum, EnumMeta
from typing import Literal, NewType, TypeVar, Protocol, Generic, ParamSpec, Union, overload, Type, Concatenate
import pandas as pd
import abc

T = TypeVar("T")
C = TypeVar("C")
class B:
    def __new__(cls: type[C],*args) -> type["B"]:
        print(cls.__subclasses__())
        class A(cls):...
        return A
        
    @classmethod
    @property
    def _member_map_(cls):
        print("JAJAJAJ")
        def update():
            for key in dir(cls):
                if key.startswith("_"):
                    continue

                value = getattr(cls, key)

                if isinstance(value, str):
                    setattr(cls, key, key)

                yield key, value

        cls._member_map_ = dict(update())
        return cls._member_map_

class G(B):
    hello='world'
print(G)

print(f"""{G.hello.upper()}
{G._member_map_.items()}
{G._member_map_.items()}
{G.hello}
"""
)


class Model(Protocol[C]):
    @property
    def _member_map_(cls: "Model") -> dict[str, any]:
        ...


def known(cls: type[C]) -> Model[C] | type[C]:
    class _F(cls):
        def __new__(cls: Model, *args):
            return list(cls._member_map_.keys())

    def update():
        for key in dir(cls):
            if key.startswith("_"):
                continue

            value = getattr(cls, key)

            if isinstance(value, str):
                setattr(_F, key, key)

            yield key, value

    _F._member_map_ = dict(update())

    return _F


@known
class Columns:
    hello = "world"
    to_the = "something"


# Columns.hello
# # Columns.fff
# Columns._member_map_.items
# print(Columns.hello)
# print(Columns())
# Columns.mro