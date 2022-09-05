from typing import Callable
from griblib.common import CaseInsensiveSTR


def enforce_literal(exc: Exception = Exception, case_insensitive: bool = True):
    """
    decorator function to enforce Literal type hint annotations on keyword arguments
    """

    def generate(annotations: dict[str, type]):
        for key, anno in annotations.items():
            if anno.__class__.__name__ == "_LiteralGenericAlias":
                yield key, tuple(
                    CaseInsensiveSTR(val) if case_insensitive and isinstance(val, str) else val
                    for val in anno.__args__
                )

    def wraps(func: Callable):
        enforce = tuple(generate(func.__annotations__))

        def literal_enforcer(*args, **kwargs):
            """
            validates keyword argument literal typehinting
            """
            for key, val in enforce:
                if not kwargs[key] in val:
                    raise exc(
                        f"the {key} keyword argument expects a Literal{list(val)} value but received '{kwargs[key]}'"
                    )
            return func(*args, **kwargs)

        return literal_enforcer

    return wraps
