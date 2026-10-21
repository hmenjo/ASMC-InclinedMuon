!   #ifndef Ztrack_
!   #define Ztrack_
!    structure used when tracking a particle
!    *************************
#include  "Zcondc.h"
#include  "Zptcl.h"
#include  "Zcoord.h"
#include  "Zpos.h"
#include  "Zdirec.h"
#include  "Zmagfield.h"
!     ---------------------
      type track      ! full particle attributes in Cosmos
        sequence

          type(ptcl):: p    ! basic ptcl attributes.

!               position and time
          type(position):: pos
          real*8 t           ! time in length/beta (m)
          type(direc):: vec
          real*4 wgt         ! weight for thin sampling
          integer*2 where    ! current obsSite no. (0 is initial value)
          integer*2 asflag   ! non 0, if As has been generated from this
!                             ptcl (only for electrons)
!         Interaction record filled by ASMC chookNEPInt.
!         Momenta, Xlab, Pt and coll height are taken at the hadron
!         collision that created the mother.  decay does not recount.
          real*8   user      ! mother px at production [GeV/c]
          real*8   user2     ! mother py [GeV/c]
          real*8   user3     ! mother pz [GeV/c]
          real*8   user4     ! projectile px [GeV/c]
          real*8   user5     ! projectile py [GeV/c]
          real*8   user6     ! projectile pz [GeV/c]
          real*8   user7     ! Xlab = E_mother / E_projectile
          real*8   user8     ! mother Pt vs projectile [GeV/c]
          real*8   user9     ! height of that hadron collision [m]
          real*8   user10    ! height where the mother decayed [m]; 0 if none
          real*8   user11    ! unused
          real*8   user12    ! unused
          integer*4 user_i1  ! hadron-collision generation (first coll = 1)
          integer*4 user_i2  ! mother PDG
          integer*4 user_i3  ! projectile PDG
          integer*4 user_i4  ! multiplicity of that collision
          integer*4 user_i5  ! unused

! particle information at production
          type(ptcl):: inip    ! basic ptcl attributes.
          type(position):: inipos
          real*8 init           ! time in length/beta (m)
          type(direc):: inivec

! parent particle information 
          type(ptcl):: parp    ! basic ptcl attributes.
          type(direc):: parvec

#if LABELING > 0
          integer  label     ! put a label (1,2,...) on each particle.
                             ! There is a global label_counter which
              ! is cleared at the start of 1 event generation.
              ! it is counted up when a particle is poped up from the
              ! stack. The label_counter is given to the label of 
              ! the poped up particle. This may be needed to judge
              ! if the same particle crosses a given observation place
              ! more than once.
           integer  info      ! for each particle,  when a particle is born
              !     this is initialized to 0.  If the ptcl goes higher than
              !     380km, 1 is added. This is for AMS observation.
#endif
      end type track
!   #endif  /* Ztrack.h */


