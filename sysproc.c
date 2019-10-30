#include "types.h"
#include "x86.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "list.h"

int
sys_fork(void)
{
  return fork();
}

int
sys_exit(void)
{
  exit();
  return 0;  // not reached
}

int
sys_wait(void)
{
  return wait();
}

int
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

int
sys_getpid(void)
{
  return myproc()->pid;
}

int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

int
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// This system call is used to find which process owns
// each frame of physical memory.
// frames is an array of integers corresponding to frame numbers
// pids is an array of integers corresponding to frame numbers
// numframes is the number of elements in the frames and pids arrays
int
sys_dump_physmem(int *frames, int *pids, int numframes)
{
  if(argint(0, &numframes) < 0)
    return -1;

  if(argptr(0, (void*)&frames, sizeof(frames)) < 0 ||
     argptr(0, (void*)&pids, sizeof(pids)) < 0)
     return -1;

  //TODO
  int i = 0;

  while(trackedframes.frames[i] != 0) {
    cprintf("frames[%d] = %d; pids[%d] = %d\n",
            i, trackedframes.frames[i], i, trackedframes.pids[i]);
    i++;
  }

  return 0;
}
