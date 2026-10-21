# ASMC-InclinedMuon
Example for inclined muon bundle studies 

# Compile cosmosapp 

```
cd (COSMOS-INSTALL DIRECTORY)
./Scrpt/CompileExampleByCMake.sh (Your repository path)/ASMC-InclinedMuon/cosmosapp/
```

In addtion to COSMOS installation, please install HDF5 library. In case of CentOS or AlmaLinux.
```
sudo dnf install epel-release
sudo dnf install hdf5 hdf5-devel
```

# Execute cosmosapp 

## Perparation 
Before the execution, please setup the enviromental variables as 
```
cd (COSMOS-INSTALL DIRECTORY)
source Scrpt/SetEnvironment.sh
```
It is needed to be done only once in the terminal. These variables can be set manually in your batch job script or bashrc as 
```
export LIBLOFT=/Users/menjo/Workspace/MCshower/CosmosX_0.09/LibLoft
export COSMOSTOP=/Users/menjo/Workspace/MCshower/CosmosX_0.09/Cosmos
```

## Execute 
```
cd (Your repository path)/ASMC-InclinedMuon/cosmosapp/
export COSMOS_H5OUT='run01.h5'  # output filename for HDF5 
export COSMOS_STDOUT=1          # 1: w/ std output for debug, 0: w/o
./cosmosLinuxGfort < param > out.txt
```

Roughly 100 events per 2 hours and 1 CPU. 
The paramters for this MC generation are given in the text file "param". Only parameters should be related to this study are listed below. Please refer the COSMOS manual for the other parameters. 

- HeightList : specification of observation layers in hight [m]. You can specify the layers using DepthList [kg/m^3] also. The parameters in DepthList are prioritized over HeightList. To disable DepthList, "-1" must be listed in DepthList.
- InitRN : Rundom seed. If negative number like -1 is specify, the cpu time is automatically used. 
- CosZenith : Range of Zenith angle for event generations. (cos theta)
- Azimuth : Range of Azimuthal angle for event generations [degree]
- HeightOfInj : Injection height of sperified parimary cosmic-rays [m]
- DestEventNo : Number of events for the generation 
- Generate : treatment of EM components 'em'=fully simulate (do tracking), 'as'=use cascade equation (skip tracking)
- IntModel : Hadronic interaction model. multiple modules can be specifyed with giving threshold energy of model-swithing. '"phits" 2.0 "dpmjet3" 80 "qgsjet2"' -> Use Phits E<2GeV, Dpmjet3 2< E <80GeV, Qgsjet2 E>80GeV
- KEminObs : Minimum energy of particles considered for observation. It corresponds to the minimum energy of tracking also. To speed up the calculation, it should be increased. 
- ObsPlane : Type of the coordinate system for outputs of observation 

In addtion, "primary", the file name is specified in "param", specifies the energies (or spectrum) and compositions of the primary cosmic-rays. 

## Improve the simulation speed 

### Apply the threshold energies of particle tracking  
To stop the tracking of particles with lower energies, the following lines should be added into 'param'
```
 KEminObs = 300.0  ! 100 keV
 KEminObs(1) = 100000.0
 KEminObs(2) = 100000.0 
 KEminObs(3) = 300.0
 KEminObs(4) = 300.0
 KEminObs(5) = 300.0
 KEminObs(6) = 300.0
```
The KEminObs parameter works only for EM components. To apply the energy threshold of tracking for hadrons, threshold value for each particle type should be specified. KEminObs(x) : threshold for particle code x, it means that Energy threshold for pions, kaons, nucleons are KEminObs(4), KEminObs(5), KEminObs(6) respectively. 


# Cosmos App output

Two outputs are produced. HDF5 is always written. The original per-particle text is written only when debug stdout is turned on.

```
export COSMOS_H5OUT=run01.h5
export COSMOS_STDOUT=1
./cosmosLinuxGfort < param > out.txt
```

`COSMOS_STDOUT` accepts `1`, `T`, `t`, `Y`, or `y`. Leave it unset for a normal run. `COSMOS_H5OUT` selects the HDF5 path. The default file is `cosmos.h5` in the working directory, and an existing file is replaced at the start of the run.

## Standard output

The redirected text always contains the observation-site list, one `#PRIM` line, `#BEGIN_EVENT`, and `#END_EVENT`. With `COSMOS_STDOUT` set, each selected particle is also written between `#BEGIN_EVENT` and `#END_EVENT`, in the original format:

```
            write(*,'(i10,4i4,i12,e18.8,3f14.4,5e17.8,f18.0,
     *            i12,4e16.8,f15.10,3f15.10)')
     *            nevent,
     *            aTrack%where,
     *            aTrack%p%code,
     *            aTrack%p%subcode,
     *            aTrack%p%charge,
     *            pdgcode,
     *            aTrack%p%fm%p(4)-aTrack%p%mass,
     *            aTrack%pos%xyz%r(1), aTrack%pos%xyz%r(2),
     *            aTrack%pos%xyz%r(3),
     *            aTrack%p%fm%p(1), aTrack%p%fm%p(2),
     *            aTrack%p%fm%p(3),
     *            aTrack%t, t, aTrack%user,
     *            pdgcodein,
     *            incident%p%fm%p(4)-incident%p%mass,
     *            incident%p%fm%p(1),
     *            incident%p%fm%p(2), incident%p%fm%p(3),
     *            incident%vec%coszenith,
     *            angle%r(1),angle%r(2),angle%r(3)
```

- nevent : event ID
- aTrack%where : ID of observation layer (starting from 1)
- aTrack%p%code : Detected particle-type ID (COSMOSX)
- aTrack%p%subcode : subcode of the detected particle
- aTrack%p%charge : Charge of detected particle
- pdgcode : PDG code of detected particle
- aTrack%p%fm%p(4)-aTrack%p%mass : Kinetic Energy [GeV]
- aTrack%pos%xyz%r(1) : x position [m] (Local coordinate of the observation layer)
- aTrack%pos%xyz%r(2) : y position [m] (Local coordinate of the observation layer)
- aTrack%pos%xyz%r(3) : z position [m] (Local coordinate of the observation layer)
- aTrack%p%fm%p(1) : px [GeV/c] (Local coordinate of the observation layer)
- aTrack%p%fm%p(2) : py [GeV/c] (Local coordinate of the observation layer)
- aTrack%p%fm%p(3) : pz [GeV/c] (Local coordinate of the observation layer)
- aTrack%t : arrival time of particle [ns] (offset of observation layer is considered)
- t : arrival time [ns] of absolute time from the incident
- aTrack%user : parent-interaction record packed into one real*8. Printed as an integer (`f18.0`). See [Parent interaction stored in `user`](#parent-interaction-stored-in-user).
- pdgcodein : pdg code of incident particle
- incident%p%fm%p(4)-incident%p%mass : Kinetic energy of incident particle [GeV]
- incident%p%fm%p(1) : px of incident particle in Earth coordinate [GeV/c]
- incident%p%fm%p(2) : py in Earth coordinate [GeV/c]
- incident%p%fm%p(3) : pz in Earth coordinate [GeV/c]
- incident%vec%coszenith : cos(Zenith angle) in the coordinate of the observation layer
- angle%r(1) : x component of unit direction vector in the primary plane (= deepest observation layer coordinate)
- angle%r(2) : y component of unit direction vector in the primary plane (= deepest observation layer coordinate)
- angle%r(3) : z component of unit direction vector (=cos(zenith angle)) in the primary plane (= deepest observation layer coordinate)

`#PRIM` is one line per event:

```
#PRIM   code subcode charge  total_energy  coszenith  dir_x dir_y dir_z
```

## HDF5

HDF5 is written for every run, whether or not `COSMOS_STDOUT` is set.

- File attributes: `latitude_deg`, `longitude_deg`, `dt_gmt_hours`, `year_geomag`
- `/obs_sites`: one row per observation layer (`id`, `depth_g_cm2`, `height_m`, `radial_km`, `x_m`, `y_m`, `z_m`)
- `/event_NNNNNNNN`: one HDF5 table per event. `NNNNNNNN` is the event number.

The incident particle (the former `#PRIM` line, plus PDG code, kinetic energy and momentum) is stored as attributes of `/event_NNNNNNNN`:

- `event`, `code`, `subcode`, `charge`, `pdg`
- `energy_gev`: total energy `p(4)` [GeV]
- `ke_gev`: kinetic energy [GeV]
- `px_gev`, `py_gev`, `pz_gev`: momentum in the Earth coordinate [GeV/c]
- `coszenith`
- `dir_x`, `dir_y`, `dir_z`: unit direction vector in the primary plane
- `nparticles`: number of rows, written when the event finishes

Each selected particle (muons, kaons, pions at an observation level) is one row:

- `where`: observation layer id, starting from 1
- `code`, `subcode`, `charge`: COSMOS particle code
- `pdg`: PDG code
- `ke_gev`: kinetic energy [GeV]
- `x_m`, `y_m`, `z_m`: position [m] in the observation-layer coordinate
- `px_gev`, `py_gev`, `pz_gev`: momentum [GeV/c] in that coordinate
- `t`: `aTrack%t`
- `t_ns`: `aTrack%t + minitime/c*Tonsec`
- `user`: same packed parent-interaction value as `aTrack%user` (full `real*8`, so all 12 digits are exact). See [Parent interaction stored in `user`](#parent-interaction-stored-in-user).

## Parent interaction stored in `user`

`user` describes the hadron that the observed particle came from, and the hadron collision that produced that hadron. The analysis target is the muon. Pions and kaons that reach an observation level carry the same kind of record.

The value is one integer of up to 12 digits, stored in `real*8`:

```text
PP GG XXXX YYYY
user = pid*1e10 + gen*1e8 + nint(Xlab*1000)*1e4 + nint(Pt*10)
```

| Digits | Field | Meaning |
|---|---|---|
| PP | parent PID | Cosmos code of the parent. Pion = 4, kaon = 5. `0` if this particle was produced directly in a hadron collision (`coll`), not by a decay. |
| GG | generation | Which hadron collision produced that parent. The primary's first `coll` is 1. The next `coll` of a secondary is 2, and so on. `decay` is not counted. |
| XXXX | Xlab | `E_parent / E_projectile` at that collision, using total energy `p(4)`. Three digits after the decimal: 0250 means 0.250. Values above 9.999 are stored as 9999. |
| YYYY | Pt | Transverse momentum of the parent with respect to the projectile momentum, in GeV/c, to 0.1 GeV/c. 0015 means 1.5. Values above 999.9 are stored as 9999. |

Example: `40102500015` is parent pion (4), generation 1, Xlab = 0.250, Pt = 1.5 GeV/c.

How the parent is chosen:

- On `coll`, each product is given PID 0, generation = projectile generation + 1, and that product's own Xlab and Pt.
- On `decay`, the Cosmos code of the decaying particle is written as the parent PID only when the stored PID is still 0 (the decaying particle itself came from `coll`). Generation, Xlab and Pt are left as they were.
- `K → π → μ` therefore keeps K as the parent. The kaon decay writes PID 5; the later pion decay does not replace it. Xlab and Pt stay those of the collision that produced the kaon.
- A muon produced directly in `coll` keeps PID 0. Its generation, Xlab and Pt are those of that collision.
- The primary starts at 0. Knock-on, pair production, bremsstrahlung and muon nuclear interaction do not rewrite this record; the products inherit it.

```python
n = int(round(user))
pt = (n % 10000) / 10.0          # GeV/c
xlab = ((n // 10000) % 10000) / 1000.0
gen = (n // 100000000) % 100
pid = n // 10000000000           # 0, 4 (pion), 5 (kaon), ...
```

Reading one event table:

```python
import h5py
with h5py.File("cosmos.h5", "r") as f:
    table = f["event_00000001"]
    print(table.attrs["pdg"], table.attrs["energy_gev"])
    print(table["where"][:], table["ke_gev"][:])
```

# Note 
- For neutrino primary (no neutrino interaction is implemented in COSMOS), specify it as "neu_e" in the primary file. This neutrino inident may help you to debug and check this application.





