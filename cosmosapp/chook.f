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

!     textout: reproduce the original per-particle stdout.
!     Set COSMOS_STDOUT=1 (or T/Y) before the run.
      module chook_debug
      implicit none
      logical:: textout = .false.
      end module chook_debug
      
!  *************************************** hook for Beginning of a Run
!  * At this moment, all (system-level) initialization for this run
!  * has been ended.  After this routine is executed, the system goes into the
!  * event creation loop.
!     *

      subroutine chookBgRun
      use chook_hdf5
      use chook_debug
      implicit none
#include "Zmanagerp.h"
#include "Ztrack.h"
#include "Ztrackv.h"
#include "Zobs.h"
#include "Zobsp.h"
#include "Zobsv.h"

      real(8):: oldv
      integer:: icon
      integer:: i
      integer:: stdoutstat
      character(len=8):: stdoutflag
      
!            namelist output
      call cwriteParam(ErrorOut, 0)
!            primary information
      call cprintPrim(ErrorOut)
!            observation level information
      write(0,*) '#==============================================='
      write(0,*) '#>>> Observation Level Information'
      write(0,*) '#==============================================='
      call cprintObs(ErrorOut)
      write(0,*) '#==============================================='
      call epResetEcrit(0, "Air", 81.0d-3, oldv, icon)
      write(0,*) 'icon=',icon,'Default Ecrit oldv(MeV)=', oldv*1000,
     * ' has been reset to ', 81, ' MeV'

      call get_environment_variable('COSMOS_STDOUT',
     *   stdoutflag, status=stdoutstat)
      textout = .false.
      if (stdoutstat .eq. 0) then
         if (stdoutflag(1:1).eq.'1' .or.
     *       stdoutflag(1:1).eq.'T' .or.
     *       stdoutflag(1:1).eq.'t' .or.
     *       stdoutflag(1:1).eq.'Y' .or.
     *       stdoutflag(1:1).eq.'y') textout = .true.
      endif
      if (textout) write(0,*)
     *   'Debug: original particle stdout is enabled'

      call chook_h5_open(LatitOfSite, LongitOfSite, DtGMT,
     *   YearOfGeomag)

      write(*, '(a,g8.3,a,g8.3,a,g8.3,2a,g8.3)') 
     *  '# Latitude=', sngl(LatitOfSite), 
     *  ' deg. Longitude=', sngl(LongitOfSite), 
     *  ' deg. DtGMT=', sngl(DtGMT), ' hours',
     *  ' year for Geomagnetism=', sngl(YearOfGeomag)
      write(*, '(a)') '#-----------------------------'
      write(*, '(a)') '#  Position of Obs. sites '
      write(*, '(a)' ) 
     * '# ID  depth (g/cm2)    Height(m)   Distance to E-center(km)'//
     * ' Molere Unit(m)     x,y,z in XYZ system (m)'
      do i = 1, NoOfSites
         !call cprObsSite(io, ObsSites(i))
         write(*, '(a,i4,1p,6g13.4)')
     *       "# ", i,
     *       ObsSites(i)%pos%depth*0.1, ObsSites(i)%pos%height, 
     *       ObsSites(i)%pos%radiallen/1000., 
     *       ObsSites(i)%pos%xyz%r(1:3)
         call chook_h5_add_site(i,
     *      ObsSites(i)%pos%depth*0.1d0,
     *      ObsSites(i)%pos%height,
     *      ObsSites(i)%pos%radiallen/1000.d0,
     *      ObsSites(i)%pos%xyz%r(1),
     *      ObsSites(i)%pos%xyz%r(2),
     *      ObsSites(i)%pos%xyz%r(3))
      enddo
      end

!     *********************************** hook for Beginning of  1 event
!     *  All system-level initialization for 1 event generation has been
!     *  eneded at this moment.
!     *  After this is executed, event generation starts.
!     *
      subroutine chookBgEvent
      use modCodeConv
      use chook_hdf5
      implicit none
#include "Ztrack.h"
#include "Zcode.h"

      type(coord):: angle
      type(track):: incident
      integer:: pdgcode
      integer:: nevent, ntevent
      integer:: icode, isub, ichg
      real(8):: etot, ekin, px, py, pz

      call cqIncident(incident, angle)
      call ccos2pdg(incident%p, pdgcode)
      call cqEventNo(nevent, ntevent)

      icode = incident%p%code
      isub = incident%p%subcode
      ichg = incident%p%charge
      etot = incident%p%fm%p(4)
      ekin = etot - incident%p%mass
      px = incident%p%fm%p(1)
      py = incident%p%fm%p(2)
      pz = incident%p%fm%p(3)

!      write(0,*) '1ry c,subc,chg, TE   cos-zenith '
      write(*,'(A, I3, I3, I3, F12.1, F8.3, 3F10.5)') 
     *   "#PRIM ",
     *   icode, isub, ichg,
     *   etot, incident%vec%coszenith, 
     *   angle%r(1),angle%r(2),angle%r(3)

      call chook_h5_begin_event(nevent, icode, isub, ichg,
     *   pdgcode, etot, ekin, px, py, pz,
     *   incident%vec%coszenith,
     *   angle%r(1), angle%r(2), angle%r(3))

      write(*,'(A)') '#BEGIN_EVENT'
      end
  

!     ************************************ hook for observation
!     *  One particle information is brought here by the system.
!     *  All information of the particle is in aTrack
!     *
      subroutine chookObs(aTrack, id)
      use modCodeConv
      use chook_hdf5
      use chook_debug
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
      type(coord):: angle
      type(track):: incident

      integer:: pcode    ! particle code of CosmosX
      integer:: pdgcode
      integer:: pdgcodein
      integer:: iwhere, icode, isub, ichg
      integer:: nevent, ntevent
      real(8):: ekin, tns
      real*4 t

!     For id=2, you need not output the z values, z's are basically the same;
!     it is "distance from the  baseL layer - 1cm" so if the observation layer
!     is the baseL,  the value is about -1cm. 

      pcode = aTrack%p%code

      if (id .eq. 2) then
             
!     Selection of muons(3), kaons(4) and pions(5)             
         if ( pcode .eq. 3 .or. pcode .eq. 4 .or. pcode .eq. 5 ) then

            ! CosmosX PID -> PDG code
            call ccos2pdg(aTrack%p, pdgcode)
            tns = aTrack%t
     *         + ObsSites(aTrack%where)%minitime/c*Tonsec
            iwhere = aTrack%where
            icode = aTrack%p%code
            isub = aTrack%p%subcode
            ichg = aTrack%p%charge
            ekin = aTrack%p%fm%p(4) - aTrack%p%mass
            call chook_h5_fill(iwhere, icode, isub, ichg,
     *         pdgcode, ekin,
     *         aTrack%pos%xyz%r(1), aTrack%pos%xyz%r(2),
     *         aTrack%pos%xyz%r(3),
     *         aTrack%p%fm%p(1), aTrack%p%fm%p(2),
     *         aTrack%p%fm%p(3),
     *         aTrack%t, tns, aTrack%user)

            if (textout) then
               call cqEventNo(nevent, ntevent)
               call cqIncident(incident, angle)
               call ccos2pdg(incident%p, pdgcodein)
               t = tns
               write(*,'(i10,4i4,i12,e18.8,3f14.4,6e17.8,
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
            endif
         endif  
      endif

      end


!    *********************************** hook for end of 1 event
!    * At this moment, 1 event generation has been ended.
!    *
      subroutine chookEnEvent
      use chook_hdf5
      call chook_h5_end_event
      write(*,'(A)') '#END_EVENT'
      end


!     ********************************* hook for end of a run
!     *  all events have been created or time lacks
!     *
      subroutine chookEnRun
      use chook_hdf5
      call chook_h5_close
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

      
      

