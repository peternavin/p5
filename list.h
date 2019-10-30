#define MAX_FRAMES 16384

struct trackedframes {
  int pids[MAX_FRAMES];
  int frames[MAX_FRAMES];
  int pages;
};

extern struct trackedframes trackedframes;
