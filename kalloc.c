// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"
#include "list.h"

struct trackedframes trackedframes = {{0},{0}, 0};
int everyOther = 1;
void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  int use_lock;
  struct run *freelist;
} kmem;

//Array of 
// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)  // Fee only every other page
    kfree(p);
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
  
  if(kmem.use_lock)
    acquire(&kmem.lock);
  if(everyOther == 1){
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  everyOther = 0;
    } else{
    everyOther = 1;
}
  if(kmem.use_lock)
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  // TODO: figure out calling process to get the pid
  struct run *r;

  int numframes = trackedframes.numframes;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;

  // TODO: is it here where we should check if the process has free pages on
  // either side (or the same process on one side)?
  if(r && (numframes == 0 ||
    trackedframes.pids[numframes] == trackedframes.pids[numframes - 1] ||
    trackedframes.pids[numframes - 1] == -2)) {

    kmem.freelist = r->next; // This is where it allocates free frame I think?

    // Get page number by masking offset - hopefully this works
    uint pagenumber = (V2P((char*)r) >> 12) & 0xffff;//((PHYSTOP - V2P((char*)r)) >> 12);

    // Add to trackedframes struct
    if (kmem.use_lock) {
     // numframes++;
      trackedframes.frames[numframes] = pagenumber;
      numframes++;
       trackedframes.numframes = numframes;
     // numframes++;
    }
    trackedframes.pids[numframes] = -2; //idk why this has to be outside of the lock
  }
  if(kmem.use_lock)
    release(&kmem.lock);

  return (char*)r;
}

//User program will allocate the arrays
//this syscall will fill the arrays with the tracked frames & pids
int
dump_physmem(int *frames, int *pids, int numframes)
{
    //This gives the correct frames for test 1 when only printing the first 100
    //the numframes int that is passed is not correct
    //it should be 100 but ~44000 is being passed
    if(frames == 0 || pids == 0){
        return -1;
    }
    for(int i = 0; i < numframes; i++){
        frames[i] = trackedframes.frames[i];
        //adding the pids here will fuck the frames up, idk wtf is goin on
        //maybe something with how it's set outside of a lock
        pids[i] = trackedframes.pids[i];
    }
/*  int i = 0;


  while(trackedframes.frames[i] != 0) {
   // cprintf("frames[%d] = %X; pids[%d] = %X\n",
   //         i, trackedframes.frames[i], i, trackedframes.pids[i]);
    frames[i] = trackedframes.frames[i];
    i++;
  }*/

  return 0;
}
