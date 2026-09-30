#!/usr/bin/env python3
"""Greedy-mesh project VOX assets with Vengi without replacing originals."""

from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

from normalize_vengi_obj import normalize


def matching_assets(project_root: Path) -> list[tuple[Path, Path]]:
    assets = []
    for vox_path in sorted((project_root / "assets").rglob("*.vox")):
        obj_path = vox_path.with_suffix(".obj")
        if obj_path.is_file():
            assets.append((vox_path, obj_path))
    return assets


def optimize(
    vengi_bin: Path,
    project_root: Path,
    output_root: Path,
    assets: list[tuple[Path, Path]],
) -> None:
    total_before = 0
    total_after = 0

    with tempfile.TemporaryDirectory(prefix="tof-vengi-") as temporary_directory:
        temporary_root = Path(temporary_directory)
        for index, (vox_path, reference_path) in enumerate(assets, 1):
            relative_path = reference_path.relative_to(project_root)
            raw_path = temporary_root / relative_path
            output_path = output_root / relative_path
            raw_path.parent.mkdir(parents=True, exist_ok=True)

            subprocess.run(
                [
                    str(vengi_bin),
                    "--force",
                    "-set",
                    "voxformat_meshmode",
                    "2",
                    "-set",
                    "voxformat_withtexcoords",
                    "true",
                    "-set",
                    "voxformat_withmaterials",
                    "true",
                    "--input",
                    str(vox_path),
                    "--output",
                    str(raw_path),
                ],
                check=True,
            )

            before, after = normalize(
                raw_path, reference_path, output_path, verbose=False
            )
            total_before += before
            if after >= before:
                output_path.unlink()
                total_after += before
                print(f"[{index}/{len(assets)}] {relative_path}: unchanged")
            else:
                total_after += after
                reduction = (before - after) / before * 100.0
                print(f"[{index}/{len(assets)}] {relative_path}: {reduction:.1f}%")

    total_reduction = (total_before - total_after) / total_before * 100.0
    print(f"optimized {len(assets)} assets")
    print(f"triangles: {total_before} -> {total_after} ({total_reduction:.1f}% reduction)")
    print(f"output: {output_root}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("vengi_bin", type=Path, help="path to vengi-voxconvert")
    parser.add_argument("output_root", type=Path, help="staging directory to create")
    arguments = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    vengi_bin = arguments.vengi_bin.expanduser().resolve()
    output_root = arguments.output_root.expanduser().resolve()
    if not vengi_bin.is_file():
        parser.error(f"Vengi executable not found: {vengi_bin}")
    if output_root == project_root or project_root in output_root.parents:
        parser.error("output_root must be outside the project")

    assets = matching_assets(project_root)
    if not assets:
        parser.error("no VOX assets with matching OBJ references found")
    optimize(vengi_bin, project_root, output_root, assets)


if __name__ == "__main__":
    main()
