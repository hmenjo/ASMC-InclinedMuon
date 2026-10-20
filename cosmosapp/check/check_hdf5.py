import h5py

filename = "run0001.h5"

with h5py.File(filename, "r") as f:
    table = f["event_00000001"]
    print(table.attrs["pdg"], table.attrs["energy_gev"])
    print(table["where"][:], table["ke_gev"][:])