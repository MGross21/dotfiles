"""Push store path closures to a Cachix cache, minus NVIDIA/CUDA and all that depend on them.

Usage: cachix-push CACHE PATH...
"""

import json
import re
import subprocess
import sys
from functools import cache

UNFREE = re.compile(r"nvidia|cuda|cudnn|cublas|cufft|curand|cusolver|cusparse|nccl|cccl")


def closure(paths: list[str]) -> dict[str, dict]:
    out = subprocess.run(
        ["nix", "path-info", "--json", "--json-format", "1", "--recursive", *paths],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return {path: meta or {} for path, meta in json.loads(out).items()}


def redistributable(info: dict[str, dict]) -> list[str]:
    @cache
    def tainted(path: str) -> bool:
        refs = (ref for ref in info[path].get("references", []) if ref != path and ref in info)
        return bool(UNFREE.search(path)) or any(map(tainted, refs))

    return [path for path in info if not tainted(path)]


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    cache_name, *paths = sys.argv[1:]
    sys.setrecursionlimit(10_000)
    keep = redistributable(closure(paths))
    subprocess.run(["cachix", "push", cache_name], input="\n".join(keep), text=True, check=True)


if __name__ == "__main__":
    main()
