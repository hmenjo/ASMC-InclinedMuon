include $(COSMOSTOP)/site.config

# Homebrew/pkg-config HDF5. Override HDF5_PREFIX if it lives elsewhere.
HDF5_PREFIX ?= $(shell pkg-config --variable=prefix hdf5_hl_fortran 2>/dev/null)
ifeq ($(HDF5_PREFIX),)
HDF5_PREFIX = /opt/homebrew/opt/hdf5
endif
HDF5_INC = -I$(HDF5_PREFIX)/include
HDF5_LIB = -L$(HDF5_PREFIX)/lib -lhdf5_hl_fortran -lhdf5_fortran -lhdf5_hl -lhdf5

objs = chook_hdf5.o chook.o

cosmos$(ARCH): $(objs)
	$(LD)  -o $@ $(objs) -L$(DEST) -l$(LIBNAME)  $(LDFLAGS)  -L$(LIBLOFT)/lib/$(ARCH) -lloft $(HDF5_LIB)

chook_hdf5.o: chook_hdf5.f90
	$(FC) $(FFLAGS) -c $(HDF5_INC) chook_hdf5.f90

chook.o: chook_hdf5.o \
	$(LIBLOFTINC)/Zmanagerp.h \
	$(COSMOSINC)/Ztrack.h \
	$(LIBLOFTINC)/Zptcl.h \
	$(LIBLOFTINC)/Zcoord.h \
	$(LIBLOFTINC)/Zpos.h \
	$(LIBLOFTINC)/Zdirec.h \
	$(LIBLOFTINC)/Zmagfield.h \
	$(LIBLOFTINC)/Zobs.h \
	$(LIBLOFTINC)/Zobsp.h \
	$(LIBLOFTINC)/Zobsv.h \
	$(COSMOSINC)/Ztrackv.h \
	$(LIBLOFTINC)/Ztrackp.h
