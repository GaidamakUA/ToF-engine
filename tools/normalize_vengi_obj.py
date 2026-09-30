#!/usr/bin/env python3
"""Make a Vengi binary-mesher OBJ match an existing project OBJ.

Vengi mesh mode 2 produces the desired greedy geometry and palette UVs, but
uses voxel-space coordinates, faces the opposite Y direction from MagicaVoxel,
and emits redundant OBJ data. This tool uses the existing MagicaVoxel OBJ as
the authority for bounds, palette UVs, and material, then writes a compact,
flat-shaded OBJ suitable for Godot.
"""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Face:
    vertices: list[int]
    texcoords: list[int]


@dataclass
class Obj:
    vertices: list[tuple[float, float, float]]
    texcoords: list[tuple[float, float]]
    faces: list[Face]
    material_library: str | None
    materials: set[str]


def obj_index(raw_index: str, item_count: int) -> int:
    index = int(raw_index)
    if index == 0:
        raise ValueError("OBJ indices cannot be zero")
    return index - 1 if index > 0 else item_count + index


def load_obj(path: Path) -> Obj:
    vertices: list[tuple[float, float, float]] = []
    texcoords: list[tuple[float, float]] = []
    faces: list[Face] = []
    material_library: str | None = None
    materials: set[str] = set()

    with path.open(encoding="utf-8", errors="strict") as source:
        for line_number, line in enumerate(source, 1):
            fields = line.split()
            if not fields:
                continue
            if fields[0] == "v":
                vertices.append(tuple(map(float, fields[1:4])))
            elif fields[0] == "vt":
                texcoords.append(tuple(map(float, fields[1:3])))
            elif fields[0] == "mtllib":
                material_library = " ".join(fields[1:])
            elif fields[0] == "usemtl":
                materials.add(" ".join(fields[1:]))
            elif fields[0] == "f":
                if len(fields) != 4:
                    raise ValueError(f"{path}:{line_number}: expected triangles")
                vertex_indices: list[int] = []
                texcoord_indices: list[int] = []
                for field in fields[1:]:
                    indices = field.split("/")
                    if len(indices) < 2 or not indices[1]:
                        raise ValueError(
                            f"{path}:{line_number}: face has no texture coordinate"
                        )
                    vertex_indices.append(obj_index(indices[0], len(vertices)))
                    texcoord_indices.append(obj_index(indices[1], len(texcoords)))
                faces.append(Face(vertex_indices, texcoord_indices))

    if not vertices or not faces:
        raise ValueError(f"{path}: OBJ has no mesh")
    return Obj(vertices, texcoords, faces, material_library, materials)


def bounds(
    vertices: list[tuple[float, float, float]],
) -> tuple[tuple[float, float, float], tuple[float, float, float]]:
    minimum = tuple(min(vertex[axis] for vertex in vertices) for axis in range(3))
    maximum = tuple(max(vertex[axis] for vertex in vertices) for axis in range(3))
    return minimum, maximum


def unique(items: list[tuple[float, ...]]) -> list[tuple[float, ...]]:
    return list(dict.fromkeys(items))


def calculate_transform(
    source_vertices: list[tuple[float, float, float]],
    reference_vertices: list[tuple[float, float, float]],
) -> tuple[float, tuple[int, int, int], tuple[float, float, float]]:
    source_min, source_max = bounds(source_vertices)
    reference_min, reference_max = bounds(reference_vertices)
    scales = []
    for axis in range(3):
        source_size = source_max[axis] - source_min[axis]
        reference_size = reference_max[axis] - reference_min[axis]
        if source_size > 1e-9:
            scales.append(reference_size / source_size)

    if not scales:
        raise ValueError("cannot calculate scale from a zero-sized mesh")
    scale = sum(scales) / len(scales)
    if any(not math.isclose(value, scale, rel_tol=1e-5, abs_tol=1e-8) for value in scales):
        raise ValueError(f"source and reference bounds require non-uniform scaling: {scales}")

    axis_directions = (-1, 1, -1)  # Vengi -> MagicaVoxel: rotate 180 degrees around Y.
    transformed_min = tuple(
        (source_min[axis] if axis_directions[axis] > 0 else -source_max[axis]) * scale
        for axis in range(3)
    )
    offset = tuple(reference_min[axis] - transformed_min[axis] for axis in range(3))
    return scale, axis_directions, offset


def transformed_vertices(
    vertices: list[tuple[float, float, float]],
    scale: float,
    axis_directions: tuple[int, int, int],
    offset: tuple[float, float, float],
) -> tuple[list[tuple[float, float, float]], list[int]]:
    compact_vertices: list[tuple[float, float, float]] = []
    compact_indices: dict[tuple[float, float, float], int] = {}
    remap: list[int] = []

    for vertex in vertices:
        transformed = tuple(
            vertex[axis] * scale * axis_directions[axis] + offset[axis]
            for axis in range(3)
        )
        key = tuple(round(value, 9) for value in transformed)
        if key not in compact_indices:
            compact_indices[key] = len(compact_vertices)
            compact_vertices.append(transformed)
        remap.append(compact_indices[key])
    return compact_vertices, remap


def palette_uv_map(
    source: Obj, reference: Obj
) -> tuple[list[tuple[float, float]], list[int]]:
    reference_uvs = unique(reference.texcoords)
    if not reference_uvs:
        raise ValueError("reference OBJ has no palette UVs")

    remap: list[int] = []
    for uv in source.texcoords:
        distances = [max(abs(uv[axis] - candidate[axis]) for axis in range(2)) for candidate in reference_uvs]
        closest = min(range(len(distances)), key=distances.__getitem__)
        if distances[closest] > 1e-5:
            raise ValueError(f"Vengi UV {uv} is absent from the reference palette UVs")
        remap.append(closest)
    return reference_uvs, remap


def face_normal(
    vertices: list[tuple[float, float, float]], face: Face, vertex_remap: list[int]
) -> tuple[float, float, float]:
    a, b, c = (vertices[vertex_remap[index]] for index in face.vertices)
    ab = tuple(b[axis] - a[axis] for axis in range(3))
    ac = tuple(c[axis] - a[axis] for axis in range(3))
    cross = (
        ab[1] * ac[2] - ab[2] * ac[1],
        ab[2] * ac[0] - ab[0] * ac[2],
        ab[0] * ac[1] - ab[1] * ac[0],
    )
    length = math.sqrt(sum(value * value for value in cross))
    if length <= 1e-9:
        raise ValueError("Vengi OBJ contains a degenerate triangle")
    normal = tuple(round(value / length, 9) for value in cross)
    if sum(abs(value) > 1e-6 for value in normal) != 1:
        raise ValueError(f"expected an axis-aligned voxel face, got normal {normal}")
    return normal


def format_number(value: float) -> str:
    if abs(value) < 5e-10:
        value = 0.0
    return f"{value:.9g}"


def normalize(
    source_path: Path,
    reference_path: Path,
    output_path: Path,
    *,
    verbose: bool = True,
) -> tuple[int, int]:
    source = load_obj(source_path)
    reference = load_obj(reference_path)
    if reference.material_library is None:
        raise ValueError("reference OBJ has no material library")
    if len(reference.materials) != 1:
        raise ValueError("reference OBJ must use exactly one material")

    scale, axis_directions, offset = calculate_transform(source.vertices, reference.vertices)
    vertices, vertex_remap = transformed_vertices(
        source.vertices, scale, axis_directions, offset
    )
    texcoords, texcoord_remap = palette_uv_map(source, reference)

    normals: list[tuple[float, float, float]] = []
    normal_indices: dict[tuple[float, float, float], int] = {}
    face_normals: list[int] = []
    face_uvs: list[int] = []
    for face in source.faces:
        mapped_uvs = {texcoord_remap[index] for index in face.texcoords}
        if len(mapped_uvs) != 1:
            raise ValueError("Vengi mode 2 face spans multiple palette colors")
        face_uvs.append(mapped_uvs.pop())

        normal = face_normal(vertices, face, vertex_remap)
        if normal not in normal_indices:
            normal_indices[normal] = len(normals)
            normals.append(normal)
        face_normals.append(normal_indices[normal])

    material = next(iter(reference.materials))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="\n") as output:
        output.write("# Vengi binary mesh normalized for Tanks of Freedom II\n\n")
        output.write(f"mtllib {reference.material_library}\n")
        output.write(f"o {output_path.stem}\n\n")
        for vertex in vertices:
            output.write("v " + " ".join(map(format_number, vertex)) + "\n")
        output.write("\n")
        for uv in texcoords:
            output.write("vt " + " ".join(map(format_number, uv)) + "\n")
        output.write("\n")
        for normal in normals:
            output.write("vn " + " ".join(map(format_number, normal)) + "\n")
        output.write(f"\nusemtl {material}\n")
        for face, uv_index, normal_index in zip(source.faces, face_uvs, face_normals):
            corners = [
                f"{vertex_remap[index] + 1}/{uv_index + 1}/{normal_index + 1}"
                for index in face.vertices
            ]
            output.write("f " + " ".join(corners) + "\n")

    if verbose:
        source_min, source_max = bounds(vertices)
        print(f"triangles: {len(source.faces)}")
        print(f"vertices: {len(source.vertices)} -> {len(vertices)}")
        print(f"scale: {format_number(scale)}")
        print("axis directions: " + ", ".join(map(str, axis_directions)))
        print("offset: " + ", ".join(map(format_number, offset)))
        print(f"bounds: {source_min} -> {source_max}")
        print(f"saved: {output_path}")
    return len(reference.faces), len(source.faces)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Vengi mode 2 OBJ")
    parser.add_argument("reference", type=Path, help="existing MagicaVoxel OBJ")
    parser.add_argument("output", type=Path, help="normalized OBJ to create")
    arguments = parser.parse_args()

    if arguments.output.resolve() in {arguments.source.resolve(), arguments.reference.resolve()}:
        parser.error("output must not overwrite the source or reference OBJ")
    normalize(arguments.source, arguments.reference, arguments.output)


if __name__ == "__main__":
    main()
