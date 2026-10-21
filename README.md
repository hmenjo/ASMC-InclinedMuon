# ASMC-InclinedMuon
Example for inclined muon bundle studies 


# Install CosmosX library

Download the latest version of cosmosX source code from http://cosmos.icrr.u-tokyo.ac.jp/COSMOSweb/index.html.
Before compiling the library, please replace the file Ztrack.h as 
```
cp  ./cosmosx_mod/Ztrack.h (COSMOS-INSTALL DIRECTORY)/Cosmos/cosmos/
```
This is needed to store many information of interactions in the track stracture. 

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
               write(*,'(i10,4i4,i12,e18.8,3f14.4,5e17.8,
     *            i6,2i12,i6,10e15.6,
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
     *            aTrack%t, t,
     *            igen, mpdg, ppdg, mult,
     *            aTrack%user, aTrack%user2, aTrack%user3,
     *            aTrack%user4, aTrack%user5, aTrack%user6,
     *            aTrack%user7, aTrack%user8,
     *            aTrack%user9, aTrack%user10,
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
- igen, mpdg, ppdg, mult, and the ten reals that follow: the interaction record. `mpdg` and `ppdg` are the mother and projectile PDG codes stored in `integer*4`. See [Interaction record](#interaction-record).
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

- File attributes: `latitude_deg`, `longitude_deg`, `dt_gmt_hours`, `year_geomag`, `format` (`asmc-inclined-muon-v2`)
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
- `igen`, `mother_pdg`, `proj_pdg`, `mult`: interaction integers. See [Interaction record](#interaction-record).
- `mother_px`, `mother_py`, `mother_pz`: mother momentum at production [GeV/c]
- `proj_px`, `proj_py`, `proj_pz`: projectile momentum [GeV/c]
- `xlab`: `E_mother / E_projectile`
- `pt`: mother transverse momentum [GeV/c]
- `coll_height_m`: height of that hadron collision [m]
- `decay_height_m`: height where the mother decayed [m]; 0 if it did not decay

## Interaction record

The record describes the mother of the observed particle and the hadron collision that produced that mother. The analysis target is the muon. Pions and kaons that reach an observation level carry the same record. Values are kept on `type track` and copied with the particle; they are not packed into one number.

`user_i1` through `user_i5` are `integer*4`. The mother PDG and the projectile PDG are stored directly in `user_i2` and `user_i3`. A nuclear code such as iron (`1000260560`) fits, so there is no clipped copy and `user11` / `user12` are not used.

| Track field | Output | Meaning |
|---|---|---|
| `user_i1` | `igen` | Hadron-collision generation that created the mother. The primary is 0. Its first `coll` is 1. Only `coll` is counted; `decay` is not. |
| `user_i2` | `mother_pdg` | PDG code of the mother. 0 if this particle was produced directly in `coll`. |
| `user_i3` | `proj_pdg` | PDG code of the projectile of that collision. |
| `user_i4` | `mult` | Number of particles produced in that collision. |
| `user`, `user2`, `user3` | `mother_px/py/pz` | Mother momentum at production [GeV/c], not at decay. For a direct `coll` product the mother is that product itself, so this is its own momentum. |
| `user4`, `user5`, `user6` | `proj_px/py/pz` | Projectile momentum at that collision [GeV/c]. |
| `user7` | `xlab` | `E_mother / E_projectile` using total energy `p(4)`. |
| `user8` | `pt` | Mother momentum perpendicular to the projectile momentum [GeV/c]. |
| `user9` | `coll_height_m` | Height of that collision [m]. |
| `user10` | `decay_height_m` | Height where the mother decayed [m]. 0 if there was no decay. |
| `user11`, `user12`, `user_i5` | | Unused. |

How the mother is chosen:

- On `coll`, each product gets mother PDG 0, generation = projectile generation + 1, and that product's own momentum, Xlab and Pt. Projectile PDG, projectile momentum, multiplicity and collision height are taken from this collision.
- On `decay`, the decaying particle becomes the mother only when the stored mother PDG is still 0. Generation, momenta, Xlab, Pt, projectile, multiplicity and collision height are left unchanged. `decay_height_m` is set to the decay height.
- `K → π → μ` keeps K as the mother. The kaon decay writes the kaon PDG and the kaon decay height. The later pion decay does not replace them. Xlab and Pt stay those of the collision that produced the kaon.
- A muon produced directly in `coll` keeps mother PDG 0 and decay height 0.
- The primary starts at zero. Knock-on, pair production, bremsstrahlung and muon nuclear interaction do not rewrite this record; the products inherit it.

Reading one event table:

```python
import h5py
with h5py.File("cosmos.h5", "r") as f:
    table = f["event_00000001"]
    print(table.attrs["pdg"], table.attrs["energy_gev"])
    print(table["mother_pdg"][:], table["proj_pdg"][:], table["igen"][:])
```

# Note 
- For neutrino primary (no neutrino interaction is implemented in COSMOS), specify it as "neu_e" in the primary file. This neutrino inident may help you to debug and check this application.





