#!/usr/bin/env python3
"""Validate story scripts and rebuild their checked-in hash archives."""

from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path


def story_id(directory: Path) -> str:
    identifier = directory.name.split(".", 1)[0]
    if not identifier.isdigit():
        raise SystemExit(f"story directory must start with a numeric id: {directory}")
    return identifier


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", type=Path, required=True)
    parser.add_argument("--hashpack", type=Path, required=True)
    parser.add_argument(
        "--content",
        type=Path,
        default=Path(__file__).resolve().parent / "content",
    )
    args = parser.parse_args()

    compiler = args.compiler.resolve()
    hashpack = args.hashpack.resolve()
    content = args.content.resolve()
    for executable in (compiler, hashpack):
        if not executable.is_file() or not os.access(executable, os.X_OK):
            raise SystemExit(f"executable not found: {executable}")

    stories = sorted(
        (directory for directory in content.iterdir() if (directory / "script.sh").is_file()),
        key=lambda directory: int(story_id(directory)),
    )
    if not stories:
        raise SystemExit(f"no story scripts found under {content}")

    for directory in stories:
        identifier = story_id(directory)
        print(f"Building story {identifier}: {directory.name}", flush=True)
        subprocess.run([compiler, "-c", identifier], cwd=directory, check=True)
        temporary_archive = directory / "script.har.tmp"
        temporary_archive.unlink(missing_ok=True)
        try:
            subprocess.run(
                [hashpack, "-c", temporary_archive.name, "script.sh"],
                cwd=directory,
                check=True,
            )
            temporary_archive.replace(directory / "script.har")
        finally:
            temporary_archive.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
