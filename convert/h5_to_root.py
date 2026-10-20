#!/usr/bin/env python3
"""Convert an ASMC-InclinedMuon HDF5 file into a ROOT TTree.

One TTree named ``tree`` holds every selected particle. Shower quantities
stored as attributes of ``/event_NNNNNNNN`` are copied onto each row of
that event, which is how the reference tree is filled.

Branch correspondence (ROOT leaf / HDF5 source):

    ShowerCounter/I     event attribute ``event``
    ObsLayer/D          column ``where``
    CosmosPID/I         column ``code``
    CosmosPID_flag/I    column ``subcode``
    PCharge/I           column ``charge``
    ParticleID/I        column ``pdg``
    KinE/D              column ``ke_gev``
    X/D Y/D Z/D         columns ``x_m`` ``y_m`` ``z_m``
    Px/D Py/D Pz/D      columns ``px_gev`` ``py_gev`` ``pz_gev``
    Time/D              column ``t``           (aTrack%t)
    ShowerTime/D        column ``t_ns``
    ShowerPID/I         attribute ``pdg``
    ShowerE/D           attribute ``energy_gev``
    ShowerPx/D          attribute ``px_gev``
    ShowerPy/D          attribute ``py_gev``
    ShowerPz/D          attribute ``pz_gev``
    ShowerCosZenith/D   attribute ``coszenith``
    Angle1/D            attribute ``dir_x``
    Angle2/D            attribute ``dir_y``
    Angle3/D            attribute ``dir_z``

The HDF5 ``user`` column is not a branch of this tree. Events with no
selected particles are omitted.

Requires numpy, h5py and uproot.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import h5py
import numpy as np
import uproot

I32 = np.dtype("<i4")
F64 = np.dtype("<f8")

# Insertion order is the branch order of the TTree.
BRANCHES: dict[str, np.dtype] = {
    "ShowerCounter": I32,
    "ObsLayer": F64,
    "CosmosPID": I32,
    "CosmosPID_flag": I32,
    "PCharge": I32,
    "ParticleID": I32,
    "KinE": F64,
    "X": F64,
    "Y": F64,
    "Z": F64,
    "Px": F64,
    "Py": F64,
    "Pz": F64,
    "Time": F64,
    "ShowerTime": F64,
    "ShowerPID": I32,
    "ShowerE": F64,
    "ShowerPx": F64,
    "ShowerPy": F64,
    "ShowerPz": F64,
    "ShowerCosZenith": F64,
    "Angle1": F64,
    "Angle2": F64,
    "Angle3": F64,
}

# ROOT branch -> HDF5 column. Shower-level branches are filled from attributes.
COLUMNS = {
    "ObsLayer": "where",
    "CosmosPID": "code",
    "CosmosPID_flag": "subcode",
    "PCharge": "charge",
    "ParticleID": "pdg",
    "KinE": "ke_gev",
    "X": "x_m",
    "Y": "y_m",
    "Z": "z_m",
    "Px": "px_gev",
    "Py": "py_gev",
    "Pz": "pz_gev",
    "Time": "t",
    "ShowerTime": "t_ns",
}

# ROOT branch -> HDF5 attribute of /event_NNNNNNNN.
ATTRIBUTES = {
    "ShowerCounter": "event",
    "ShowerPID": "pdg",
    "ShowerE": "energy_gev",
    "ShowerPx": "px_gev",
    "ShowerPy": "py_gev",
    "ShowerPz": "pz_gev",
    "ShowerCosZenith": "coszenith",
    "Angle1": "dir_x",
    "Angle2": "dir_y",
    "Angle3": "dir_z",
}


def scalar(attrs: h5py.AttributeManager, name: str, dataset: str):
    if name not in attrs:
        raise KeyError(f"{dataset} has no attribute {name!r}")
    value = np.asarray(attrs[name]).reshape(-1)
    if value.size != 1:
        raise ValueError(f"{dataset} attribute {name!r} is not a scalar")
    return value[0]


def event_names(h5: h5py.File) -> list[str]:
    names = []
    for name in h5.keys():
        if not name.startswith("event_"):
            continue
        obj = h5[name]
        if isinstance(obj, h5py.Dataset) and obj.dtype.names:
            names.append(name)
    names.sort()
    return names


def rows_for_event(table: h5py.Dataset) -> dict[str, np.ndarray]:
    n = int(table.shape[0])
    name = table.name
    fields = set(table.dtype.names or ())
    missing = [col for col in COLUMNS.values() if col not in fields]
    if missing:
        raise KeyError(f"{name} is missing columns: {', '.join(missing)}")

    out: dict[str, np.ndarray] = {}
    for branch, column in COLUMNS.items():
        out[branch] = np.asarray(table[column][:], dtype=BRANCHES[branch])
    for branch, attr in ATTRIBUTES.items():
        out[branch] = np.full(n, scalar(table.attrs, attr, name), dtype=BRANCHES[branch])
    return out


def convert(h5_path: Path, root_path: Path, tree_name: str = "tree") -> tuple[int, int]:
    """Write ``root_path``. Returns (n_events_with_rows, n_entries)."""
    n_events = 0
    n_entries = 0
    root_path.parent.mkdir(parents=True, exist_ok=True)
    with h5py.File(h5_path, "r") as h5, uproot.recreate(root_path) as root:
        tree = root.mktree(tree_name, BRANCHES, title=tree_name)
        for name in event_names(h5):
            table = h5[name]
            if table.shape[0] == 0:
                continue
            chunk = rows_for_event(table)
            tree.extend(chunk)
            n_events += 1
            n_entries += int(table.shape[0])
    return n_events, n_entries


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path, help="HDF5 file written by cosmos (cosmos.h5, runNNNNNNN.h5)")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="ROOT file to write (default: input path with .root)",
    )
    parser.add_argument("--tree", default="tree", help="TTree name (default: tree)")
    args = parser.parse_args()
    output = args.output if args.output is not None else args.input.with_suffix(".root")
    n_events, n_entries = convert(args.input, output, args.tree)
    print(f"{output}: {n_entries} entries from {n_events} events in TTree {args.tree!r}")


if __name__ == "__main__":
    main()
