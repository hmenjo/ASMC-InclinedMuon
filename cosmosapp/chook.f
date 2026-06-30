!  #define  ONLYELEC
#include "cmain.f"
!#include "chookHybAS.f"

!!! #include "ctemplCeren.f" not needed now
!     If you would supply your own cmyEfield.f and/or cmyBfield.f
!     put your cmyEfield.f in this folder; to do so,
!     probably it's better to copy cmyEfield.f in $COSMOSTOP/cosmos/
!     here and modify it.  The file here will override the one
!     in $COSMOSTOP/cosmos/        
!!! #include "cmyEfield.f" not needed now
!!! #include "cmyBfield.f" not needed now
      
!  *************************************** hook for Beginning of a Run
!  * At this moment, all (system-level) initialization for this run
!  * has been ended.  After this routine is executed, the system goes into the
!  * event creation loop.
!     *

      subroutine chookBgRun
      implicit none
#include "Zmanagerp.h"
#include "Ztrack.h"
#include "Ztrackv.h"
#include "Zobs.h"
#include "Zobsp.h"
#include "Zobsv.h"

      real(8):: oldv
      integer:: icon
      
!            namelist output
      call cwriteParam(ErrorOut, 0)
!            primary information
      call cprintPrim(ErrorOut)
!            observation level information
      write(0,*) '==============================================='
      write(0,*) '>>> Observation Level Information'
      write(0,*) '==============================================='
      call cprintObs(ErrorOut)
      write(0,*) '==============================================='
      call epResetEcrit(0, "Air", 81.0d-3, oldv, icon)
      write(0,*) 'icon=',icon,'Default Ecrit oldv(MeV)=', oldv*1000,
     * ' has been reset to ', 81, ' MeV'

      end

!     *********************************** hook for Beginning of  1 event
!     *  All system-level initialization for 1 event generation has been
!     *  eneded at this moment.
!     *  After this is executed, event generation starts.
!     *
      subroutine chookBgEvent
#include "Ztrack.h"
#include "Zcode.h"

      type(coord):: angle
      type(track):: incident
      integer:: pdgcode 

      call cqIncident(incident, angle)
!      call ccos2pdg(incident%p, pdgcode)


!      write(0,*) '1ry c,subc,chg, TE   cos-zenith '
      write(*,'(A, I3, I3, I3, F12.1, F8.3)') "PRIM ",
     *   incident%p%code, incident%p%subcode, incident%p%charge,
     *   incident%p%fm%p(4), incident%vec%coszenith

!      npart = 0  ! npart(i,j) = 0 (i = 1,..., j = 1,...)
      
      write(*,'(A)') 'BEGIN_EVENT'
      end
  

!     ************************************ hook for observation
!     *  One particle information is brought here by the system.
!     *  All information of the particle is in aTrack
!     *
      subroutine chookObs(aTrack, id)
      use modCodeConv   
!   
!     Note that every real variable is in double  precision so
!     that you may output it in sigle precision to save the memory.
!     In some cases it is essential to put it in sigle (say,
!     for gnuplot).
! 
      implicit none
#include "Ztrack.h"
#include "Zcode.h"
#include "Zglobalc.h"
#include "Zobs.h"
#include "Zobsv.h"

      integer id  ! input.  1 ==> aTrack is going out from
!                                 outer boundery.
!                           2 ==> reached at an observation level
!                           3 ==> reached at inner boundery.
      type(track):: aTrack

      integer::i
      integer:: pdgcode  ! ptcl code by PDG M.C 
      real*4 t

!     For id=2, you need not output the z values, z's are basically the same;
!     it is "distance from the  baseL layer - 1cm" so if the observation layer
!     is the baseL,  the value is about -1cm. 

      if (id .eq. 2) then
             call ccos2pdg(aTrack%p, pdgcode)
!      if ( (pdgcode.eq.13).or. (pdgcode.eq.-13) ) then
             t = aTrack%t + ObsSites(aTrack%where)%minitime/c *Tonsec

             write(*, '(3i3, i12, 1p, 8g15.4, g17.9)')
     *            aTrack%where,  
     *            aTrack%p%code, 
     *            aTrack%p%charge, 
     *            pdgcode,
     *            aTrack%p%fm%p(4)-aTrack%p%mass, 
     *            aTrack%pos%xyz%r(1), aTrack%pos%xyz%r(2), 
     *            aTrack%pos%xyz%r(3),
     *            aTrack%p%fm%p(1), aTrack%p%fm%p(2), 
     *            aTrack%p%fm%p(3),
     *            aTrack%t, t
!      endif  
      endif

      end


!    *********************************** hook for end of 1 event
!    * At this moment, 1 event generation has been ended.
!    *
      subroutine chookEnEvent
      
      write(*,'(A)') 'END_EVENT'
      end


!     ********************************* hook for end of a run
!     *  all events have been created or time lacks
!     *
      subroutine chookEnRun
      end

      
!     ********************************* hook for trace
!     *  This is called only when trace > 60
!     *  User should manage the trace information here.
!     *  If you use this, you may need some output for trace
!     *  at the beginning of 1 event generatio and at the end of  1 event
!     *  generation so that you can identfy each event.
!     *
!     *
      subroutine chookTrace
      end

      
!     ********************* this is the hook called when
!       an electron made an interaction.
!     
      subroutine chookEInt(never)
      integer never
      end

      
!     ********************* this is the hook called when
!       a gamma ray made an interaction.
!     
      subroutine chookGInt(never)
      integer never
      end

      
!     ********************* this is the hook called when
!       non e-g particle made an interaction.
!     

      subroutine chookNEPInt(never)
      integer never
      end

      
      

