c***********************************************************************
      subroutine GRrmesh(mxvert,mxnode,mxelem,mxnbd,mxbdp,
     &                   ngmx,ncmx,nvertd,phi,
     &                   nvert,nnode,x,y,
     &                   nelem,inod,nec,area,reft,aspr,
     &                   nbd,ibdnod,nic,ic,nbound,nside,
     &                   leniw,iwork,h1,h2,h3,dG,lrmsh)
c
c-----------------------------------------------------------------------
c     This subroutine use GRUMMP to remesh the domain. local refinement 
c        is performed according the input phi field.
c     Input:
c        
c        mxvert,mxnode,mxelem,mxnbd,ngmx,ncmx:
c                    maximum sizes for arrays and mesh
c        nvertd:     number of vertices in the old mesh
c        phi:        phi field defined on the old mesh
c        nic:        number of boundary sections
c        h2,h3>h1:      mesh size at far field and at interface 
c                       h2 for phi=1, and h3 for phi=-1   
c        dG:         grading control in GRUMMP, >1 , recommend dG=4.d0
c        leniw:      length of the integer working 
c     Output:
c        nvert,nnode,nelem,nbd,nic:
c                    new mesh sizes
c        nbound:     number of close boundaries
c        inod:       element description table
c        nec:        neighbouring elements
c        x,y:        coordinates of nodes
c        ibdnod:     indices of bounary nodes in the global node list
c        ic:         starting position of bd secs in ibdnod
c        nside:      number of sections in each close boundaries
c        area,reft,aspr:
c                    area, reference # and aspect ratio of elements
c        lrmsh:      whether remesh has been performed
c     Working:
c        iwork
c-----------------------------------------------------------------------
c     NOTE: old mesh info is stored in the GRUMMP part
c     Mar 7, 2005, Pengtao Yue
c-----------------------------------------------------------------------
      implicit none
c
      intent (in) :: mxvert,mxnode,mxelem,mxnbd,ngmx,ncmx,nvertd,mxbdp,
     &               leniw,h1,h2,h3,dG,phi
      intent (out):: nvert,nnode,nelem,nbd,nic,inod,nec,x,y,ibdnod,ic,
     &               area,reft,aspr,lrmsh,nbound,nside
      intent (inout):: iwork
c
      integer mxvert,mxnode,mxelem,mxnbd,mxbdp,ngmx,ncmx,
     &        nvertd,nvert,nnode,nelem,nbd,nic,leniw,nbound
      integer inod(ngmx,mxelem),nec(ncmx,mxelem),ic(mxbdp+1),
     &        ibdnod(mxnbd),iwork(leniw),reft(mxelem),nside(mxbdp)
      real(8) h1,h2,h3,dG
      real(8) x(mxnode),y(mxnode),area(mxelem),aspr(mxelem),phi(nvertd)
      logical lrmsh
c     local variables
      integer lrefseg,lbdseg,lngh,lflag,leni,lrmhold,lrmhnew,liwork,
     &        lnodseg,lnxtseg,lmidnod,lnumseg
c
c      ftype=mod(flowtype,100)
c      if(ftype.eq.1.or.ftype.eq.2.or.ftype.eq.11)then
c         nic=4
c      endif
c      nbound=1
c      nside(1)=nic
c
      lrefseg=1
      lbdseg =lrefseg+mxnbd
      lngh   =lbdseg +mxnbd *2
      lflag  =lngh   +mxelem*3
      lrmhold=lflag  +mxvert
      lrmhnew=lrmhold+mxelem
      lnodseg=lrmhnew+mxelem
      lnxtseg=lnodseg+mxvert*2
      lmidnod=lnxtseg+mxnbd
      lnumseg=lmidnod+mxnbd
      liwork =lnumseg+mxnbd
      leni   =liwork +mxelem*3
      if(leni.gt.leniw+1)stop 'iwork too short in GRrmesh!'
c
      call GRrfnmsh(mxnbd,mxvert,mxelem,ngmx,ncmx,nvertd,phi,
     &              nbd,nvert,nelem,iwork(lbdseg),iwork(lrefseg),
     &              inod,nec,reft,x,y,h1,h2,h3,dG,lrmsh)
      if(.not.lrmsh) return
c     debug
c      write(*,*)'lrmsh:',lrmsh
c      if(lrmsh)then
c      write(*,*)'lrmsh=true',lrmsh
c      call mshoutput (nnode,nvert,nelem,ngmx,ncmx,
c     &                inod,nec,x,y,
c     &                nbd,ibdnod,nic,ic, nbound,nside)
c      else
c      write(*,*)'lrmsh=false',lrmsh
c         return
c      endif
c      pause
c

      call mshtrans(mxnbd,mxbdp,mxnode,ngmx,ncmx,
     &              nvert,nnode,x,y,nelem,inod,nec,area,aspr,
     &              nbd,iwork(lrefseg),iwork(lbdseg),ibdnod,
     &               nic,ic,nbound,nside,
     &              iwork(lngh),iwork(lflag),iwork(lrmhold),
     &               iwork(lrmhnew),iwork(lnodseg),iwork(lnxtseg),
     &               iwork(lmidnod),
     &              iwork(lnumseg),iwork(liwork))
      reft(1:nelem)=1
      write(*,'("Remesh invoked!")')
      write(*,'("Vert=",i7,1x,"Node=",i7,1x,"Elem=",i7,1x,"nbd=",i7)')
     &   nvert,nnode,nelem,nbd
      end

      

c***********************************************************************
      subroutine GRinitmsh(flowtype,mxvert,mxnode,mxelem,mxnbd,mxbdp,
     &                     ngmx,ncmx,nvert,nnode,x,y,
     &                     nelem,inod,nec,area,reft,aspr,
     &                     nbd,ibdnod,nic,ic,nbound,nside,
     &                     leniw,lenrw,iwork,rwork,
     &                     rd,xd,yd,dropone,eps,h1,h2,h3,dG)
c
c-----------------------------------------------------------------------
c     This subroutine use GRUMMP to generate the initial mesh
c
c     Input:
c        flowtype:   
c        mxvert:     maximum number of vertices             
c        mxnode:     maximum number of nodes
c        mxelem:     maximum nubmer of elememts
c        mxnbd:      maximum number of boundary nodes
c        mxbdp:      maximum number of boundary sections
c        ngmx:       maximum number of nodes per element
c        ncmx:       maximum number of neighbouring elements per element
c        leniwk,lenrwk:    size of the working arrays
c        rd,xd,yd:   radius and position of drop
c        dropone:    whether phi=1 in drop phase
c        eps:        capillary width
c        h2,h3>h1:      mesh size at far field and at interface 
c                       h2 for phi=1, and h3 for phi=-1   
c        dG:         grading control in GRUMMP, >1 , recommend dG=4.d0
c     Output:
c        nvert, nnode,nelem,nbd,nic: actual parameters of the mesh
c        nbound:     number of close boundaries
c        inod:       element description table
c        nec:        neighboring elements
c        x,y:        coordinates of nodes
c        ibdnod:     indices of bounary nodes in the global node list
c        ic:         starting position of boundary section in ibdnod
c        nside:      number of sections in each close boundaries
c        area:       area of elements
c        reft:       reference number of elements
c        aspr:       aspect ratio of elements
c     working:
c        iwork,rwork
c        lenrw>=nvert
c-----------------------------------------------------------------------
c     Mar 7, 2005, Pengtao Yue
c-----------------------------------------------------------------------
      implicit none
c
      intent (in) :: flowtype,mxvert,mxnode,mxelem,mxnbd,ngmx,ncmx,
     &               mxbdp,leniw,lenrw,h1,h2,h3,dG,rd,xd,yd,dropone
      intent (out):: nvert,nnode,nelem,nbd,nic,inod,nec,x,y,ibdnod,ic,
     &               area,reft,aspr,nbound,nside
      intent (inout):: iwork,rwork
c
      integer flowtype,mxvert,mxnode,mxelem,mxnbd,ngmx,ncmx,nvert,nnode,
     &        nelem,nbd,nic,leniw,lenrw,mxbdp,nbound
      integer inod(ngmx,mxelem),nec(ncmx,mxelem),ic(mxbdp+1),
     &        ibdnod(mxnbd),iwork(leniw),reft(mxelem),nside(mxbdp)
      real(8) rd,xd,yd,h1,h2,h3,dG,eps
      real(8) x(mxnode),y(mxnode),rwork(lenrw),area(mxelem),aspr(mxelem)
      logical dropone
c     local variables
      integer level,n,nvertd,leni,lenr
      integer lrefseg,lbdseg,lngh,lflag,lphi,lrmhold,
     &        lrmhnew,liwork,lnodseg,lnxtseg,lmidnod,lnumseg
      real(8) h,hh2,hh3
      logical lrmsh
      write(*,'("Mesh initializing...")')

c
      if(leni.gt.leniw+1)stop 'iwork too short in GRinitmsh!'
      if(lenr.gt.lenrw+1)stop 'rwork too short in GRinitmsh!'
c
      level=int(log(h2/h1)/log(2.d0))+1
      if(dropone)then
         h=h3
      else
	   h=h2
      endif
      call GRunimsh(mxnbd,mxvert,mxelem,ngmx,ncmx,nbd,nvert,nelem,
     &              iwork(lrefseg),iwork(lbdseg),inod,nec,reft,x,y,h)
c
	hh2=h2
      hh3=h3
      if(dropone)then
         if(h2.le.h3)then
            hh2=max(h3/2.d0,h2)
         else
            hh2=min(h3*2.d0,h2)
         endif
      else
         if(h3.le.h2)then
            hh3=max(h2/2.d0,h3)
         else
            hh3=min(h2*2.d0,h3)
         endif
      endif
c
      do n=1,level*2
         h=max(h/2.d0,h1)
c         if(n.ge.level)then
c            h=h1
c         else
c            h=h/2.d0
c         endif
         call initphi(nvert,x,y,rwork(lphi),dropone,eps,rd,xd,yd,
     &               flowtype)
         nvertd=nvert
         call GRrfnmsh(mxnbd,mxvert,mxelem,ngmx,ncmx,nvertd,rwork(lphi),
     &                 nbd,nvert,nelem,iwork(lbdseg),iwork(lrefseg),
     &                 inod,nec,reft,x,y,h,hh2,hh3,dG,lrmsh)
         if(.not.lrmsh)exit
c
         if(dropone)then
            if(h2.le.h3)then
               hh2=max(hh2/2.d0,h2)
            else
               hh2=min(hh2*2.d0,h2)
            endif
         else
            if(h3.le.h2)then
               hh3=max(hh3/2.d0,h3)
            else
               hh3=min(hh3*2.d0,h3)
            endif
         endif
c 
      enddo
      call mshtrans(mxnbd,mxbdp,mxnode,ngmx,ncmx,
     &              nvert,nnode,x,y,nelem,inod,nec,area,aspr,
     &              nbd,iwork(lrefseg),iwork(lbdseg),ibdnod,
     &               nic,ic,nbound,nside,
     &              iwork(lngh),iwork(lflag),iwork(lrmhold),
     &               iwork(lrmhnew),iwork(lnodseg),iwork(lnxtseg),
     &               iwork(lmidnod),
     &              iwork(lnumseg),iwork(liwork))
c      call mshoutput(nnode,nvert,nelem,ngmx,ncmx,
c     &               inod,nec,x,y,
c     &               nbd,ibdnod,nic,ic, nbound,nside)
      reft(1:nelem)=1
c      do n=1,nelem
c         if(reft(n).ne.1)stop 'error in reft'
c      enddo
c      open(101,file='reft.dat')
c      do n=1,nelem
c         write(*,*)n,reft(n)
c      enddo
c      close(101)      
c      lrmsh=.false.
      write(*,'("Vert=",i7,1x,"Node=",i7,1x,"Elem=",i7,1x,"nbd=",i7)')
     &   nvert,nnode,nelem,nbd
      call WRAMPHIMESH()
      end

c***********************************************************************
      subroutine mshtrans(mxnbd,mxbdp,mxnode,ngmx,ncmx,
     &                    nvert,nnode,x,y,nelem,inod,nec,area,aspr,
     &                    nbd,refseg,bdseg,ibdnod,nic,ic,nbound,nside,
     &                    ngh,iflag,rmhold,rmhnew,nodseg,nxtseg,midnod,
     &                    numseg,iwork)
c
c-----------------------------------------------------------------------
c     This subroutine check the integrity of the mesh generated by 
c        grummp and generate the date required by Amphi
c
c     input:
c        maximum numbers: (for array bound checking as well)
c           mxnbd,mxbdp,mxnode
c        nvert:   number of vertices
c        nelem:   nubmer of elements
c        refseg:  ref # of boundary segments
c        bdseg:   ending node number of boundary segments
c        indd:    element description table(P1 element)
c        nec:     neighbouring elements
c        coor:    coordinates of vertices          
c        nbd:     number of bounary vertices
c    output:
c        nnode:   number of nodes
c        x,y:     coordinates of nodes
c        inod:    element description table (P2 element)
c        nbd:     number of boundary nodes
c        ibdnod:  global indices of boudary nodes      
c        nic:     number of boundary sections
c        ic:      ibdnod(ic(i):ic(i+1)-1) are the boundary nodes in ith
c                 bounary section
c        nbound:  number of closed boundaries
c        nside:   number of sections in each closed boundary
c        area:    area of elements(twice of area)
c        aspr:    aspect ratio of elements
c        nec:     reset negative entries to zero
c     working:
c        ngh:     ngh(i,ne)=j : ne element is the jth neighbour 
c                 of its ith neighbour
c        nodseg:  neighbouring bd segments of nodes
c        
c                       -------node-------->
c                           |           |
c                      nodseg(1,n)    nodseg(2,n)
c        nxtseg:  next boundar segment
c        numseg(new segment number):    
c                 old segment number
c        iflag,rmhold,rmhnew,midnod,iwork
c-----------------------------------------------------------------------
c                              n3
c     element info:           /  \
c                         e3,n6  n5,e2
c                           /      \
c                          n1--n4--n2
c                              e1
c
c     nec(i,ne)=-ref when the edge is a boundary edge
c     nec(i,ne)=0 will return error, at output, nec(i,ne) is set to 
c     zero for all negative values for consistency with Amphi
c     ibdnod:
c           1--2--3--4--5--6--7--8--9--10--11--12--13--14
c           |<-------sec 1------>|  |<-----sec 2------>|
c           |<---------------------boundary 1 -----------
c           1,3,5,...odd entries are vertices
c           2,4,6,...even entries are midnodes
c
c     Mar 3, 2005    Pengtao Yue                
c-----------------------------------------------------------------------
      implicit none
      intent (in)    :: mxnbd,mxbdp,nvert,mxnode,nelem,
     &                  bdseg,refseg,ngmx,ncmx
      intent (inout) :: nbd,inod,x,y,nec
      intent (out)   :: nic,ic,nnode,ibdnod,area,aspr,nbound,nside
      integer nbd,nvert,nelem,mxnbd,mxbdp,nic,mxnode,nnode,ngmx,ncmx,
     &        nbound
      integer bdseg(2,mxnbd),refseg(mxnbd),ic(mxbdp+1),inod(ngmx,nelem),
     &        nec(ncmx,nelem),ibdnod(mxnbd),rmhold(nelem),rmhnew(nelem),
     &        iwork(3,nelem)
      real*8  x(mxnode),y(mxnode),area(nelem),aspr(nelem)
      integer ngh(3,nelem),iflag(nvert),numseg(mxnbd)
      integer nodseg(2,nvert),nxtseg(mxnbd),nside(mxbdp),midnod(mxnbd)
c-----------------------------------------------------------------------
      real*8  xcoor,c1,c2,c3,y1,y2,y3,x21,x31,y21,y31,tmp
      integer n,n1,n2,n3,ne,i,i1,i2,i3,j,m
c-----------------------------------------------------------------------
c
c     renumbering the elements
c     ------------------------
      call GRnumnel (nelem,ncmx,nec,rmhold,rmhnew)
c     update inod
      iwork(1:3,1:nelem)=inod(1:3,1:nelem)
      do n=1,nelem
         inod(1:3,rmhnew(n))=iwork(1:3,n)
      enddo
c     update nec
      iwork(1:3,1:nelem)=nec(1:3,1:nelem)
      do n=1,nelem
         do i=1,3
            n2=iwork(i,n)
            if(n2.gt.0)n2=rmhnew(n2)
            nec(i,rmhnew(n))=n2
         enddo
      enddo
c
c     Check the integrity of the input mesh
c     -------------------------------------
c
c     local node ordering (element area)
      do i=1,nelem
         n1 = inod(1,i)
         n2 = inod(2,i)
         n3 = inod(3,i)
         c1 = x(n1)
         c2 = xcoor(c1,x(n2))
         c3 = xcoor(c1,x(n3))
         y1 = y(n1)
         y2 = y(n2)
         y3 = y(n3)
         x21 = c2-c1
         x31 = c3-c1
         y21 = y2-y1
         y31 = y3-y1
         tmp = x21*y31 - y21*x31
         area(i) = tmp
         aspr(i) = max(x21**2+y21**2,x31**2+y31**2,
     &                   (c3-c2)**2+(y3-y2)**2) / tmp
         if ( tmp.le.0.d0 ) then
            write(*,*) 'mshtrans: element with negative area! in elem',i
            stop
         endif
      enddo
c     
c     calculate ngh(3,nelem)
      do ne=1,nelem
         do i=1,3
            n2=nec(i,ne)
            if(n2.le.0)then
               ngh(i,ne)=n2
               if(n2.eq.0) then
                  write(*,*) 'mshtrans: error! nec=0 in elem', ne
                  stop
               endif
            else
               do j=1,3
                  if(nec(j,n2).eq.ne)exit
               enddo
               if(j.gt.3) then
                  write(*,*) 'mshtrans: error in nec! elem=',ne
                  stop
               endif
               ngh(i,ne)=j
            endif
         enddo
      enddo      
c     check the local numbering of neighbour elements
      do ne=1,nelem
         do i=1,3
            i1=i
            i2=mod(i1,3)+1
            i3=mod(i2,3)+1
            n2=nec(i,ne)
            if(n2.le.0) cycle
            do j=1,3
               if(inod(i3,ne).eq.inod(j,n2))then
                  write(*,*)'mshtrans: error in nec local numbering'
                  stop
               endif
            enddo
         enddo
      enddo
c
c     boundary nodes and segments manipulation
c     ----------------------------------------
c     calculate the neighboring bdsegments of bd nodes
      nodseg(1:2,1:nvert)=0
      iflag(1:nvert)=0
      do n=1,nbd
         n1=bdseg(1,n)
         n2=bdseg(2,n)
         nodseg(2,n1)=n
         nodseg(1,n2)=n
         ibdnod(n)=n1
         if(iflag(n1).eq.1)stop 'mshtrans: error in bdseg!'
         iflag(n1)=1
      enddo
c     get the next contiguous bd segments
      do n=1,nbd      
         i=ibdnod(n)
         nxtseg(nodseg(1,i))=nodseg(2,i)
      enddo
c     get the new order of the boundary segments
      nside(1:mxbdp)=1
      nbound=0
      nic=0
      iflag(1:nbd)=0
      m=0
      do while(m.lt.nbd)
         nbound=nbound+1
         nic=nic+1
c         ic(nic)=m+1
         do n=1,nbd
            if(iflag(n).eq.1)cycle
            n1=nxtseg(n)
            if(refseg(n).ne.nic.and.refseg(n1).eq.nic) then 
               ic(nic)=m+1
               exit
            endif
         enddo
c	if there's only one ref # on a closed boundary
         if(n==nbd+1)then
            do n=1,nbd
               if(refseg(n)==nic)then
                  ic(nic)=m+1
                  exit
               endif
            enddo
         endif
c
         do while(m.lt.nbd)
            n=nxtseg(n)
            if(iflag(n).eq.1)exit
            m=m+1
            numseg(m)=n
            iflag(n)=1
            if(refseg(n).ne.nic)then
c     debug point 2
      if(refseg(n).ne.nic+1)stop 'mshtrans: error at debug piont2'
c     end debug     
               nic=nic+1
               ic(nic)=m
               nside(nbound)=nside(nbound)+1
            endif
         enddo
      enddo
      ic(nic+1)=nbd+1
c     check the integrity of ic
      do n=1,nic
         if(ic(n).ge.ic(n+1))stop 'mshtrans: error in ic(nic+1)'
      enddo
c
c     Generate mid-nodes
c     ------------------
      n=nvert
      do ne=1,nelem
         do i=1,3
            n2=nec(i,ne)
            i1=inod(i,ne)
            i2=inod(mod(i,3)+1,ne)
            if(n2.lt.0)then
               n=n+1
               x(n)=0.5d0*(x(i1)+x(i2))
               y(n)=0.5d0*(y(i1)+y(i2))
c               n2=-n2
c               seclst(n2)=seclst(n2)+1
c               ibdnod(seclst(n2))=n
               inod(3+i,ne)=n
               midnod(nodseg(2,i1))=n
c     debug point 3
         if(bdseg(2,nodseg(2,i1)).ne.i2)
     &      stop 'mshtrans: error at debug point3'
c
            elseif(n2.gt.ne)then
               n=n+1
               x(n)=0.5d0*(x(i1)+x(i2))
               y(n)=0.5d0*(y(i1)+y(i2))
               inod(3+i,ne)=n
               inod(3+ngh(i,ne),n2)=n
            endif
         enddo
      enddo
      nnode=n
c     check boundary integrity
c      do n=1,nic
c         if(seclst(n).ne.ic(n+1)-1)then
c            write(*,*)'mshtrans: error in ic(nic+1)! section',n
c            stop
c         endif               
c      enddo
c
c     calculate ibdnod
c     ----------------
      m=0
      do n=1,nbd
         n1=numseg(n)
         m=m+1
         ibdnod(m)=bdseg(1,n1)
         m=m+1
         ibdnod(m)=midnod(n1)
      enddo
      ic(1:nic+1)=2*ic(1:nic+1)-1
      nbd=nbd*2
c     set nec to zero for negative values
      do n=1,nelem
         do i=1,3
            nec(i,n)=max(0,nec(i,n))
         enddo
      enddo
c-----------------------------------------------------------------------  
      return    
      end
c***********************************************************************
      subroutine GRnumnel (nelem,ncmx,nec,rmhnel,rmhlen)
c
c     The routine renumbers the mesh using Cuthill & McKee's algorithm
c
c     OUTPUT 
c       rmhnel(new elem numb) = old elem numb
c       rmhlen(old elem numb) = new elem numb
c     Modified by Pengtao Yue on Mar 8,2005
c        from Howard's subroutine RNBNEL
c     NOTE: nec<=0 for bounary edges
c***********************************************************************
      implicit none
      intent  (in):: nelem,ncmx,nec
      intent (out):: rmhnel, rmhlen
      integer nelem,ncmx,nec(ncmx,nelem),rmhnel(nelem),rmhlen(nelem)
c
      integer i,ie,nact1,nact2,mact,ne,nne
c
      do i=1,nelem
         rmhnel(i) = 0
         rmhlen(i) = 0
      enddo
      rmhnel(1) = 1
      rmhlen(1) = 1
c
      nact1 = 1
      nact2 = 1
      do while (nact2.lt.nelem )
c
         mact = 0
         do ie=nact1,nact2
            ne = rmhnel(ie)
            do i=1,3
               nne = nec(i,ne)
               if ( nne.gt.0 ) then
                  if ( rmhlen(nne).eq.0 ) then
                     mact = mact + 1
                     rmhnel(nact2+mact) = nne
                     rmhlen(nne) = nact2+mact
                  endif
               endif
            enddo
         enddo
c
         nact1 = nact2 + 1
         nact2 = nact2 + mact
c
      enddo
c
      return
      end
c***********************************************************************
      subroutine mshoutput (nnode,nvert,nelem,ngmx,ncmx,
     &                      inod,nec,x,y,
     &                      nbd,ibdnod,nic,ic, nbound,nside)
c     Jan, 2005, Pengtao Yue
c     This routine outputs mesh data for tecplot
c
c     Input :
c       it  : iteration courante
c       nnode,nvert,nelem,inod,x,y, nbd,ibdnod,nic,ic: mesh inf.
c       u,p : velocities and pressure
c       strm, vort: streamfunction and vorticity
c***********************************************************************
      implicit none
      integer nnode,nvert,nelem,ngmx,ncmx,nbd,nic,nbound
      integer inod(ngmx,nelem),nec(ncmx,nelem),ibdnod(nbd),ic(nic+1),
     &        nside(nbound)
      real(8) x(nnode),y(nnode)
c
      integer iou,i,j,k,m
      iou=101

      open(unit=iou,file='tecmesh.dat')
        write(iou,'(a,1pe13.5,a)')'Title="2D Mesh"'
        write(iou,'(a)')'Variables="x", "y"'
        write(iou,'(a,2(1x,a,i7))')'ZONE', 'N=', nvert, 'E=', nelem
        write(iou,'(a)')'F=FEBLOCK, ET=TRIANGLE'
        
        write(iou,1015) (x(i),i=1,nvert)
        write(iou,1015) (y(i),i=1,nvert)
        write(iou,1013) ((inod(i,k),i=1,3),k=1,nelem)
c
      close(unit=iou)
c     output nec
      open(iou,file='nec.dat')
      do i=1,nelem
         write(iou,*)'elem',i,':',nec(1:3,i)
      enddo
c     output ibdnod
      open(iou,file='bdnode.dat')
      m=0
      do i=1,nbound
         do j=1,nside(nbound)
            m=m+1
            write(iou,*)'bounary',i,' section',j
            write(iou,'(80(1h*))')
            write(iou,*)ibdnod(ic(m):ic(m+1)-1)
         enddo
      enddo
      close(iou)
      open(iou,file='nodes.dat')
      do i=1,nnode
        write(iou,*)x(i),y(i)
      enddo
      close(iou)
      open(iou,file='inod.dat')
      do i=1,nelem
        write(iou,'("elem",i5,":",6(1x,i5))')i,inod(1:ngmx,i)
      enddo
      close(iou)
      
1013  format(3i6)
1015  format(6(1pe13.5))
c
      end
