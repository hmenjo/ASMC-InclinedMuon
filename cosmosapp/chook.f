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
#include "Zstackv.h"

      type(coord):: angle
      type(track):: incident
      integer:: pdgcode
      integer:: nevent, ntevent
      integer:: icode, isub, ichg
      integer:: istk
      real(8):: etot, ekin, px, py, pz

!     Primary has not yet come from a hadron interaction.
!     chookNEPInt reads this as generation 0 and parent PID 0.
      do istk = 1, Stack_pos
         Stack(istk)%user = 0.d0
      enddo

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
             
!     Selection of muons(3), pions(4) and kaons(5).
!     aTrack%user is packed by chookNEPInt:
!       pid*1d10 + gen*1d8 + nint(Xlab*1000)*1d4 + nint(Pt*10)
!     pid: Cosmos code of the decay parent (0 if born in 'coll')
!     gen: hadron-collision generation that produced that parent
!     Xlab = E_parent/E_projectile. Pt is in GeV/c.
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
      use modSetIntInf
      implicit none

#include  "Ztrack.h"
#include  "Ztrackp.h"
#include  "Ztrackv.h"
#include  "Zpwork.h"

      integer:: never
      integer:: i
      integer:: pid, gen, ixlab, ipt, code
      real*8:: eproj, xlab, pt, pt2, ppar, p2, pabs
      real*8:: ux, uy, uz
      character*8:: proc
      type(track):: aTrack

!     Called before Cosmos stacks Pwork.  never must stay 0 so that
!     this hook runs at every non-e-g interaction in the event.
!     Track%user (12 decimal digits, exact in real*8):
!       PP GG XXXX YYYY
!       = pid*1d10 + gen*1d8 + ixlab*1d4 + ipt
!     PP    parent Cosmos code. 0 if this particle was born in 'coll'.
!           pion=4, kaon=5. Written only on 'decay', and only when the
!           decaying particle itself was born in 'coll' (stored pid=0).
!           A later decay (K->pi->mu) does not replace K with pi.
!     GG    hadron-collision generation that created that parent.
!           Primary is 0. First 'coll' is 1. 'decay' is not counted.
!     XXXX  Xlab=E_parent/E_projectile at that collision, as 0.XXX
!           (nint(Xlab*1000), so 0250 means 0.250; saturates at 9.999).
!     YYYY  Pt of the parent perpendicular to the projectile momentum,
!           in GeV/c as XXX.X (nint(Pt*10); saturates at 999.9).
!     Example: 40102500015 = pid 4, gen 1, Xlab 0.250, Pt 1.5 GeV/c.
!
!     On 'coll' the products are stacked here and Nproduced is cleared
!     so Cosmos does not stack them again. Each product gets its own
!     Xlab and Pt. ThinSampling is not applied to those products.
      proc = IntInfArray(ProcessNo)%process

      if(proc .eq. 'coll') then
         call chookUnpackUser(MovedTrack%user, pid, gen, ixlab, ipt)
         gen = gen + 1
         if(gen .gt. 99) gen = 99
         eproj = MovedTrack%p%fm%p(4)
         p2 = MovedTrack%p%fm%p(1)**2 + MovedTrack%p%fm%p(2)**2
     *      + MovedTrack%p%fm%p(3)**2
         pabs = sqrt(p2)
         if(pabs .gt. 0.d0) then
            ux = MovedTrack%p%fm%p(1)/pabs
            uy = MovedTrack%p%fm%p(2)/pabs
            uz = MovedTrack%p%fm%p(3)/pabs
         else
            ux = MovedTrack%vec%w%r(1)
            uy = MovedTrack%vec%w%r(2)
            uz = MovedTrack%vec%w%r(3)
         endif
         do i = 1, Nproduced
            aTrack = MovedTrack
            aTrack%p = Pwork(i)
            if(eproj .gt. 0.d0) then
               xlab = aTrack%p%fm%p(4)/eproj
            else
               xlab = 0.d0
            endif
            ixlab = nint(xlab*1000.d0)
            if(ixlab .lt. 0) ixlab = 0
            if(ixlab .gt. 9999) ixlab = 9999
            ppar = aTrack%p%fm%p(1)*ux + aTrack%p%fm%p(2)*uy
     *           + aTrack%p%fm%p(3)*uz
            p2 = aTrack%p%fm%p(1)**2 + aTrack%p%fm%p(2)**2
     *         + aTrack%p%fm%p(3)**2
            pt2 = p2 - ppar*ppar
            if(pt2 .lt. 0.d0) pt2 = 0.d0
            pt = sqrt(pt2)
            ipt = nint(pt*10.d0)
            if(ipt .lt. 0) ipt = 0
            if(ipt .gt. 9999) ipt = 9999
            call chookPackUser(0, gen, ixlab, ipt, aTrack%user)
            call cresetDirec(aTrack)
            call csaveParent(aTrack)
            call cpush(aTrack)
         enddo
         Nproduced = 0
         never = 0
      elseif(proc .eq. 'decay') then
         call chookUnpackUser(MovedTrack%user, pid, gen, ixlab, ipt)
         if(pid .eq. 0) then
            code = MovedTrack%p%code
            if(code .lt. 0) code = 0
            if(code .gt. 99) code = 99
            call chookPackUser(code, gen, ixlab, ipt,
     *         MovedTrack%user)
         endif
         never = 0
      else
         never = 0
      endif

      end

!     Pack parent-interaction fields into Track%user.
      subroutine chookPackUser(pid, gen, ixlab, ipt, user)
      implicit none
      integer pid, gen, ixlab, ipt
      real*8 user
      user = dble(pid)*1.0d10 + dble(gen)*1.0d8
     *     + dble(ixlab)*1.0d4 + dble(ipt)
      end

!     Inverse of chookPackUser. The 12-digit integer is exact in real*8.
      subroutine chookUnpackUser(user, pid, gen, ixlab, ipt)
      implicit none
      real*8 user
      integer pid, gen, ixlab, ipt
      real*8 u, r
      u = anint(user)
      if(u .lt. 0.d0) u = 0.d0
      r = mod(u, 1.0d4)
      ipt = nint(r)
      u = anint((u - r)/1.0d4)
      r = mod(u, 1.0d4)
      ixlab = nint(r)
      u = anint((u - r)/1.0d4)
      r = mod(u, 1.0d2)
      gen = nint(r)
      u = anint((u - r)/1.0d2)
      pid = nint(u)
      if(pid .lt. 0) pid = 0
      if(pid .gt. 99) pid = 99
      end

      
      

