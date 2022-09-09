
import argparse
from pathlib import Path
from datetime import datetime

from .io import download2parquet

parser = argparse.ArgumentParser()

parser.add_argument("--start", help="--start 2022-03-01",required=True)
parser.add_argument("--end", help="--end 2022-03-02", required=True)
parser.add_argument("--path", required=True)
# bin/download_probsevere --path=./data-bucket --start=2022-03-01 --end=2022-08-01
def date_handler(arg:str) -> datetime:
    if arg == "now":
        return datetime.utcnow()
    return datetime.fromisoformat(arg)
    
def main() -> int:
    args = parser.parse_args()
    print(args.start)
    start, end = (date_handler(getattr(args,arg)) for arg in ("start", "end"))
    path:Path = Path.cwd() / args.path
    # print(path)
    if not path.exists():
        prompt = "Path does not exsist would you like to make it? [y,n]:"
        if input(prompt) != "y":
            raise SystemExit("system exiting, no files downloaded")
        path.mkdir()

    download2parquet(path, start=start, end=end)
    return 0
            
if __name__ == "__main__":
    raise SystemExit(main())
