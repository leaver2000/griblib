"""extension for working with jupyter notebooks"""
# griblib.jupyter.py
from IPython.terminal.interactiveshell import TerminalInteractiveShell


def load_ipython_extension(ipython: TerminalInteractiveShell) -> None:
    import nest_asyncio
    import jupyter_black

    nest_asyncio.apply()
    jupyter_black.load_ipython_extension(ipython)


def unload_ipython_extension(ipython: TerminalInteractiveShell) -> None:
    ...
    # If you want your extension to be unloadable, put that logic here.
