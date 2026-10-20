# ASMC-InclinedMuon
Example for inclined muon bundle studies 

# Compile cosmosapp 

```
cd (COSMOS-INSTALL DIRECTORY)
./Scrpt/CompileExampleByCMake.sh (Your repository path)/ASMC-InclinedMuon/cosmosapp/
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

```
            write(*,'(i10,4i4,i12,e18.8,3g12.4,5e16.8,
     *            i12,4e16.8,g16.8,3g16.8)')
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
     *            pdgcodein, 
     *            incident%p%fm%p(4)-incident%p%mass, 
     *            incident%p%fm%p(1),
     *            incident%p%fm%p(2), incident%p%fm%p(3),
     *            incident%vec%coszenith,
     *            angle%r(1),angle%r(2),angle%r(3)
```

- nevent : event ID 
- aTrack%where : ID of observation layer (starting from 1)
- aTrack%p%code : Detected particl-type ID (COSMOSX)
- aTrack%p%charge : Charge of detected particle
- pdgcode : PDG code of detected partcle 
- aTrack%p%fm%p(4)-aTrack%p%mass : Kinetic Energy [GeV]
- aTrack%pos%xyz%r(1) : x position [m] (Local coordinate of the observation layer)
- aTrack%pos%xyz%r(2) : y position [m] (Local coordinate of the observation layer)
- aTrack%pos%xyz%r(3) : z position [m] (Local coordinate of the observation layer)
- aTrack%p%fm%p(1) : px [GeV/c] (Local coordinate of the observation layer)
- aTrack%p%fm%p(2) : py [GeV/c] (Local coordinate of the observation layer)
- aTrack%p%fm%p(3) : pz [GeV/c] (Local coordinate of the observation layer)
- aTrack%t : arrival time of particle [ns] (offset of observation layer is considered)
- t : arrival time [ns] of absolute time from the incident.
- pdgcodein : pdg code of incident particle
- incident%p%fm%p(4)-incident%p%mass : Kinetic energy of incident particle [GeV]
- incident%p%fm%p(1) : px of incident particle in Earth coordinate [GeV/c]
- incident%p%fm%p(2) : py in Earth coordinate [GeV/c]
- incident%p%fm%p(3) : pz in Earth coordinate [GeV/c]
- incident%vec%coszenith : cos(Zenith angle) in the coordinate of the observation layer
- angle*r(1) : x component of unit direction vertor in the primary plan (= deepest observation layer coordinate)
- angle*r(2) : y component of unit direction vertor in the primary plan (= deepest observation layer coordinate)
- angle*r(3) : z component of unit direction vertor (=cos(zenith angle)) in the primary plan (= deepest observation layer coordinate)

# Note 
- For neutrino primary (no neutrino interaction is implemented in COSMOS), specify it as "neu_e" in the primary file. This neutrino inident may help you to debug and check this application.





