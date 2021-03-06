c***********************************************************************
      subroutine tecpostgmsh ( nnode,nvert,nelem,ngmx,inod,x,y,phi,dist)
c***********************************************************************
      implicit none
      integer nnode,nvert,nelem,ngmx,
     &        inod(ngmx,nelem)
      real*8 x(nnode),y(nnode),phi(nnode),dist(nvert)
c
      integer iou, i,k
c      
      iou=10
      open(unit=iou,file="tec_dist.dat")
        write(iou,'(a)')'Title="distance function"'
        write(iou,'(a)')'Variables="x", "y", "phi", "d"'
        write(iou,'(a,2(1x,a,i7))')'ZONE', 'N=', nvert, 'E=', nelem
        write(iou,'(a)')'F=FEBLOCK, ET=TRIANGLE'
        
        write(iou,1015) (x(i),i=1,nvert)
        write(iou,1015) (y(i),i=1,nvert)
        write(iou,1015) (phi(i),i=1,nvert)
        write(iou,1015) (dist(i),i=1,nvert)
        do k=1,nelem
          write(iou,1013) (inod(i,k),i=1,3)
        enddo
        
      close(unit=iou)
c
      return
c
1013  format(3i6)
1015  format(6(1pe13.5))
c
      end
