from typing import Literal
import pytest
from griblib.exceptions import enforce_literal


def test_enforce():
    @enforce_literal(IndentationError, case_insensitive=True)
    def func_1(*, kwarg: Literal["X", "Y"] = ...):
        return True

    assert func_1(kwarg="X")
    assert func_1(kwarg="x")
    assert func_1(kwarg="Y")
    assert func_1(kwarg="y")

    with pytest.raises(IndentationError):
        func_1(kwarg="HEllO")

    @enforce_literal(KeyError, case_insensitive=False)
    def func_2(*, kwarg: Literal["X", "Y"] = ...):
        return True

    assert func_2(kwarg="X")
    assert func_2(kwarg="Y")

    with pytest.raises(KeyError):
        func_2(kwarg="x")
    with pytest.raises(KeyError):
        func_2(kwarg=1)
