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
It is needed to be done only once in the terminal. These variables can be set manually as 
```
LIBLOFT=/Users/menjo/Workspace/MCshower/CosmosX_0.09/LibLoft
COSMOSTOP=/Users/menjo/Workspace/MCshower/CosmosX_0.09/Cosmos
```

## Execute 
```
cd (Your repository path)/ASMC-InclinedMuon/cosmosapp/
./cosmosLinuxGfort < param > out.txt
```


# Cosmos App output 

```
            write(*,'(i10,4i4,i12,e16.8,3g10.4,5e16.8,
     *            i12,4e16.8,e16.8)')
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
     *            incident%vec%coszenith
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
- incident%p%fm%p(1) : px in Earth coordinate [GeV/c]
- incident%p%fm%p(2) : py in Earth coordinate [GeV/c]
- incident%p%fm%p(3) : pz in Earth coordinate [GeV/c]
- incident%vec%coszenith : cos(Zenith angle)


