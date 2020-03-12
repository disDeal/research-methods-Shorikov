      program mt_mpi
      implicit none

      include "mpif.h"
      INTEGER :: ncol, nrow, i, j, ierr
      INTEGER :: ncol_main, nrow_main, ncol_sub, nrow_sub
      INTEGER :: ncol_l, nrow_l, ncol_r, nrow_r
      INTEGER :: nproc, rank
      INTEGER :: tmp
      INTEGER, ALLOCATABLE :: arr(:,:), arr2(:,:), slice(:,:)
      INTEGER, ALLOCATABLE :: chunk_main(:,:), chunk_sub(:,:)
      INTEGER, ALLOCATABLE :: chunk_l(:,:), chunk_r(:,:)
      INTEGER status(MPI_STATUS_SIZE)

      CALL MPI_INIT(ierr)
      CALL MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, ierr)
      CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)

      if (rank .eq. 0) then
          open(10, file='M', form='formatted', status='unknown')
          read(10, *)ncol
          read(10, *)nrow

          ALLOCATE (arr(ncol, nrow))
          do i = 1,ncol
              read(10,*)(arr(i,j),j=1,nrow)
          enddo

          write(6,*) "ncol:", ncol, ", nrow:", nrow
          write(6,*) "Untouched matrix:"
          do i = 1,ncol
              write(6,100)(arr(i,j),j=1,nrow)
          enddo

       endif


       if (rank .eq. 0) then

           CALL MPI_BCAST(ncol, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)
           CALL MPI_BCAST(nrow, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)

           ncol_main = ncol - ncol / 2
           nrow_main = nrow - nrow / 2

           slice = arr(ncol_main+1:ncol_main+ncol/2,nrow_main+1:nrow_main+nrow/2)
           CALL MPI_SEND(slice, (ncol/2)*(nrow/2), MPI_INTEGER, 1, 01, MPI_COMM_WORLD,ierr)
           DEALLOCATE (slice)

           slice = arr(1:ncol_main,nrow_main+1:nrow_main+nrow/2)
           CALL MPI_SEND(slice, (ncol/2)*(nrow_main), MPI_INTEGER, 2, 02, MPI_COMM_WORLD,ierr)
           DEALLOCATE (slice)

           slice = arr(ncol_main+1:ncol_main+ncol/2,1:nrow/2)
           CALL MPI_SEND(slice, (ncol_main)*(nrow/2), MPI_INTEGER, 3, 03, MPI_COMM_WORLD,ierr)
           DEALLOCATE (slice)

           chunk_main = arr(1:ncol_main,1:nrow_main)

           MPI_BARRIER(MPI_COMM_WORLD, ierr)
           do i = 1,ncol_main
               do j = 1,nrow_main
                   tmp = arr(i, j)
                   arr(i, j) = arr(j, i)
                   arr(j, i) = tmp
               enddo
           enddo
           MPI_BARRIER(MPI_COMM_WORLD, ierr)


           write(6,*) "Main matrix:"
           do i = 1,ncol_main
               write(6,100)(arr(i,j),j=1,nrow_main)
           enddo


      elseif (rank .eq. 1) then

           CALL MPI_BCAST(ncol, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)
           CALL MPI_BCAST(nrow, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)

           ncol_sub = ncol / 2
           nrow_sub = nrow / 2


           ALLOCATE (chunk_sub(ncol_sub, ncol_sub))
           CALL MPI_RECV(chunk_sub, ncol_sub*nrow_sub, MPI_INTEGER, 0, 01, MPI_COMM_WORLD, status,ierr)

           do i = 1,ncol_sub
               do j = 1,nrow_sub
                   tmp = chunk_sub(i, j)
                   chunk_sub(i, j) = chunk_sub(j, i)
                   chunk_sub(j, i) = tmp
               enddo
           enddo

           write(6,*) "Sub matrix:"
           do i = 1,ncol_sub
               write(6,100)(chunk_sub(i,j),j=1,nrow_sub)
           enddo

           DEALLOCATE (chunk_sub)

       elseif (rank .eq. 2) then

           CALL MPI_BCAST(ncol, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)
           CALL MPI_BCAST(nrow, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)

           ncol_r = ncol - ncol/ 2
           nrow_r = nrow / 2

           ALLOCATE (chunk_r(ncol_r, ncol_r))
           CALL MPI_RECV(chunk_r, ncol_r*nrow_r, MPI_INTEGER, 0, 02, MPI_COMM_WORLD, status,ierr)

!           write(6,*) "Right matrix:"
!           do i = 1,ncol_r
!               write(6,100)(chunk_r(i,j),j=1,nrow_r)
!           enddo

           DEALLOCATE (chunk_r)

      elseif (rank .eq. 3) then

           CALL MPI_BCAST(ncol, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)
           CALL MPI_BCAST(nrow, 1, MPI_INTEGER, 0, MPI_COMM_WORLD,ierr)

           ncol_l = ncol / 2
           nrow_l = nrow - nrow / 2

           ALLOCATE (chunk_l(ncol_l, ncol_l))
           CALL MPI_RECV(chunk_l, ncol_l*nrow_l, MPI_INTEGER, 0, 03, MPI_COMM_WORLD, status,ierr)

!           write(6,*) "Left matrix:"
!           do i = 1,ncol_l
!               write(6,100)(chunk_l(i,j),j=1,nrow_l)
!           enddo


           DEALLOCATE (chunk_l)
      endif


      CALL MPI_FINALIZE(ierr)

      if (rank .eq. 0) then
          DEALLOCATE (arr)
      endif

100   format(100i4)
      end 
