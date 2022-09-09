import argparse
from typing import Type


class NameSpace(argparse.Namespace, Type):
    name: str


class CustomParser(argparse.ArgumentParser):
    def parse_args(self) -> NameSpace:
        return super().parse_args()


parser = CustomParser()

parser.add_argument("--name")

if __name__ == "__main__":
    args = parser.parse_args()


    print(args.name)
