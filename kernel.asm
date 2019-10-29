
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 80 10 00       	mov    $0x108000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc d0 a5 10 80       	mov    $0x8010a5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 83 2a 10 80       	mov    $0x80102a83,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 e0 a5 10 80       	push   $0x8010a5e0
80100046:	e8 69 3b 00 00       	call   80103bb4 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 ed 10 80    	mov    0x8010ed30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 e0 a5 10 80       	push   $0x8010a5e0
8010007c:	e8 98 3b 00 00       	call   80103c19 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 14 39 00 00       	call   801039a0 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c ed 10 80    	mov    0x8010ed2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 e0 a5 10 80       	push   $0x8010a5e0
801000ca:	e8 4a 3b 00 00       	call   80103c19 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 c6 38 00 00       	call   801039a0 <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 40 64 10 80       	push   $0x80106440
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 64 10 80       	push   $0x80106451
80100100:	68 e0 a5 10 80       	push   $0x8010a5e0
80100105:	e8 6e 39 00 00       	call   80103a78 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed2c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed30
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 58 64 10 80       	push   $0x80106458
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 25 38 00 00       	call   8010396d <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 7d 38 00 00       	call   80103a2a <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 5f 64 10 80       	push   $0x8010645f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 41 38 00 00       	call   80103a2a <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 f6 37 00 00       	call   801039ef <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80100200:	e8 af 39 00 00       	call   80103bb4 <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 a5 10 80       	push   $0x8010a5e0
8010024c:	e8 c8 39 00 00       	call   80103c19 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 64 10 80       	push   $0x80106466
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 25 39 00 00       	call   80103bb4 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
8010029f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 69 2f 00 00       	call   80103215 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 95 10 80       	push   $0x80109520
801002ba:	68 c0 ef 10 80       	push   $0x8010efc0
801002bf:	e8 f5 33 00 00       	call   801036b9 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 43 39 00 00       	call   80103c19 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 c0 ef 10 80    	mov    %edx,0x8010efc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ef 10 80 	movzbl -0x7fef10c0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 c0 ef 10 80       	mov    %eax,0x8010efc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 95 10 80       	push   $0x80109520
80100331:	e8 e3 38 00 00       	call   80103c19 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 95 10 80 00 	movl   $0x0,0x80109554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 3e 20 00 00       	call   8010239d <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 64 10 80       	push   $0x8010646d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 6d 10 80 	movl   $0x80106dbb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 ff 36 00 00       	call   80103a93 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 64 10 80       	push   $0x80106481
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 95 10 80 01 	movl   $0x1,0x80109558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 85 64 10 80       	push   $0x80106485
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 1c 38 00 00       	call   80103cdb <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 82 37 00 00       	call   80103c60 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 95 10 80 00 	cmpl   $0x0,0x80109558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 28 4b 00 00       	call   80105033 <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 0f 4b 00 00       	call   80105033 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 03 4b 00 00       	call   80105033 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 f7 4a 00 00       	call   80105033 <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 b0 64 10 80 	movzbl -0x7fef9b50(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 e5 35 00 00       	call   80103bb4 <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 95 10 80       	push   $0x80109520
801005f1:	e8 23 36 00 00       	call   80103c19 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 95 10 80       	mov    0x80109554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 95 10 80       	push   $0x80109520
80100638:	e8 77 35 00 00       	call   80103bb4 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 64 10 80       	push   $0x8010649f
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be 98 64 10 80       	mov    $0x80106498,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 95 10 80       	push   $0x80109520
80100734:	e8 e0 34 00 00       	call   80103c19 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 95 10 80       	push   $0x80109520
8010074f:	e8 60 34 00 00       	call   80103bb4 <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ef 10 80    	sub    0x8010efc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ef 10 80    	mov    %edx,0x8010efc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ef 10 80    	mov    %cl,-0x7fef10c0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ef 10 80    	cmp    %eax,0x8010efc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007d1:	a3 c4 ef 10 80       	mov    %eax,0x8010efc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ef 10 80       	push   $0x8010efc0
801007de:	e8 3b 30 00 00       	call   8010381e <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007fc:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ef 10 80 0a 	cmpb   $0xa,-0x7fef10c0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
8010084f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 95 10 80       	push   $0x80109520
80100873:	e8 a1 33 00 00       	call   80103c19 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 2f 30 00 00       	call   801038bb <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 a8 64 10 80       	push   $0x801064a8
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 d5 31 00 00       	call   80103a78 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c f9 10 80 ac 	movl   $0x801005ac,0x8010f98c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 f9 10 80 68 	movl   $0x80100268,0x8010f988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 95 10 80 01 	movl   $0x1,0x80109554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 32 29 00 00       	call   80103215 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 df 1e 00 00       	call   801027cd <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 0d 1f 00 00       	call   80102847 <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 f8 1e 00 00       	call   80102847 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 64 10 80       	push   $0x801064c1
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 7c 58 00 00       	call   801061f3 <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 8e 56 00 00       	call   80106099 <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 2a 55 00 00       	call   80105f67 <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 ef 1d 00 00       	call   80102847 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 20 56 00 00       	call   80106099 <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 e1 56 00 00       	call   80106183 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 b7 57 00 00       	call   80106278 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 1b 33 00 00       	call   80103e02 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 09 33 00 00       	call   80103e02 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 bb 58 00 00       	call   801063c6 <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 5b 58 00 00       	call   801063c6 <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 1f 32 00 00       	call   80103dc7 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 10 52 00 00       	call   80105de6 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 a5 55 00 00       	call   80106183 <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 cd 64 10 80       	push   $0x801064cd
80100c1e:	68 e0 ef 10 80       	push   $0x8010efe0
80100c23:	e8 50 2e 00 00       	call   80103a78 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 e0 ef 10 80       	push   $0x8010efe0
80100c39:	e8 76 2f 00 00       	call   80103bb4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 14 f0 10 80       	mov    $0x8010f014,%ebx
80100c46:	81 fb 74 f9 10 80    	cmp    $0x8010f974,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 e0 ef 10 80       	push   $0x8010efe0
80100c68:	e8 ac 2f 00 00       	call   80103c19 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 e0 ef 10 80       	push   $0x8010efe0
80100c7f:	e8 95 2f 00 00       	call   80103c19 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 e0 ef 10 80       	push   $0x8010efe0
80100c9d:	e8 12 2f 00 00       	call   80103bb4 <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 e0 ef 10 80       	push   $0x8010efe0
80100cba:	e8 5a 2f 00 00       	call   80103c19 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 64 10 80       	push   $0x801064d4
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 e0 ef 10 80       	push   $0x8010efe0
80100ce2:	e8 cd 2e 00 00       	call   80103bb4 <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 e0 ef 10 80       	push   $0x8010efe0
80100d03:	e8 11 2f 00 00       	call   80103c19 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 dc 64 10 80       	push   $0x801064dc
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 e0 ef 10 80       	push   $0x8010efe0
80100d49:	e8 cb 2e 00 00       	call   80103c19 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 6a 1a 00 00       	call   801027cd <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 d4 1a 00 00       	call   80102847 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 b9 20 00 00       	call   80102e41 <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 58 21 00 00       	call   80102f99 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 64 10 80       	push   $0x801064e6
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 33 20 00 00       	call   80102ecd <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 26 19 00 00       	call   801027cd <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 65 19 00 00       	call   80102847 <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 ef 64 10 80       	push   $0x801064ef
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 f5 64 10 80       	push   $0x801064f5
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 4c 2d 00 00       	call   80103cdb <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 3c 2d 00 00       	call   80103cdb <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 7c 2c 00 00       	call   80103c60 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 0a 19 00 00       	call   801028f6 <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 e0 f9 10 80    	cmp    %esi,0x8010f9e0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d e0 f9 10 80    	cmp    0x8010f9e0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 ff 64 10 80       	push   $0x801064ff
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 32 18 00 00       	call   801028f6 <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 81 17 00 00       	call   801028f6 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 65 10 80       	push   $0x80106515
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 00 fa 10 80       	push   $0x8010fa00
8010119a:	e8 15 2a 00 00       	call   80103bb4 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 34 fa 10 80       	mov    $0x8010fa34,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 54 16 11 80    	cmp    $0x80111654,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 00 fa 10 80       	push   $0x8010fa00
801011e1:	e8 33 2a 00 00       	call   80103c19 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 00 fa 10 80       	push   $0x8010fa00
80101217:	e8 fd 29 00 00       	call   80103c19 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 28 65 10 80       	push   $0x80106528
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 81 2a 00 00       	call   80103cdb <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 e0 f9 10 80       	push   $0x8010f9e0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 29 16 00 00       	call   801028f6 <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 38 65 10 80       	push   $0x80106538
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 65 10 80       	push   $0x8010654b
801012f8:	68 00 fa 10 80       	push   $0x8010fa00
801012fd:	e8 76 27 00 00       	call   80103a78 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 65 10 80       	push   $0x80106552
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 fa 10 80       	add    $0x8010fa40,%eax
80101321:	50                   	push   %eax
80101322:	e8 46 26 00 00       	call   8010396d <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 e0 f9 10 80       	push   $0x8010f9e0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 f8 f9 10 80    	pushl  0x8010f9f8
80101348:	ff 35 f4 f9 10 80    	pushl  0x8010f9f4
8010134e:	ff 35 f0 f9 10 80    	pushl  0x8010f9f0
80101354:	ff 35 ec f9 10 80    	pushl  0x8010f9ec
8010135a:	ff 35 e8 f9 10 80    	pushl  0x8010f9e8
80101360:	ff 35 e4 f9 10 80    	pushl  0x8010f9e4
80101366:	ff 35 e0 f9 10 80    	pushl  0x8010f9e0
8010136c:	68 b8 65 10 80       	push   $0x801065b8
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d e8 f9 10 80    	cmp    %ebx,0x8010f9e8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 58 65 10 80       	push   $0x80106558
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 6a 28 00 00       	call   80103c60 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 f1 14 00 00       	call   801028f6 <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 56 28 00 00       	call   80103cdb <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 69 14 00 00       	call   801028f6 <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 00 fa 10 80       	push   $0x8010fa00
80101560:	e8 4f 26 00 00       	call   80103bb4 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
80101575:	e8 9f 26 00 00       	call   80103c19 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 01 24 00 00       	call   801039a0 <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 6a 65 10 80       	push   $0x8010656a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 c2 26 00 00       	call   80103cdb <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 70 65 10 80       	push   $0x80106570
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 cf 23 00 00       	call   80103a2a <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 7e 23 00 00       	call   801039ef <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 65 10 80       	push   $0x8010657f
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 03 23 00 00       	call   801039a0 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 39 23 00 00       	call   801039ef <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016bd:	e8 f2 24 00 00       	call   80103bb4 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016d2:	e8 42 25 00 00       	call   80103c19 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 00 fa 10 80       	push   $0x8010fa00
801016ea:	e8 c5 24 00 00       	call   80103bb4 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016f9:	e8 1b 25 00 00       	call   80103c19 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 80 f9 10 80 	mov    -0x7fef0680(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 ac 24 00 00       	call   80103cdb <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 84 f9 10 80 	mov    -0x7fef067c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 b0 23 00 00       	call   80103cdb <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 c3 0f 00 00       	call   801028f6 <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 94 23 00 00       	call   80103d42 <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 87 65 10 80       	push   $0x80106587
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 65 10 80       	push   $0x80106599
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 b6 17 00 00       	call   80103215 <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 a8 65 10 80       	push   $0x801065a8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 d1 21 00 00       	call   80103d7f <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 b4 6b 10 80       	push   $0x80106bb4
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 0b 66 10 80       	push   $0x8010660b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 66 10 80       	push   $0x80106614
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 26 66 10 80       	push   $0x80106626
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 63 1d 00 00       	call   80103a78 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 1d 11 80       	mov    0x80111d20,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 95 10 80       	push   $0x80109580
80101d80:	e8 2f 1e 00 00       	call   80103bb4 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 6c 1a 00 00       	call   8010381e <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 95 10 80       	mov    0x80109564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 95 10 80       	push   $0x80109580
80101dcb:	e8 49 1e 00 00       	call   80103c19 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 95 10 80       	push   $0x80109580
80101de2:	e8 32 1e 00 00       	call   80103c19 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 0b 1c 00 00       	call   80103a2a <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 95 10 80       	push   $0x80109580
80101e47:	e8 68 1d 00 00       	call   80103bb4 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 66 10 80       	push   $0x8010662a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 66 10 80       	push   $0x80106640
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 66 10 80       	push   $0x80106655
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 95 10 80       	push   $0x80109580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 0b 18 00 00       	call   801036b9 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 95 10 80       	push   $0x80109580
80101ec3:	e8 51 1d 00 00       	call   80103c19 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 54 16 11 80    	mov    0x80111654,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 54 16 11 80    	mov    0x80111654,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 54 16 11 80 00 	movl   $0xfec00000,0x80111654
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 80 17 11 80 	movzbl 0x80111780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 74 66 10 80       	push   $0x80106674
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 5f                	jne    80102015 <kfree+0x71>
80101fb6:	81 fb c8 44 11 80    	cmp    $0x801144c8,%ebx
80101fbc:	72 57                	jb     80102015 <kfree+0x71>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 4a                	ja     80102015 <kfree+0x71>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 85 1c 00 00       	call   80103c60 <memset>
  
  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80101fe5:	75 3b                	jne    80102022 <kfree+0x7e>
    acquire(&kmem.lock);
  r = (struct run*)v;
  //r->next = kmem.freelist;
  //SHOULD add every other frame to the freelist
  if(everyOther == 0){
80101fe7:	83 3d b4 95 10 80 00 	cmpl   $0x0,0x801095b4
80101fee:	75 44                	jne    80102034 <kfree+0x90>
    r->next = kmem.freelist;
80101ff0:	a1 98 16 11 80       	mov    0x80111698,%eax
80101ff5:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = r;
80101ff7:	89 1d 98 16 11 80    	mov    %ebx,0x80111698
    everyOther = 1;
80101ffd:	c7 05 b4 95 10 80 01 	movl   $0x1,0x801095b4
80102004:	00 00 00 
  } else{
      everyOther = 0;
  }
  if(kmem.use_lock)
80102007:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
8010200e:	75 30                	jne    80102040 <kfree+0x9c>
    release(&kmem.lock);
}
80102010:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102013:	c9                   	leave  
80102014:	c3                   	ret    
    panic("kfree");
80102015:	83 ec 0c             	sub    $0xc,%esp
80102018:	68 a6 66 10 80       	push   $0x801066a6
8010201d:	e8 26 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102022:	83 ec 0c             	sub    $0xc,%esp
80102025:	68 60 16 11 80       	push   $0x80111660
8010202a:	e8 85 1b 00 00       	call   80103bb4 <acquire>
8010202f:	83 c4 10             	add    $0x10,%esp
80102032:	eb b3                	jmp    80101fe7 <kfree+0x43>
      everyOther = 0;
80102034:	c7 05 b4 95 10 80 00 	movl   $0x0,0x801095b4
8010203b:	00 00 00 
8010203e:	eb c7                	jmp    80102007 <kfree+0x63>
    release(&kmem.lock);
80102040:	83 ec 0c             	sub    $0xc,%esp
80102043:	68 60 16 11 80       	push   $0x80111660
80102048:	e8 cc 1b 00 00       	call   80103c19 <release>
8010204d:	83 c4 10             	add    $0x10,%esp
}
80102050:	eb be                	jmp    80102010 <kfree+0x6c>

80102052 <freerange>:
{
80102052:	55                   	push   %ebp
80102053:	89 e5                	mov    %esp,%ebp
80102055:	56                   	push   %esi
80102056:	53                   	push   %ebx
80102057:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010205a:	8b 45 08             	mov    0x8(%ebp),%eax
8010205d:	05 ff 0f 00 00       	add    $0xfff,%eax
80102062:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102067:	eb 0e                	jmp    80102077 <freerange+0x25>
    kfree(p);
80102069:	83 ec 0c             	sub    $0xc,%esp
8010206c:	50                   	push   %eax
8010206d:	e8 32 ff ff ff       	call   80101fa4 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102072:	83 c4 10             	add    $0x10,%esp
80102075:	89 f0                	mov    %esi,%eax
80102077:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010207d:	39 de                	cmp    %ebx,%esi
8010207f:	76 e8                	jbe    80102069 <freerange+0x17>
}
80102081:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102084:	5b                   	pop    %ebx
80102085:	5e                   	pop    %esi
80102086:	5d                   	pop    %ebp
80102087:	c3                   	ret    

80102088 <kinit1>:
{
80102088:	55                   	push   %ebp
80102089:	89 e5                	mov    %esp,%ebp
8010208b:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010208e:	68 ac 66 10 80       	push   $0x801066ac
80102093:	68 60 16 11 80       	push   $0x80111660
80102098:	e8 db 19 00 00       	call   80103a78 <initlock>
  kmem.use_lock = 0;
8010209d:	c7 05 94 16 11 80 00 	movl   $0x0,0x80111694
801020a4:	00 00 00 
  freerange(vstart, vend);
801020a7:	83 c4 08             	add    $0x8,%esp
801020aa:	ff 75 0c             	pushl  0xc(%ebp)
801020ad:	ff 75 08             	pushl  0x8(%ebp)
801020b0:	e8 9d ff ff ff       	call   80102052 <freerange>
}
801020b5:	83 c4 10             	add    $0x10,%esp
801020b8:	c9                   	leave  
801020b9:	c3                   	ret    

801020ba <kinit2>:
{
801020ba:	55                   	push   %ebp
801020bb:	89 e5                	mov    %esp,%ebp
801020bd:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020c0:	ff 75 0c             	pushl  0xc(%ebp)
801020c3:	ff 75 08             	pushl  0x8(%ebp)
801020c6:	e8 87 ff ff ff       	call   80102052 <freerange>
  kmem.use_lock = 1;
801020cb:	c7 05 94 16 11 80 01 	movl   $0x1,0x80111694
801020d2:	00 00 00 
}
801020d5:	83 c4 10             	add    $0x10,%esp
801020d8:	c9                   	leave  
801020d9:	c3                   	ret    

801020da <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020da:	55                   	push   %ebp
801020db:	89 e5                	mov    %esp,%ebp
801020dd:	53                   	push   %ebx
801020de:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020e1:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020e8:	75 21                	jne    8010210b <kalloc+0x31>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020ea:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
801020f0:	85 db                	test   %ebx,%ebx
801020f2:	74 07                	je     801020fb <kalloc+0x21>
    kmem.freelist = r->next;
801020f4:	8b 03                	mov    (%ebx),%eax
801020f6:	a3 98 16 11 80       	mov    %eax,0x80111698
  if(kmem.use_lock)
801020fb:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80102102:	75 19                	jne    8010211d <kalloc+0x43>
    release(&kmem.lock);
  return (char*)r;
}
80102104:	89 d8                	mov    %ebx,%eax
80102106:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102109:	c9                   	leave  
8010210a:	c3                   	ret    
    acquire(&kmem.lock);
8010210b:	83 ec 0c             	sub    $0xc,%esp
8010210e:	68 60 16 11 80       	push   $0x80111660
80102113:	e8 9c 1a 00 00       	call   80103bb4 <acquire>
80102118:	83 c4 10             	add    $0x10,%esp
8010211b:	eb cd                	jmp    801020ea <kalloc+0x10>
    release(&kmem.lock);
8010211d:	83 ec 0c             	sub    $0xc,%esp
80102120:	68 60 16 11 80       	push   $0x80111660
80102125:	e8 ef 1a 00 00       	call   80103c19 <release>
8010212a:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010212d:	eb d5                	jmp    80102104 <kalloc+0x2a>

8010212f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010212f:	55                   	push   %ebp
80102130:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102132:	ba 64 00 00 00       	mov    $0x64,%edx
80102137:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102138:	a8 01                	test   $0x1,%al
8010213a:	0f 84 b5 00 00 00    	je     801021f5 <kbdgetc+0xc6>
80102140:	ba 60 00 00 00       	mov    $0x60,%edx
80102145:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102146:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102149:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010214f:	74 5c                	je     801021ad <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102151:	84 c0                	test   %al,%al
80102153:	78 66                	js     801021bb <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102155:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
8010215b:	f6 c1 40             	test   $0x40,%cl
8010215e:	74 0f                	je     8010216f <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102160:	83 c8 80             	or     $0xffffff80,%eax
80102163:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102166:	83 e1 bf             	and    $0xffffffbf,%ecx
80102169:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  }

  shift |= shiftcode[data];
8010216f:	0f b6 8a e0 67 10 80 	movzbl -0x7fef9820(%edx),%ecx
80102176:	0b 0d b8 95 10 80    	or     0x801095b8,%ecx
  shift ^= togglecode[data];
8010217c:	0f b6 82 e0 66 10 80 	movzbl -0x7fef9920(%edx),%eax
80102183:	31 c1                	xor    %eax,%ecx
80102185:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  c = charcode[shift & (CTL | SHIFT)][data];
8010218b:	89 c8                	mov    %ecx,%eax
8010218d:	83 e0 03             	and    $0x3,%eax
80102190:	8b 04 85 c0 66 10 80 	mov    -0x7fef9940(,%eax,4),%eax
80102197:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010219b:	f6 c1 08             	test   $0x8,%cl
8010219e:	74 19                	je     801021b9 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801021a0:	8d 50 9f             	lea    -0x61(%eax),%edx
801021a3:	83 fa 19             	cmp    $0x19,%edx
801021a6:	77 40                	ja     801021e8 <kbdgetc+0xb9>
      c += 'A' - 'a';
801021a8:	83 e8 20             	sub    $0x20,%eax
801021ab:	eb 0c                	jmp    801021b9 <kbdgetc+0x8a>
    shift |= E0ESC;
801021ad:	83 0d b8 95 10 80 40 	orl    $0x40,0x801095b8
    return 0;
801021b4:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801021b9:	5d                   	pop    %ebp
801021ba:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801021bb:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
801021c1:	f6 c1 40             	test   $0x40,%cl
801021c4:	75 05                	jne    801021cb <kbdgetc+0x9c>
801021c6:	89 c2                	mov    %eax,%edx
801021c8:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801021cb:	0f b6 82 e0 67 10 80 	movzbl -0x7fef9820(%edx),%eax
801021d2:	83 c8 40             	or     $0x40,%eax
801021d5:	0f b6 c0             	movzbl %al,%eax
801021d8:	f7 d0                	not    %eax
801021da:	21 c8                	and    %ecx,%eax
801021dc:	a3 b8 95 10 80       	mov    %eax,0x801095b8
    return 0;
801021e1:	b8 00 00 00 00       	mov    $0x0,%eax
801021e6:	eb d1                	jmp    801021b9 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801021e8:	8d 50 bf             	lea    -0x41(%eax),%edx
801021eb:	83 fa 19             	cmp    $0x19,%edx
801021ee:	77 c9                	ja     801021b9 <kbdgetc+0x8a>
      c += 'a' - 'A';
801021f0:	83 c0 20             	add    $0x20,%eax
  return c;
801021f3:	eb c4                	jmp    801021b9 <kbdgetc+0x8a>
    return -1;
801021f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021fa:	eb bd                	jmp    801021b9 <kbdgetc+0x8a>

801021fc <kbdintr>:

void
kbdintr(void)
{
801021fc:	55                   	push   %ebp
801021fd:	89 e5                	mov    %esp,%ebp
801021ff:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102202:	68 2f 21 10 80       	push   $0x8010212f
80102207:	e8 32 e5 ff ff       	call   8010073e <consoleintr>
}
8010220c:	83 c4 10             	add    $0x10,%esp
8010220f:	c9                   	leave  
80102210:	c3                   	ret    

80102211 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102211:	55                   	push   %ebp
80102212:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102214:	8b 0d 9c 16 11 80    	mov    0x8011169c,%ecx
8010221a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010221d:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010221f:	a1 9c 16 11 80       	mov    0x8011169c,%eax
80102224:	8b 40 20             	mov    0x20(%eax),%eax
}
80102227:	5d                   	pop    %ebp
80102228:	c3                   	ret    

80102229 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102229:	55                   	push   %ebp
8010222a:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010222c:	ba 70 00 00 00       	mov    $0x70,%edx
80102231:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102232:	ba 71 00 00 00       	mov    $0x71,%edx
80102237:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102238:	0f b6 c0             	movzbl %al,%eax
}
8010223b:	5d                   	pop    %ebp
8010223c:	c3                   	ret    

8010223d <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010223d:	55                   	push   %ebp
8010223e:	89 e5                	mov    %esp,%ebp
80102240:	53                   	push   %ebx
80102241:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102243:	b8 00 00 00 00       	mov    $0x0,%eax
80102248:	e8 dc ff ff ff       	call   80102229 <cmos_read>
8010224d:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010224f:	b8 02 00 00 00       	mov    $0x2,%eax
80102254:	e8 d0 ff ff ff       	call   80102229 <cmos_read>
80102259:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010225c:	b8 04 00 00 00       	mov    $0x4,%eax
80102261:	e8 c3 ff ff ff       	call   80102229 <cmos_read>
80102266:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102269:	b8 07 00 00 00       	mov    $0x7,%eax
8010226e:	e8 b6 ff ff ff       	call   80102229 <cmos_read>
80102273:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102276:	b8 08 00 00 00       	mov    $0x8,%eax
8010227b:	e8 a9 ff ff ff       	call   80102229 <cmos_read>
80102280:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102283:	b8 09 00 00 00       	mov    $0x9,%eax
80102288:	e8 9c ff ff ff       	call   80102229 <cmos_read>
8010228d:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102290:	5b                   	pop    %ebx
80102291:	5d                   	pop    %ebp
80102292:	c3                   	ret    

80102293 <lapicinit>:
  if(!lapic)
80102293:	83 3d 9c 16 11 80 00 	cmpl   $0x0,0x8011169c
8010229a:	0f 84 fb 00 00 00    	je     8010239b <lapicinit+0x108>
{
801022a0:	55                   	push   %ebp
801022a1:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801022a3:	ba 3f 01 00 00       	mov    $0x13f,%edx
801022a8:	b8 3c 00 00 00       	mov    $0x3c,%eax
801022ad:	e8 5f ff ff ff       	call   80102211 <lapicw>
  lapicw(TDCR, X1);
801022b2:	ba 0b 00 00 00       	mov    $0xb,%edx
801022b7:	b8 f8 00 00 00       	mov    $0xf8,%eax
801022bc:	e8 50 ff ff ff       	call   80102211 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801022c1:	ba 20 00 02 00       	mov    $0x20020,%edx
801022c6:	b8 c8 00 00 00       	mov    $0xc8,%eax
801022cb:	e8 41 ff ff ff       	call   80102211 <lapicw>
  lapicw(TICR, 10000000);
801022d0:	ba 80 96 98 00       	mov    $0x989680,%edx
801022d5:	b8 e0 00 00 00       	mov    $0xe0,%eax
801022da:	e8 32 ff ff ff       	call   80102211 <lapicw>
  lapicw(LINT0, MASKED);
801022df:	ba 00 00 01 00       	mov    $0x10000,%edx
801022e4:	b8 d4 00 00 00       	mov    $0xd4,%eax
801022e9:	e8 23 ff ff ff       	call   80102211 <lapicw>
  lapicw(LINT1, MASKED);
801022ee:	ba 00 00 01 00       	mov    $0x10000,%edx
801022f3:	b8 d8 00 00 00       	mov    $0xd8,%eax
801022f8:	e8 14 ff ff ff       	call   80102211 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801022fd:	a1 9c 16 11 80       	mov    0x8011169c,%eax
80102302:	8b 40 30             	mov    0x30(%eax),%eax
80102305:	c1 e8 10             	shr    $0x10,%eax
80102308:	3c 03                	cmp    $0x3,%al
8010230a:	77 7b                	ja     80102387 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010230c:	ba 33 00 00 00       	mov    $0x33,%edx
80102311:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102316:	e8 f6 fe ff ff       	call   80102211 <lapicw>
  lapicw(ESR, 0);
8010231b:	ba 00 00 00 00       	mov    $0x0,%edx
80102320:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102325:	e8 e7 fe ff ff       	call   80102211 <lapicw>
  lapicw(ESR, 0);
8010232a:	ba 00 00 00 00       	mov    $0x0,%edx
8010232f:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102334:	e8 d8 fe ff ff       	call   80102211 <lapicw>
  lapicw(EOI, 0);
80102339:	ba 00 00 00 00       	mov    $0x0,%edx
8010233e:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102343:	e8 c9 fe ff ff       	call   80102211 <lapicw>
  lapicw(ICRHI, 0);
80102348:	ba 00 00 00 00       	mov    $0x0,%edx
8010234d:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102352:	e8 ba fe ff ff       	call   80102211 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102357:	ba 00 85 08 00       	mov    $0x88500,%edx
8010235c:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102361:	e8 ab fe ff ff       	call   80102211 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102366:	a1 9c 16 11 80       	mov    0x8011169c,%eax
8010236b:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102371:	f6 c4 10             	test   $0x10,%ah
80102374:	75 f0                	jne    80102366 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102376:	ba 00 00 00 00       	mov    $0x0,%edx
8010237b:	b8 20 00 00 00       	mov    $0x20,%eax
80102380:	e8 8c fe ff ff       	call   80102211 <lapicw>
}
80102385:	5d                   	pop    %ebp
80102386:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102387:	ba 00 00 01 00       	mov    $0x10000,%edx
8010238c:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102391:	e8 7b fe ff ff       	call   80102211 <lapicw>
80102396:	e9 71 ff ff ff       	jmp    8010230c <lapicinit+0x79>
8010239b:	f3 c3                	repz ret 

8010239d <lapicid>:
{
8010239d:	55                   	push   %ebp
8010239e:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801023a0:	a1 9c 16 11 80       	mov    0x8011169c,%eax
801023a5:	85 c0                	test   %eax,%eax
801023a7:	74 08                	je     801023b1 <lapicid+0x14>
  return lapic[ID] >> 24;
801023a9:	8b 40 20             	mov    0x20(%eax),%eax
801023ac:	c1 e8 18             	shr    $0x18,%eax
}
801023af:	5d                   	pop    %ebp
801023b0:	c3                   	ret    
    return 0;
801023b1:	b8 00 00 00 00       	mov    $0x0,%eax
801023b6:	eb f7                	jmp    801023af <lapicid+0x12>

801023b8 <lapiceoi>:
  if(lapic)
801023b8:	83 3d 9c 16 11 80 00 	cmpl   $0x0,0x8011169c
801023bf:	74 14                	je     801023d5 <lapiceoi+0x1d>
{
801023c1:	55                   	push   %ebp
801023c2:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801023c4:	ba 00 00 00 00       	mov    $0x0,%edx
801023c9:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023ce:	e8 3e fe ff ff       	call   80102211 <lapicw>
}
801023d3:	5d                   	pop    %ebp
801023d4:	c3                   	ret    
801023d5:	f3 c3                	repz ret 

801023d7 <microdelay>:
{
801023d7:	55                   	push   %ebp
801023d8:	89 e5                	mov    %esp,%ebp
}
801023da:	5d                   	pop    %ebp
801023db:	c3                   	ret    

801023dc <lapicstartap>:
{
801023dc:	55                   	push   %ebp
801023dd:	89 e5                	mov    %esp,%ebp
801023df:	57                   	push   %edi
801023e0:	56                   	push   %esi
801023e1:	53                   	push   %ebx
801023e2:	8b 75 08             	mov    0x8(%ebp),%esi
801023e5:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801023e8:	b8 0f 00 00 00       	mov    $0xf,%eax
801023ed:	ba 70 00 00 00       	mov    $0x70,%edx
801023f2:	ee                   	out    %al,(%dx)
801023f3:	b8 0a 00 00 00       	mov    $0xa,%eax
801023f8:	ba 71 00 00 00       	mov    $0x71,%edx
801023fd:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801023fe:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102405:	00 00 
  wrv[1] = addr >> 4;
80102407:	89 f8                	mov    %edi,%eax
80102409:	c1 e8 04             	shr    $0x4,%eax
8010240c:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102412:	c1 e6 18             	shl    $0x18,%esi
80102415:	89 f2                	mov    %esi,%edx
80102417:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010241c:	e8 f0 fd ff ff       	call   80102211 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102421:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102426:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010242b:	e8 e1 fd ff ff       	call   80102211 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102430:	ba 00 85 00 00       	mov    $0x8500,%edx
80102435:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010243a:	e8 d2 fd ff ff       	call   80102211 <lapicw>
  for(i = 0; i < 2; i++){
8010243f:	bb 00 00 00 00       	mov    $0x0,%ebx
80102444:	eb 21                	jmp    80102467 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102446:	89 f2                	mov    %esi,%edx
80102448:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010244d:	e8 bf fd ff ff       	call   80102211 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102452:	89 fa                	mov    %edi,%edx
80102454:	c1 ea 0c             	shr    $0xc,%edx
80102457:	80 ce 06             	or     $0x6,%dh
8010245a:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010245f:	e8 ad fd ff ff       	call   80102211 <lapicw>
  for(i = 0; i < 2; i++){
80102464:	83 c3 01             	add    $0x1,%ebx
80102467:	83 fb 01             	cmp    $0x1,%ebx
8010246a:	7e da                	jle    80102446 <lapicstartap+0x6a>
}
8010246c:	5b                   	pop    %ebx
8010246d:	5e                   	pop    %esi
8010246e:	5f                   	pop    %edi
8010246f:	5d                   	pop    %ebp
80102470:	c3                   	ret    

80102471 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102471:	55                   	push   %ebp
80102472:	89 e5                	mov    %esp,%ebp
80102474:	57                   	push   %edi
80102475:	56                   	push   %esi
80102476:	53                   	push   %ebx
80102477:	83 ec 3c             	sub    $0x3c,%esp
8010247a:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010247d:	b8 0b 00 00 00       	mov    $0xb,%eax
80102482:	e8 a2 fd ff ff       	call   80102229 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102487:	83 e0 04             	and    $0x4,%eax
8010248a:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010248c:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010248f:	e8 a9 fd ff ff       	call   8010223d <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102494:	b8 0a 00 00 00       	mov    $0xa,%eax
80102499:	e8 8b fd ff ff       	call   80102229 <cmos_read>
8010249e:	a8 80                	test   $0x80,%al
801024a0:	75 ea                	jne    8010248c <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801024a2:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801024a5:	89 d8                	mov    %ebx,%eax
801024a7:	e8 91 fd ff ff       	call   8010223d <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801024ac:	83 ec 04             	sub    $0x4,%esp
801024af:	6a 18                	push   $0x18
801024b1:	53                   	push   %ebx
801024b2:	8d 45 d0             	lea    -0x30(%ebp),%eax
801024b5:	50                   	push   %eax
801024b6:	e8 eb 17 00 00       	call   80103ca6 <memcmp>
801024bb:	83 c4 10             	add    $0x10,%esp
801024be:	85 c0                	test   %eax,%eax
801024c0:	75 ca                	jne    8010248c <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801024c2:	85 ff                	test   %edi,%edi
801024c4:	0f 85 84 00 00 00    	jne    8010254e <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801024ca:	8b 55 d0             	mov    -0x30(%ebp),%edx
801024cd:	89 d0                	mov    %edx,%eax
801024cf:	c1 e8 04             	shr    $0x4,%eax
801024d2:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024d5:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024d8:	83 e2 0f             	and    $0xf,%edx
801024db:	01 d0                	add    %edx,%eax
801024dd:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801024e0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801024e3:	89 d0                	mov    %edx,%eax
801024e5:	c1 e8 04             	shr    $0x4,%eax
801024e8:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024eb:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024ee:	83 e2 0f             	and    $0xf,%edx
801024f1:	01 d0                	add    %edx,%eax
801024f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801024f6:	8b 55 d8             	mov    -0x28(%ebp),%edx
801024f9:	89 d0                	mov    %edx,%eax
801024fb:	c1 e8 04             	shr    $0x4,%eax
801024fe:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102501:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102504:	83 e2 0f             	and    $0xf,%edx
80102507:	01 d0                	add    %edx,%eax
80102509:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010250c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010250f:	89 d0                	mov    %edx,%eax
80102511:	c1 e8 04             	shr    $0x4,%eax
80102514:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102517:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010251a:	83 e2 0f             	and    $0xf,%edx
8010251d:	01 d0                	add    %edx,%eax
8010251f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102522:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102525:	89 d0                	mov    %edx,%eax
80102527:	c1 e8 04             	shr    $0x4,%eax
8010252a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010252d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102530:	83 e2 0f             	and    $0xf,%edx
80102533:	01 d0                	add    %edx,%eax
80102535:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102538:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010253b:	89 d0                	mov    %edx,%eax
8010253d:	c1 e8 04             	shr    $0x4,%eax
80102540:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102543:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102546:	83 e2 0f             	and    $0xf,%edx
80102549:	01 d0                	add    %edx,%eax
8010254b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010254e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102551:	89 06                	mov    %eax,(%esi)
80102553:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102556:	89 46 04             	mov    %eax,0x4(%esi)
80102559:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010255c:	89 46 08             	mov    %eax,0x8(%esi)
8010255f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102562:	89 46 0c             	mov    %eax,0xc(%esi)
80102565:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102568:	89 46 10             	mov    %eax,0x10(%esi)
8010256b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010256e:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102571:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102578:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010257b:	5b                   	pop    %ebx
8010257c:	5e                   	pop    %esi
8010257d:	5f                   	pop    %edi
8010257e:	5d                   	pop    %ebp
8010257f:	c3                   	ret    

80102580 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102580:	55                   	push   %ebp
80102581:	89 e5                	mov    %esp,%ebp
80102583:	53                   	push   %ebx
80102584:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102587:	ff 35 d4 16 11 80    	pushl  0x801116d4
8010258d:	ff 35 e4 16 11 80    	pushl  0x801116e4
80102593:	e8 d4 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102598:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010259b:	89 1d e8 16 11 80    	mov    %ebx,0x801116e8
  for (i = 0; i < log.lh.n; i++) {
801025a1:	83 c4 10             	add    $0x10,%esp
801025a4:	ba 00 00 00 00       	mov    $0x0,%edx
801025a9:	eb 0e                	jmp    801025b9 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801025ab:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801025af:	89 0c 95 ec 16 11 80 	mov    %ecx,-0x7feee914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801025b6:	83 c2 01             	add    $0x1,%edx
801025b9:	39 d3                	cmp    %edx,%ebx
801025bb:	7f ee                	jg     801025ab <read_head+0x2b>
  }
  brelse(buf);
801025bd:	83 ec 0c             	sub    $0xc,%esp
801025c0:	50                   	push   %eax
801025c1:	e8 0f dc ff ff       	call   801001d5 <brelse>
}
801025c6:	83 c4 10             	add    $0x10,%esp
801025c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801025cc:	c9                   	leave  
801025cd:	c3                   	ret    

801025ce <install_trans>:
{
801025ce:	55                   	push   %ebp
801025cf:	89 e5                	mov    %esp,%ebp
801025d1:	57                   	push   %edi
801025d2:	56                   	push   %esi
801025d3:	53                   	push   %ebx
801025d4:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801025d7:	bb 00 00 00 00       	mov    $0x0,%ebx
801025dc:	eb 66                	jmp    80102644 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801025de:	89 d8                	mov    %ebx,%eax
801025e0:	03 05 d4 16 11 80    	add    0x801116d4,%eax
801025e6:	83 c0 01             	add    $0x1,%eax
801025e9:	83 ec 08             	sub    $0x8,%esp
801025ec:	50                   	push   %eax
801025ed:	ff 35 e4 16 11 80    	pushl  0x801116e4
801025f3:	e8 74 db ff ff       	call   8010016c <bread>
801025f8:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801025fa:	83 c4 08             	add    $0x8,%esp
801025fd:	ff 34 9d ec 16 11 80 	pushl  -0x7feee914(,%ebx,4)
80102604:	ff 35 e4 16 11 80    	pushl  0x801116e4
8010260a:	e8 5d db ff ff       	call   8010016c <bread>
8010260f:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102611:	8d 57 5c             	lea    0x5c(%edi),%edx
80102614:	8d 40 5c             	lea    0x5c(%eax),%eax
80102617:	83 c4 0c             	add    $0xc,%esp
8010261a:	68 00 02 00 00       	push   $0x200
8010261f:	52                   	push   %edx
80102620:	50                   	push   %eax
80102621:	e8 b5 16 00 00       	call   80103cdb <memmove>
    bwrite(dbuf);  // write dst to disk
80102626:	89 34 24             	mov    %esi,(%esp)
80102629:	e8 6c db ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010262e:	89 3c 24             	mov    %edi,(%esp)
80102631:	e8 9f db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102636:	89 34 24             	mov    %esi,(%esp)
80102639:	e8 97 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010263e:	83 c3 01             	add    $0x1,%ebx
80102641:	83 c4 10             	add    $0x10,%esp
80102644:	39 1d e8 16 11 80    	cmp    %ebx,0x801116e8
8010264a:	7f 92                	jg     801025de <install_trans+0x10>
}
8010264c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010264f:	5b                   	pop    %ebx
80102650:	5e                   	pop    %esi
80102651:	5f                   	pop    %edi
80102652:	5d                   	pop    %ebp
80102653:	c3                   	ret    

80102654 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102654:	55                   	push   %ebp
80102655:	89 e5                	mov    %esp,%ebp
80102657:	53                   	push   %ebx
80102658:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010265b:	ff 35 d4 16 11 80    	pushl  0x801116d4
80102661:	ff 35 e4 16 11 80    	pushl  0x801116e4
80102667:	e8 00 db ff ff       	call   8010016c <bread>
8010266c:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010266e:	8b 0d e8 16 11 80    	mov    0x801116e8,%ecx
80102674:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102677:	83 c4 10             	add    $0x10,%esp
8010267a:	b8 00 00 00 00       	mov    $0x0,%eax
8010267f:	eb 0e                	jmp    8010268f <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102681:	8b 14 85 ec 16 11 80 	mov    -0x7feee914(,%eax,4),%edx
80102688:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010268c:	83 c0 01             	add    $0x1,%eax
8010268f:	39 c1                	cmp    %eax,%ecx
80102691:	7f ee                	jg     80102681 <write_head+0x2d>
  }
  bwrite(buf);
80102693:	83 ec 0c             	sub    $0xc,%esp
80102696:	53                   	push   %ebx
80102697:	e8 fe da ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010269c:	89 1c 24             	mov    %ebx,(%esp)
8010269f:	e8 31 db ff ff       	call   801001d5 <brelse>
}
801026a4:	83 c4 10             	add    $0x10,%esp
801026a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026aa:	c9                   	leave  
801026ab:	c3                   	ret    

801026ac <recover_from_log>:

static void
recover_from_log(void)
{
801026ac:	55                   	push   %ebp
801026ad:	89 e5                	mov    %esp,%ebp
801026af:	83 ec 08             	sub    $0x8,%esp
  read_head();
801026b2:	e8 c9 fe ff ff       	call   80102580 <read_head>
  install_trans(); // if committed, copy from log to disk
801026b7:	e8 12 ff ff ff       	call   801025ce <install_trans>
  log.lh.n = 0;
801026bc:	c7 05 e8 16 11 80 00 	movl   $0x0,0x801116e8
801026c3:	00 00 00 
  write_head(); // clear the log
801026c6:	e8 89 ff ff ff       	call   80102654 <write_head>
}
801026cb:	c9                   	leave  
801026cc:	c3                   	ret    

801026cd <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801026cd:	55                   	push   %ebp
801026ce:	89 e5                	mov    %esp,%ebp
801026d0:	57                   	push   %edi
801026d1:	56                   	push   %esi
801026d2:	53                   	push   %ebx
801026d3:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801026d6:	bb 00 00 00 00       	mov    $0x0,%ebx
801026db:	eb 66                	jmp    80102743 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801026dd:	89 d8                	mov    %ebx,%eax
801026df:	03 05 d4 16 11 80    	add    0x801116d4,%eax
801026e5:	83 c0 01             	add    $0x1,%eax
801026e8:	83 ec 08             	sub    $0x8,%esp
801026eb:	50                   	push   %eax
801026ec:	ff 35 e4 16 11 80    	pushl  0x801116e4
801026f2:	e8 75 da ff ff       	call   8010016c <bread>
801026f7:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801026f9:	83 c4 08             	add    $0x8,%esp
801026fc:	ff 34 9d ec 16 11 80 	pushl  -0x7feee914(,%ebx,4)
80102703:	ff 35 e4 16 11 80    	pushl  0x801116e4
80102709:	e8 5e da ff ff       	call   8010016c <bread>
8010270e:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102710:	8d 50 5c             	lea    0x5c(%eax),%edx
80102713:	8d 46 5c             	lea    0x5c(%esi),%eax
80102716:	83 c4 0c             	add    $0xc,%esp
80102719:	68 00 02 00 00       	push   $0x200
8010271e:	52                   	push   %edx
8010271f:	50                   	push   %eax
80102720:	e8 b6 15 00 00       	call   80103cdb <memmove>
    bwrite(to);  // write the log
80102725:	89 34 24             	mov    %esi,(%esp)
80102728:	e8 6d da ff ff       	call   8010019a <bwrite>
    brelse(from);
8010272d:	89 3c 24             	mov    %edi,(%esp)
80102730:	e8 a0 da ff ff       	call   801001d5 <brelse>
    brelse(to);
80102735:	89 34 24             	mov    %esi,(%esp)
80102738:	e8 98 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010273d:	83 c3 01             	add    $0x1,%ebx
80102740:	83 c4 10             	add    $0x10,%esp
80102743:	39 1d e8 16 11 80    	cmp    %ebx,0x801116e8
80102749:	7f 92                	jg     801026dd <write_log+0x10>
  }
}
8010274b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010274e:	5b                   	pop    %ebx
8010274f:	5e                   	pop    %esi
80102750:	5f                   	pop    %edi
80102751:	5d                   	pop    %ebp
80102752:	c3                   	ret    

80102753 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102753:	83 3d e8 16 11 80 00 	cmpl   $0x0,0x801116e8
8010275a:	7e 26                	jle    80102782 <commit+0x2f>
{
8010275c:	55                   	push   %ebp
8010275d:	89 e5                	mov    %esp,%ebp
8010275f:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102762:	e8 66 ff ff ff       	call   801026cd <write_log>
    write_head();    // Write header to disk -- the real commit
80102767:	e8 e8 fe ff ff       	call   80102654 <write_head>
    install_trans(); // Now install writes to home locations
8010276c:	e8 5d fe ff ff       	call   801025ce <install_trans>
    log.lh.n = 0;
80102771:	c7 05 e8 16 11 80 00 	movl   $0x0,0x801116e8
80102778:	00 00 00 
    write_head();    // Erase the transaction from the log
8010277b:	e8 d4 fe ff ff       	call   80102654 <write_head>
  }
}
80102780:	c9                   	leave  
80102781:	c3                   	ret    
80102782:	f3 c3                	repz ret 

80102784 <initlog>:
{
80102784:	55                   	push   %ebp
80102785:	89 e5                	mov    %esp,%ebp
80102787:	53                   	push   %ebx
80102788:	83 ec 2c             	sub    $0x2c,%esp
8010278b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010278e:	68 e0 68 10 80       	push   $0x801068e0
80102793:	68 a0 16 11 80       	push   $0x801116a0
80102798:	e8 db 12 00 00       	call   80103a78 <initlock>
  readsb(dev, &sb);
8010279d:	83 c4 08             	add    $0x8,%esp
801027a0:	8d 45 dc             	lea    -0x24(%ebp),%eax
801027a3:	50                   	push   %eax
801027a4:	53                   	push   %ebx
801027a5:	e8 8c ea ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801027aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801027ad:	a3 d4 16 11 80       	mov    %eax,0x801116d4
  log.size = sb.nlog;
801027b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801027b5:	a3 d8 16 11 80       	mov    %eax,0x801116d8
  log.dev = dev;
801027ba:	89 1d e4 16 11 80    	mov    %ebx,0x801116e4
  recover_from_log();
801027c0:	e8 e7 fe ff ff       	call   801026ac <recover_from_log>
}
801027c5:	83 c4 10             	add    $0x10,%esp
801027c8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027cb:	c9                   	leave  
801027cc:	c3                   	ret    

801027cd <begin_op>:
{
801027cd:	55                   	push   %ebp
801027ce:	89 e5                	mov    %esp,%ebp
801027d0:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801027d3:	68 a0 16 11 80       	push   $0x801116a0
801027d8:	e8 d7 13 00 00       	call   80103bb4 <acquire>
801027dd:	83 c4 10             	add    $0x10,%esp
801027e0:	eb 15                	jmp    801027f7 <begin_op+0x2a>
      sleep(&log, &log.lock);
801027e2:	83 ec 08             	sub    $0x8,%esp
801027e5:	68 a0 16 11 80       	push   $0x801116a0
801027ea:	68 a0 16 11 80       	push   $0x801116a0
801027ef:	e8 c5 0e 00 00       	call   801036b9 <sleep>
801027f4:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801027f7:	83 3d e0 16 11 80 00 	cmpl   $0x0,0x801116e0
801027fe:	75 e2                	jne    801027e2 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102800:	a1 dc 16 11 80       	mov    0x801116dc,%eax
80102805:	83 c0 01             	add    $0x1,%eax
80102808:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010280b:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
8010280e:	03 15 e8 16 11 80    	add    0x801116e8,%edx
80102814:	83 fa 1e             	cmp    $0x1e,%edx
80102817:	7e 17                	jle    80102830 <begin_op+0x63>
      sleep(&log, &log.lock);
80102819:	83 ec 08             	sub    $0x8,%esp
8010281c:	68 a0 16 11 80       	push   $0x801116a0
80102821:	68 a0 16 11 80       	push   $0x801116a0
80102826:	e8 8e 0e 00 00       	call   801036b9 <sleep>
8010282b:	83 c4 10             	add    $0x10,%esp
8010282e:	eb c7                	jmp    801027f7 <begin_op+0x2a>
      log.outstanding += 1;
80102830:	a3 dc 16 11 80       	mov    %eax,0x801116dc
      release(&log.lock);
80102835:	83 ec 0c             	sub    $0xc,%esp
80102838:	68 a0 16 11 80       	push   $0x801116a0
8010283d:	e8 d7 13 00 00       	call   80103c19 <release>
}
80102842:	83 c4 10             	add    $0x10,%esp
80102845:	c9                   	leave  
80102846:	c3                   	ret    

80102847 <end_op>:
{
80102847:	55                   	push   %ebp
80102848:	89 e5                	mov    %esp,%ebp
8010284a:	53                   	push   %ebx
8010284b:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
8010284e:	68 a0 16 11 80       	push   $0x801116a0
80102853:	e8 5c 13 00 00       	call   80103bb4 <acquire>
  log.outstanding -= 1;
80102858:	a1 dc 16 11 80       	mov    0x801116dc,%eax
8010285d:	83 e8 01             	sub    $0x1,%eax
80102860:	a3 dc 16 11 80       	mov    %eax,0x801116dc
  if(log.committing)
80102865:	8b 1d e0 16 11 80    	mov    0x801116e0,%ebx
8010286b:	83 c4 10             	add    $0x10,%esp
8010286e:	85 db                	test   %ebx,%ebx
80102870:	75 2c                	jne    8010289e <end_op+0x57>
  if(log.outstanding == 0){
80102872:	85 c0                	test   %eax,%eax
80102874:	75 35                	jne    801028ab <end_op+0x64>
    log.committing = 1;
80102876:	c7 05 e0 16 11 80 01 	movl   $0x1,0x801116e0
8010287d:	00 00 00 
    do_commit = 1;
80102880:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102885:	83 ec 0c             	sub    $0xc,%esp
80102888:	68 a0 16 11 80       	push   $0x801116a0
8010288d:	e8 87 13 00 00       	call   80103c19 <release>
  if(do_commit){
80102892:	83 c4 10             	add    $0x10,%esp
80102895:	85 db                	test   %ebx,%ebx
80102897:	75 24                	jne    801028bd <end_op+0x76>
}
80102899:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010289c:	c9                   	leave  
8010289d:	c3                   	ret    
    panic("log.committing");
8010289e:	83 ec 0c             	sub    $0xc,%esp
801028a1:	68 e4 68 10 80       	push   $0x801068e4
801028a6:	e8 9d da ff ff       	call   80100348 <panic>
    wakeup(&log);
801028ab:	83 ec 0c             	sub    $0xc,%esp
801028ae:	68 a0 16 11 80       	push   $0x801116a0
801028b3:	e8 66 0f 00 00       	call   8010381e <wakeup>
801028b8:	83 c4 10             	add    $0x10,%esp
801028bb:	eb c8                	jmp    80102885 <end_op+0x3e>
    commit();
801028bd:	e8 91 fe ff ff       	call   80102753 <commit>
    acquire(&log.lock);
801028c2:	83 ec 0c             	sub    $0xc,%esp
801028c5:	68 a0 16 11 80       	push   $0x801116a0
801028ca:	e8 e5 12 00 00       	call   80103bb4 <acquire>
    log.committing = 0;
801028cf:	c7 05 e0 16 11 80 00 	movl   $0x0,0x801116e0
801028d6:	00 00 00 
    wakeup(&log);
801028d9:	c7 04 24 a0 16 11 80 	movl   $0x801116a0,(%esp)
801028e0:	e8 39 0f 00 00       	call   8010381e <wakeup>
    release(&log.lock);
801028e5:	c7 04 24 a0 16 11 80 	movl   $0x801116a0,(%esp)
801028ec:	e8 28 13 00 00       	call   80103c19 <release>
801028f1:	83 c4 10             	add    $0x10,%esp
}
801028f4:	eb a3                	jmp    80102899 <end_op+0x52>

801028f6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801028f6:	55                   	push   %ebp
801028f7:	89 e5                	mov    %esp,%ebp
801028f9:	53                   	push   %ebx
801028fa:	83 ec 04             	sub    $0x4,%esp
801028fd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102900:	8b 15 e8 16 11 80    	mov    0x801116e8,%edx
80102906:	83 fa 1d             	cmp    $0x1d,%edx
80102909:	7f 45                	jg     80102950 <log_write+0x5a>
8010290b:	a1 d8 16 11 80       	mov    0x801116d8,%eax
80102910:	83 e8 01             	sub    $0x1,%eax
80102913:	39 c2                	cmp    %eax,%edx
80102915:	7d 39                	jge    80102950 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102917:	83 3d dc 16 11 80 00 	cmpl   $0x0,0x801116dc
8010291e:	7e 3d                	jle    8010295d <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102920:	83 ec 0c             	sub    $0xc,%esp
80102923:	68 a0 16 11 80       	push   $0x801116a0
80102928:	e8 87 12 00 00       	call   80103bb4 <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010292d:	83 c4 10             	add    $0x10,%esp
80102930:	b8 00 00 00 00       	mov    $0x0,%eax
80102935:	8b 15 e8 16 11 80    	mov    0x801116e8,%edx
8010293b:	39 c2                	cmp    %eax,%edx
8010293d:	7e 2b                	jle    8010296a <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
8010293f:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102942:	39 0c 85 ec 16 11 80 	cmp    %ecx,-0x7feee914(,%eax,4)
80102949:	74 1f                	je     8010296a <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
8010294b:	83 c0 01             	add    $0x1,%eax
8010294e:	eb e5                	jmp    80102935 <log_write+0x3f>
    panic("too big a transaction");
80102950:	83 ec 0c             	sub    $0xc,%esp
80102953:	68 f3 68 10 80       	push   $0x801068f3
80102958:	e8 eb d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
8010295d:	83 ec 0c             	sub    $0xc,%esp
80102960:	68 09 69 10 80       	push   $0x80106909
80102965:	e8 de d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
8010296a:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010296d:	89 0c 85 ec 16 11 80 	mov    %ecx,-0x7feee914(,%eax,4)
  if (i == log.lh.n)
80102974:	39 c2                	cmp    %eax,%edx
80102976:	74 18                	je     80102990 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102978:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
8010297b:	83 ec 0c             	sub    $0xc,%esp
8010297e:	68 a0 16 11 80       	push   $0x801116a0
80102983:	e8 91 12 00 00       	call   80103c19 <release>
}
80102988:	83 c4 10             	add    $0x10,%esp
8010298b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010298e:	c9                   	leave  
8010298f:	c3                   	ret    
    log.lh.n++;
80102990:	83 c2 01             	add    $0x1,%edx
80102993:	89 15 e8 16 11 80    	mov    %edx,0x801116e8
80102999:	eb dd                	jmp    80102978 <log_write+0x82>

8010299b <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010299b:	55                   	push   %ebp
8010299c:	89 e5                	mov    %esp,%ebp
8010299e:	53                   	push   %ebx
8010299f:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801029a2:	68 8a 00 00 00       	push   $0x8a
801029a7:	68 8c 94 10 80       	push   $0x8010948c
801029ac:	68 00 70 00 80       	push   $0x80007000
801029b1:	e8 25 13 00 00       	call   80103cdb <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801029b6:	83 c4 10             	add    $0x10,%esp
801029b9:	bb a0 17 11 80       	mov    $0x801117a0,%ebx
801029be:	eb 06                	jmp    801029c6 <startothers+0x2b>
801029c0:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
801029c6:	69 05 20 1d 11 80 b0 	imul   $0xb0,0x80111d20,%eax
801029cd:	00 00 00 
801029d0:	05 a0 17 11 80       	add    $0x801117a0,%eax
801029d5:	39 d8                	cmp    %ebx,%eax
801029d7:	76 4c                	jbe    80102a25 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
801029d9:	e8 c0 07 00 00       	call   8010319e <mycpu>
801029de:	39 d8                	cmp    %ebx,%eax
801029e0:	74 de                	je     801029c0 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801029e2:	e8 f3 f6 ff ff       	call   801020da <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
801029e7:	05 00 10 00 00       	add    $0x1000,%eax
801029ec:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
801029f1:	c7 05 f8 6f 00 80 69 	movl   $0x80102a69,0x80006ff8
801029f8:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801029fb:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102a02:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102a05:	83 ec 08             	sub    $0x8,%esp
80102a08:	68 00 70 00 00       	push   $0x7000
80102a0d:	0f b6 03             	movzbl (%ebx),%eax
80102a10:	50                   	push   %eax
80102a11:	e8 c6 f9 ff ff       	call   801023dc <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102a16:	83 c4 10             	add    $0x10,%esp
80102a19:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102a1f:	85 c0                	test   %eax,%eax
80102a21:	74 f6                	je     80102a19 <startothers+0x7e>
80102a23:	eb 9b                	jmp    801029c0 <startothers+0x25>
      ;
  }
}
80102a25:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a28:	c9                   	leave  
80102a29:	c3                   	ret    

80102a2a <mpmain>:
{
80102a2a:	55                   	push   %ebp
80102a2b:	89 e5                	mov    %esp,%ebp
80102a2d:	53                   	push   %ebx
80102a2e:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102a31:	e8 c4 07 00 00       	call   801031fa <cpuid>
80102a36:	89 c3                	mov    %eax,%ebx
80102a38:	e8 bd 07 00 00       	call   801031fa <cpuid>
80102a3d:	83 ec 04             	sub    $0x4,%esp
80102a40:	53                   	push   %ebx
80102a41:	50                   	push   %eax
80102a42:	68 24 69 10 80       	push   $0x80106924
80102a47:	e8 bf db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102a4c:	e8 7a 23 00 00       	call   80104dcb <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102a51:	e8 48 07 00 00       	call   8010319e <mycpu>
80102a56:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102a58:	b8 01 00 00 00       	mov    $0x1,%eax
80102a5d:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102a64:	e8 2b 0a 00 00       	call   80103494 <scheduler>

80102a69 <mpenter>:
{
80102a69:	55                   	push   %ebp
80102a6a:	89 e5                	mov    %esp,%ebp
80102a6c:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102a6f:	e8 60 33 00 00       	call   80105dd4 <switchkvm>
  seginit();
80102a74:	e8 0f 32 00 00       	call   80105c88 <seginit>
  lapicinit();
80102a79:	e8 15 f8 ff ff       	call   80102293 <lapicinit>
  mpmain();
80102a7e:	e8 a7 ff ff ff       	call   80102a2a <mpmain>

80102a83 <main>:
{
80102a83:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102a87:	83 e4 f0             	and    $0xfffffff0,%esp
80102a8a:	ff 71 fc             	pushl  -0x4(%ecx)
80102a8d:	55                   	push   %ebp
80102a8e:	89 e5                	mov    %esp,%ebp
80102a90:	51                   	push   %ecx
80102a91:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102a94:	68 00 00 40 80       	push   $0x80400000
80102a99:	68 c8 44 11 80       	push   $0x801144c8
80102a9e:	e8 e5 f5 ff ff       	call   80102088 <kinit1>
  kvmalloc();      // kernel page table
80102aa3:	e8 b9 37 00 00       	call   80106261 <kvmalloc>
  mpinit();        // detect other processors
80102aa8:	e8 c9 01 00 00       	call   80102c76 <mpinit>
  lapicinit();     // interrupt controller
80102aad:	e8 e1 f7 ff ff       	call   80102293 <lapicinit>
  seginit();       // segment descriptors
80102ab2:	e8 d1 31 00 00       	call   80105c88 <seginit>
  picinit();       // disable pic
80102ab7:	e8 82 02 00 00       	call   80102d3e <picinit>
  ioapicinit();    // another interrupt controller
80102abc:	e8 39 f4 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102ac1:	e8 c8 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102ac6:	e8 ae 25 00 00       	call   80105079 <uartinit>
  pinit();         // process table
80102acb:	e8 b4 06 00 00       	call   80103184 <pinit>
  tvinit();        // trap vectors
80102ad0:	e8 45 22 00 00       	call   80104d1a <tvinit>
  binit();         // buffer cache
80102ad5:	e8 1a d6 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102ada:	e8 34 e1 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102adf:	e8 1c f2 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102ae4:	e8 b2 fe ff ff       	call   8010299b <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102ae9:	83 c4 08             	add    $0x8,%esp
80102aec:	68 00 00 00 8e       	push   $0x8e000000
80102af1:	68 00 00 40 80       	push   $0x80400000
80102af6:	e8 bf f5 ff ff       	call   801020ba <kinit2>
  userinit();      // first user process
80102afb:	e8 39 07 00 00       	call   80103239 <userinit>
  mpmain();        // finish this processor's setup
80102b00:	e8 25 ff ff ff       	call   80102a2a <mpmain>

80102b05 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102b05:	55                   	push   %ebp
80102b06:	89 e5                	mov    %esp,%ebp
80102b08:	56                   	push   %esi
80102b09:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102b0a:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102b0f:	b9 00 00 00 00       	mov    $0x0,%ecx
80102b14:	eb 09                	jmp    80102b1f <sum+0x1a>
    sum += addr[i];
80102b16:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102b1a:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102b1c:	83 c1 01             	add    $0x1,%ecx
80102b1f:	39 d1                	cmp    %edx,%ecx
80102b21:	7c f3                	jl     80102b16 <sum+0x11>
  return sum;
}
80102b23:	89 d8                	mov    %ebx,%eax
80102b25:	5b                   	pop    %ebx
80102b26:	5e                   	pop    %esi
80102b27:	5d                   	pop    %ebp
80102b28:	c3                   	ret    

80102b29 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102b29:	55                   	push   %ebp
80102b2a:	89 e5                	mov    %esp,%ebp
80102b2c:	56                   	push   %esi
80102b2d:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102b2e:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102b34:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102b36:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102b38:	eb 03                	jmp    80102b3d <mpsearch1+0x14>
80102b3a:	83 c3 10             	add    $0x10,%ebx
80102b3d:	39 f3                	cmp    %esi,%ebx
80102b3f:	73 29                	jae    80102b6a <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102b41:	83 ec 04             	sub    $0x4,%esp
80102b44:	6a 04                	push   $0x4
80102b46:	68 38 69 10 80       	push   $0x80106938
80102b4b:	53                   	push   %ebx
80102b4c:	e8 55 11 00 00       	call   80103ca6 <memcmp>
80102b51:	83 c4 10             	add    $0x10,%esp
80102b54:	85 c0                	test   %eax,%eax
80102b56:	75 e2                	jne    80102b3a <mpsearch1+0x11>
80102b58:	ba 10 00 00 00       	mov    $0x10,%edx
80102b5d:	89 d8                	mov    %ebx,%eax
80102b5f:	e8 a1 ff ff ff       	call   80102b05 <sum>
80102b64:	84 c0                	test   %al,%al
80102b66:	75 d2                	jne    80102b3a <mpsearch1+0x11>
80102b68:	eb 05                	jmp    80102b6f <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102b6a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102b6f:	89 d8                	mov    %ebx,%eax
80102b71:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102b74:	5b                   	pop    %ebx
80102b75:	5e                   	pop    %esi
80102b76:	5d                   	pop    %ebp
80102b77:	c3                   	ret    

80102b78 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102b78:	55                   	push   %ebp
80102b79:	89 e5                	mov    %esp,%ebp
80102b7b:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102b7e:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102b85:	c1 e0 08             	shl    $0x8,%eax
80102b88:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102b8f:	09 d0                	or     %edx,%eax
80102b91:	c1 e0 04             	shl    $0x4,%eax
80102b94:	85 c0                	test   %eax,%eax
80102b96:	74 1f                	je     80102bb7 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102b98:	ba 00 04 00 00       	mov    $0x400,%edx
80102b9d:	e8 87 ff ff ff       	call   80102b29 <mpsearch1>
80102ba2:	85 c0                	test   %eax,%eax
80102ba4:	75 0f                	jne    80102bb5 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102ba6:	ba 00 00 01 00       	mov    $0x10000,%edx
80102bab:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102bb0:	e8 74 ff ff ff       	call   80102b29 <mpsearch1>
}
80102bb5:	c9                   	leave  
80102bb6:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102bb7:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102bbe:	c1 e0 08             	shl    $0x8,%eax
80102bc1:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102bc8:	09 d0                	or     %edx,%eax
80102bca:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102bcd:	2d 00 04 00 00       	sub    $0x400,%eax
80102bd2:	ba 00 04 00 00       	mov    $0x400,%edx
80102bd7:	e8 4d ff ff ff       	call   80102b29 <mpsearch1>
80102bdc:	85 c0                	test   %eax,%eax
80102bde:	75 d5                	jne    80102bb5 <mpsearch+0x3d>
80102be0:	eb c4                	jmp    80102ba6 <mpsearch+0x2e>

80102be2 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102be2:	55                   	push   %ebp
80102be3:	89 e5                	mov    %esp,%ebp
80102be5:	57                   	push   %edi
80102be6:	56                   	push   %esi
80102be7:	53                   	push   %ebx
80102be8:	83 ec 1c             	sub    $0x1c,%esp
80102beb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102bee:	e8 85 ff ff ff       	call   80102b78 <mpsearch>
80102bf3:	85 c0                	test   %eax,%eax
80102bf5:	74 5c                	je     80102c53 <mpconfig+0x71>
80102bf7:	89 c7                	mov    %eax,%edi
80102bf9:	8b 58 04             	mov    0x4(%eax),%ebx
80102bfc:	85 db                	test   %ebx,%ebx
80102bfe:	74 5a                	je     80102c5a <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102c00:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102c06:	83 ec 04             	sub    $0x4,%esp
80102c09:	6a 04                	push   $0x4
80102c0b:	68 3d 69 10 80       	push   $0x8010693d
80102c10:	56                   	push   %esi
80102c11:	e8 90 10 00 00       	call   80103ca6 <memcmp>
80102c16:	83 c4 10             	add    $0x10,%esp
80102c19:	85 c0                	test   %eax,%eax
80102c1b:	75 44                	jne    80102c61 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102c1d:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102c24:	3c 01                	cmp    $0x1,%al
80102c26:	0f 95 c2             	setne  %dl
80102c29:	3c 04                	cmp    $0x4,%al
80102c2b:	0f 95 c0             	setne  %al
80102c2e:	84 c2                	test   %al,%dl
80102c30:	75 36                	jne    80102c68 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102c32:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102c39:	89 f0                	mov    %esi,%eax
80102c3b:	e8 c5 fe ff ff       	call   80102b05 <sum>
80102c40:	84 c0                	test   %al,%al
80102c42:	75 2b                	jne    80102c6f <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102c44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102c47:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102c49:	89 f0                	mov    %esi,%eax
80102c4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102c4e:	5b                   	pop    %ebx
80102c4f:	5e                   	pop    %esi
80102c50:	5f                   	pop    %edi
80102c51:	5d                   	pop    %ebp
80102c52:	c3                   	ret    
    return 0;
80102c53:	be 00 00 00 00       	mov    $0x0,%esi
80102c58:	eb ef                	jmp    80102c49 <mpconfig+0x67>
80102c5a:	be 00 00 00 00       	mov    $0x0,%esi
80102c5f:	eb e8                	jmp    80102c49 <mpconfig+0x67>
    return 0;
80102c61:	be 00 00 00 00       	mov    $0x0,%esi
80102c66:	eb e1                	jmp    80102c49 <mpconfig+0x67>
    return 0;
80102c68:	be 00 00 00 00       	mov    $0x0,%esi
80102c6d:	eb da                	jmp    80102c49 <mpconfig+0x67>
    return 0;
80102c6f:	be 00 00 00 00       	mov    $0x0,%esi
80102c74:	eb d3                	jmp    80102c49 <mpconfig+0x67>

80102c76 <mpinit>:

void
mpinit(void)
{
80102c76:	55                   	push   %ebp
80102c77:	89 e5                	mov    %esp,%ebp
80102c79:	57                   	push   %edi
80102c7a:	56                   	push   %esi
80102c7b:	53                   	push   %ebx
80102c7c:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102c7f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102c82:	e8 5b ff ff ff       	call   80102be2 <mpconfig>
80102c87:	85 c0                	test   %eax,%eax
80102c89:	74 19                	je     80102ca4 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102c8b:	8b 50 24             	mov    0x24(%eax),%edx
80102c8e:	89 15 9c 16 11 80    	mov    %edx,0x8011169c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c94:	8d 50 2c             	lea    0x2c(%eax),%edx
80102c97:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102c9b:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102c9d:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ca2:	eb 34                	jmp    80102cd8 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102ca4:	83 ec 0c             	sub    $0xc,%esp
80102ca7:	68 42 69 10 80       	push   $0x80106942
80102cac:	e8 97 d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102cb1:	8b 35 20 1d 11 80    	mov    0x80111d20,%esi
80102cb7:	83 fe 07             	cmp    $0x7,%esi
80102cba:	7f 19                	jg     80102cd5 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102cbc:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102cc0:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102cc6:	88 87 a0 17 11 80    	mov    %al,-0x7feee860(%edi)
        ncpu++;
80102ccc:	83 c6 01             	add    $0x1,%esi
80102ccf:	89 35 20 1d 11 80    	mov    %esi,0x80111d20
      }
      p += sizeof(struct mpproc);
80102cd5:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102cd8:	39 ca                	cmp    %ecx,%edx
80102cda:	73 2b                	jae    80102d07 <mpinit+0x91>
    switch(*p){
80102cdc:	0f b6 02             	movzbl (%edx),%eax
80102cdf:	3c 04                	cmp    $0x4,%al
80102ce1:	77 1d                	ja     80102d00 <mpinit+0x8a>
80102ce3:	0f b6 c0             	movzbl %al,%eax
80102ce6:	ff 24 85 7c 69 10 80 	jmp    *-0x7fef9684(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102ced:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102cf1:	a2 80 17 11 80       	mov    %al,0x80111780
      p += sizeof(struct mpioapic);
80102cf6:	83 c2 08             	add    $0x8,%edx
      continue;
80102cf9:	eb dd                	jmp    80102cd8 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102cfb:	83 c2 08             	add    $0x8,%edx
      continue;
80102cfe:	eb d8                	jmp    80102cd8 <mpinit+0x62>
    default:
      ismp = 0;
80102d00:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d05:	eb d1                	jmp    80102cd8 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102d07:	85 db                	test   %ebx,%ebx
80102d09:	74 26                	je     80102d31 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102d0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d0e:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102d12:	74 15                	je     80102d29 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d14:	b8 70 00 00 00       	mov    $0x70,%eax
80102d19:	ba 22 00 00 00       	mov    $0x22,%edx
80102d1e:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d1f:	ba 23 00 00 00       	mov    $0x23,%edx
80102d24:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102d25:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d28:	ee                   	out    %al,(%dx)
  }
}
80102d29:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d2c:	5b                   	pop    %ebx
80102d2d:	5e                   	pop    %esi
80102d2e:	5f                   	pop    %edi
80102d2f:	5d                   	pop    %ebp
80102d30:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102d31:	83 ec 0c             	sub    $0xc,%esp
80102d34:	68 5c 69 10 80       	push   $0x8010695c
80102d39:	e8 0a d6 ff ff       	call   80100348 <panic>

80102d3e <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102d3e:	55                   	push   %ebp
80102d3f:	89 e5                	mov    %esp,%ebp
80102d41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d46:	ba 21 00 00 00       	mov    $0x21,%edx
80102d4b:	ee                   	out    %al,(%dx)
80102d4c:	ba a1 00 00 00       	mov    $0xa1,%edx
80102d51:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102d52:	5d                   	pop    %ebp
80102d53:	c3                   	ret    

80102d54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102d54:	55                   	push   %ebp
80102d55:	89 e5                	mov    %esp,%ebp
80102d57:	57                   	push   %edi
80102d58:	56                   	push   %esi
80102d59:	53                   	push   %ebx
80102d5a:	83 ec 0c             	sub    $0xc,%esp
80102d5d:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102d60:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102d63:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102d69:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102d6f:	e8 b9 de ff ff       	call   80100c2d <filealloc>
80102d74:	89 03                	mov    %eax,(%ebx)
80102d76:	85 c0                	test   %eax,%eax
80102d78:	74 16                	je     80102d90 <pipealloc+0x3c>
80102d7a:	e8 ae de ff ff       	call   80100c2d <filealloc>
80102d7f:	89 06                	mov    %eax,(%esi)
80102d81:	85 c0                	test   %eax,%eax
80102d83:	74 0b                	je     80102d90 <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102d85:	e8 50 f3 ff ff       	call   801020da <kalloc>
80102d8a:	89 c7                	mov    %eax,%edi
80102d8c:	85 c0                	test   %eax,%eax
80102d8e:	75 35                	jne    80102dc5 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102d90:	8b 03                	mov    (%ebx),%eax
80102d92:	85 c0                	test   %eax,%eax
80102d94:	74 0c                	je     80102da2 <pipealloc+0x4e>
    fileclose(*f0);
80102d96:	83 ec 0c             	sub    $0xc,%esp
80102d99:	50                   	push   %eax
80102d9a:	e8 34 df ff ff       	call   80100cd3 <fileclose>
80102d9f:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102da2:	8b 06                	mov    (%esi),%eax
80102da4:	85 c0                	test   %eax,%eax
80102da6:	0f 84 8b 00 00 00    	je     80102e37 <pipealloc+0xe3>
    fileclose(*f1);
80102dac:	83 ec 0c             	sub    $0xc,%esp
80102daf:	50                   	push   %eax
80102db0:	e8 1e df ff ff       	call   80100cd3 <fileclose>
80102db5:	83 c4 10             	add    $0x10,%esp
  return -1;
80102db8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102dbd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102dc0:	5b                   	pop    %ebx
80102dc1:	5e                   	pop    %esi
80102dc2:	5f                   	pop    %edi
80102dc3:	5d                   	pop    %ebp
80102dc4:	c3                   	ret    
  p->readopen = 1;
80102dc5:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102dcc:	00 00 00 
  p->writeopen = 1;
80102dcf:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102dd6:	00 00 00 
  p->nwrite = 0;
80102dd9:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102de0:	00 00 00 
  p->nread = 0;
80102de3:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102dea:	00 00 00 
  initlock(&p->lock, "pipe");
80102ded:	83 ec 08             	sub    $0x8,%esp
80102df0:	68 90 69 10 80       	push   $0x80106990
80102df5:	50                   	push   %eax
80102df6:	e8 7d 0c 00 00       	call   80103a78 <initlock>
  (*f0)->type = FD_PIPE;
80102dfb:	8b 03                	mov    (%ebx),%eax
80102dfd:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102e03:	8b 03                	mov    (%ebx),%eax
80102e05:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102e09:	8b 03                	mov    (%ebx),%eax
80102e0b:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102e0f:	8b 03                	mov    (%ebx),%eax
80102e11:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102e14:	8b 06                	mov    (%esi),%eax
80102e16:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102e1c:	8b 06                	mov    (%esi),%eax
80102e1e:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102e22:	8b 06                	mov    (%esi),%eax
80102e24:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102e28:	8b 06                	mov    (%esi),%eax
80102e2a:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102e2d:	83 c4 10             	add    $0x10,%esp
80102e30:	b8 00 00 00 00       	mov    $0x0,%eax
80102e35:	eb 86                	jmp    80102dbd <pipealloc+0x69>
  return -1;
80102e37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e3c:	e9 7c ff ff ff       	jmp    80102dbd <pipealloc+0x69>

80102e41 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102e41:	55                   	push   %ebp
80102e42:	89 e5                	mov    %esp,%ebp
80102e44:	53                   	push   %ebx
80102e45:	83 ec 10             	sub    $0x10,%esp
80102e48:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102e4b:	53                   	push   %ebx
80102e4c:	e8 63 0d 00 00       	call   80103bb4 <acquire>
  if(writable){
80102e51:	83 c4 10             	add    $0x10,%esp
80102e54:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e58:	74 3f                	je     80102e99 <pipeclose+0x58>
    p->writeopen = 0;
80102e5a:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102e61:	00 00 00 
    wakeup(&p->nread);
80102e64:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102e6a:	83 ec 0c             	sub    $0xc,%esp
80102e6d:	50                   	push   %eax
80102e6e:	e8 ab 09 00 00       	call   8010381e <wakeup>
80102e73:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102e76:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102e7d:	75 09                	jne    80102e88 <pipeclose+0x47>
80102e7f:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102e86:	74 2f                	je     80102eb7 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102e88:	83 ec 0c             	sub    $0xc,%esp
80102e8b:	53                   	push   %ebx
80102e8c:	e8 88 0d 00 00       	call   80103c19 <release>
80102e91:	83 c4 10             	add    $0x10,%esp
}
80102e94:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102e97:	c9                   	leave  
80102e98:	c3                   	ret    
    p->readopen = 0;
80102e99:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102ea0:	00 00 00 
    wakeup(&p->nwrite);
80102ea3:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102ea9:	83 ec 0c             	sub    $0xc,%esp
80102eac:	50                   	push   %eax
80102ead:	e8 6c 09 00 00       	call   8010381e <wakeup>
80102eb2:	83 c4 10             	add    $0x10,%esp
80102eb5:	eb bf                	jmp    80102e76 <pipeclose+0x35>
    release(&p->lock);
80102eb7:	83 ec 0c             	sub    $0xc,%esp
80102eba:	53                   	push   %ebx
80102ebb:	e8 59 0d 00 00       	call   80103c19 <release>
    kfree((char*)p);
80102ec0:	89 1c 24             	mov    %ebx,(%esp)
80102ec3:	e8 dc f0 ff ff       	call   80101fa4 <kfree>
80102ec8:	83 c4 10             	add    $0x10,%esp
80102ecb:	eb c7                	jmp    80102e94 <pipeclose+0x53>

80102ecd <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102ecd:	55                   	push   %ebp
80102ece:	89 e5                	mov    %esp,%ebp
80102ed0:	57                   	push   %edi
80102ed1:	56                   	push   %esi
80102ed2:	53                   	push   %ebx
80102ed3:	83 ec 18             	sub    $0x18,%esp
80102ed6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102ed9:	89 de                	mov    %ebx,%esi
80102edb:	53                   	push   %ebx
80102edc:	e8 d3 0c 00 00       	call   80103bb4 <acquire>
  for(i = 0; i < n; i++){
80102ee1:	83 c4 10             	add    $0x10,%esp
80102ee4:	bf 00 00 00 00       	mov    $0x0,%edi
80102ee9:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102eec:	0f 8d 88 00 00 00    	jge    80102f7a <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102ef2:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102ef8:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102efe:	05 00 02 00 00       	add    $0x200,%eax
80102f03:	39 c2                	cmp    %eax,%edx
80102f05:	75 51                	jne    80102f58 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102f07:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f0e:	74 2f                	je     80102f3f <pipewrite+0x72>
80102f10:	e8 00 03 00 00       	call   80103215 <myproc>
80102f15:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f19:	75 24                	jne    80102f3f <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102f1b:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f21:	83 ec 0c             	sub    $0xc,%esp
80102f24:	50                   	push   %eax
80102f25:	e8 f4 08 00 00       	call   8010381e <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f2a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f30:	83 c4 08             	add    $0x8,%esp
80102f33:	56                   	push   %esi
80102f34:	50                   	push   %eax
80102f35:	e8 7f 07 00 00       	call   801036b9 <sleep>
80102f3a:	83 c4 10             	add    $0x10,%esp
80102f3d:	eb b3                	jmp    80102ef2 <pipewrite+0x25>
        release(&p->lock);
80102f3f:	83 ec 0c             	sub    $0xc,%esp
80102f42:	53                   	push   %ebx
80102f43:	e8 d1 0c 00 00       	call   80103c19 <release>
        return -1;
80102f48:	83 c4 10             	add    $0x10,%esp
80102f4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102f50:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f53:	5b                   	pop    %ebx
80102f54:	5e                   	pop    %esi
80102f55:	5f                   	pop    %edi
80102f56:	5d                   	pop    %ebp
80102f57:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102f58:	8d 42 01             	lea    0x1(%edx),%eax
80102f5b:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102f61:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102f67:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f6a:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102f6e:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102f72:	83 c7 01             	add    $0x1,%edi
80102f75:	e9 6f ff ff ff       	jmp    80102ee9 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102f7a:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f80:	83 ec 0c             	sub    $0xc,%esp
80102f83:	50                   	push   %eax
80102f84:	e8 95 08 00 00       	call   8010381e <wakeup>
  release(&p->lock);
80102f89:	89 1c 24             	mov    %ebx,(%esp)
80102f8c:	e8 88 0c 00 00       	call   80103c19 <release>
  return n;
80102f91:	83 c4 10             	add    $0x10,%esp
80102f94:	8b 45 10             	mov    0x10(%ebp),%eax
80102f97:	eb b7                	jmp    80102f50 <pipewrite+0x83>

80102f99 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80102f99:	55                   	push   %ebp
80102f9a:	89 e5                	mov    %esp,%ebp
80102f9c:	57                   	push   %edi
80102f9d:	56                   	push   %esi
80102f9e:	53                   	push   %ebx
80102f9f:	83 ec 18             	sub    $0x18,%esp
80102fa2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fa5:	89 df                	mov    %ebx,%edi
80102fa7:	53                   	push   %ebx
80102fa8:	e8 07 0c 00 00       	call   80103bb4 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80102fad:	83 c4 10             	add    $0x10,%esp
80102fb0:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80102fb6:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80102fbc:	75 3d                	jne    80102ffb <piperead+0x62>
80102fbe:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80102fc4:	85 f6                	test   %esi,%esi
80102fc6:	74 38                	je     80103000 <piperead+0x67>
    if(myproc()->killed){
80102fc8:	e8 48 02 00 00       	call   80103215 <myproc>
80102fcd:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fd1:	75 15                	jne    80102fe8 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80102fd3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fd9:	83 ec 08             	sub    $0x8,%esp
80102fdc:	57                   	push   %edi
80102fdd:	50                   	push   %eax
80102fde:	e8 d6 06 00 00       	call   801036b9 <sleep>
80102fe3:	83 c4 10             	add    $0x10,%esp
80102fe6:	eb c8                	jmp    80102fb0 <piperead+0x17>
      release(&p->lock);
80102fe8:	83 ec 0c             	sub    $0xc,%esp
80102feb:	53                   	push   %ebx
80102fec:	e8 28 0c 00 00       	call   80103c19 <release>
      return -1;
80102ff1:	83 c4 10             	add    $0x10,%esp
80102ff4:	be ff ff ff ff       	mov    $0xffffffff,%esi
80102ff9:	eb 50                	jmp    8010304b <piperead+0xb2>
80102ffb:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103000:	3b 75 10             	cmp    0x10(%ebp),%esi
80103003:	7d 2c                	jge    80103031 <piperead+0x98>
    if(p->nread == p->nwrite)
80103005:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010300b:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103011:	74 1e                	je     80103031 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103013:	8d 50 01             	lea    0x1(%eax),%edx
80103016:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010301c:	25 ff 01 00 00       	and    $0x1ff,%eax
80103021:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103026:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103029:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010302c:	83 c6 01             	add    $0x1,%esi
8010302f:	eb cf                	jmp    80103000 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103031:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103037:	83 ec 0c             	sub    $0xc,%esp
8010303a:	50                   	push   %eax
8010303b:	e8 de 07 00 00       	call   8010381e <wakeup>
  release(&p->lock);
80103040:	89 1c 24             	mov    %ebx,(%esp)
80103043:	e8 d1 0b 00 00       	call   80103c19 <release>
  return i;
80103048:	83 c4 10             	add    $0x10,%esp
}
8010304b:	89 f0                	mov    %esi,%eax
8010304d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103050:	5b                   	pop    %ebx
80103051:	5e                   	pop    %esi
80103052:	5f                   	pop    %edi
80103053:	5d                   	pop    %ebp
80103054:	c3                   	ret    

80103055 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103055:	55                   	push   %ebp
80103056:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103058:	ba 74 1d 11 80       	mov    $0x80111d74,%edx
8010305d:	eb 03                	jmp    80103062 <wakeup1+0xd>
8010305f:	83 c2 7c             	add    $0x7c,%edx
80103062:	81 fa 74 3c 11 80    	cmp    $0x80113c74,%edx
80103068:	73 14                	jae    8010307e <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
8010306a:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010306e:	75 ef                	jne    8010305f <wakeup1+0xa>
80103070:	39 42 20             	cmp    %eax,0x20(%edx)
80103073:	75 ea                	jne    8010305f <wakeup1+0xa>
      p->state = RUNNABLE;
80103075:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010307c:	eb e1                	jmp    8010305f <wakeup1+0xa>
}
8010307e:	5d                   	pop    %ebp
8010307f:	c3                   	ret    

80103080 <allocproc>:
{
80103080:	55                   	push   %ebp
80103081:	89 e5                	mov    %esp,%ebp
80103083:	53                   	push   %ebx
80103084:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103087:	68 40 1d 11 80       	push   $0x80111d40
8010308c:	e8 23 0b 00 00       	call   80103bb4 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103091:	83 c4 10             	add    $0x10,%esp
80103094:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103099:	81 fb 74 3c 11 80    	cmp    $0x80113c74,%ebx
8010309f:	73 0b                	jae    801030ac <allocproc+0x2c>
    if(p->state == UNUSED)
801030a1:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801030a5:	74 1c                	je     801030c3 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030a7:	83 c3 7c             	add    $0x7c,%ebx
801030aa:	eb ed                	jmp    80103099 <allocproc+0x19>
  release(&ptable.lock);
801030ac:	83 ec 0c             	sub    $0xc,%esp
801030af:	68 40 1d 11 80       	push   $0x80111d40
801030b4:	e8 60 0b 00 00       	call   80103c19 <release>
  return 0;
801030b9:	83 c4 10             	add    $0x10,%esp
801030bc:	bb 00 00 00 00       	mov    $0x0,%ebx
801030c1:	eb 69                	jmp    8010312c <allocproc+0xac>
  p->state = EMBRYO;
801030c3:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801030ca:	a1 04 90 10 80       	mov    0x80109004,%eax
801030cf:	8d 50 01             	lea    0x1(%eax),%edx
801030d2:	89 15 04 90 10 80    	mov    %edx,0x80109004
801030d8:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801030db:	83 ec 0c             	sub    $0xc,%esp
801030de:	68 40 1d 11 80       	push   $0x80111d40
801030e3:	e8 31 0b 00 00       	call   80103c19 <release>
  if((p->kstack = kalloc()) == 0){
801030e8:	e8 ed ef ff ff       	call   801020da <kalloc>
801030ed:	89 43 08             	mov    %eax,0x8(%ebx)
801030f0:	83 c4 10             	add    $0x10,%esp
801030f3:	85 c0                	test   %eax,%eax
801030f5:	74 3c                	je     80103133 <allocproc+0xb3>
  sp -= sizeof *p->tf;
801030f7:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801030fd:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103100:	c7 80 b0 0f 00 00 0f 	movl   $0x80104d0f,0xfb0(%eax)
80103107:	4d 10 80 
  sp -= sizeof *p->context;
8010310a:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
8010310f:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103112:	83 ec 04             	sub    $0x4,%esp
80103115:	6a 14                	push   $0x14
80103117:	6a 00                	push   $0x0
80103119:	50                   	push   %eax
8010311a:	e8 41 0b 00 00       	call   80103c60 <memset>
  p->context->eip = (uint)forkret;
8010311f:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103122:	c7 40 10 41 31 10 80 	movl   $0x80103141,0x10(%eax)
  return p;
80103129:	83 c4 10             	add    $0x10,%esp
}
8010312c:	89 d8                	mov    %ebx,%eax
8010312e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103131:	c9                   	leave  
80103132:	c3                   	ret    
    p->state = UNUSED;
80103133:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
8010313a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010313f:	eb eb                	jmp    8010312c <allocproc+0xac>

80103141 <forkret>:
{
80103141:	55                   	push   %ebp
80103142:	89 e5                	mov    %esp,%ebp
80103144:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103147:	68 40 1d 11 80       	push   $0x80111d40
8010314c:	e8 c8 0a 00 00       	call   80103c19 <release>
  if (first) {
80103151:	83 c4 10             	add    $0x10,%esp
80103154:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
8010315b:	75 02                	jne    8010315f <forkret+0x1e>
}
8010315d:	c9                   	leave  
8010315e:	c3                   	ret    
    first = 0;
8010315f:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
80103166:	00 00 00 
    iinit(ROOTDEV);
80103169:	83 ec 0c             	sub    $0xc,%esp
8010316c:	6a 01                	push   $0x1
8010316e:	e8 79 e1 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103173:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010317a:	e8 05 f6 ff ff       	call   80102784 <initlog>
8010317f:	83 c4 10             	add    $0x10,%esp
}
80103182:	eb d9                	jmp    8010315d <forkret+0x1c>

80103184 <pinit>:
{
80103184:	55                   	push   %ebp
80103185:	89 e5                	mov    %esp,%ebp
80103187:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010318a:	68 95 69 10 80       	push   $0x80106995
8010318f:	68 40 1d 11 80       	push   $0x80111d40
80103194:	e8 df 08 00 00       	call   80103a78 <initlock>
}
80103199:	83 c4 10             	add    $0x10,%esp
8010319c:	c9                   	leave  
8010319d:	c3                   	ret    

8010319e <mycpu>:
{
8010319e:	55                   	push   %ebp
8010319f:	89 e5                	mov    %esp,%ebp
801031a1:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801031a4:	9c                   	pushf  
801031a5:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801031a6:	f6 c4 02             	test   $0x2,%ah
801031a9:	75 28                	jne    801031d3 <mycpu+0x35>
  apicid = lapicid();
801031ab:	e8 ed f1 ff ff       	call   8010239d <lapicid>
  for (i = 0; i < ncpu; ++i) {
801031b0:	ba 00 00 00 00       	mov    $0x0,%edx
801031b5:	39 15 20 1d 11 80    	cmp    %edx,0x80111d20
801031bb:	7e 23                	jle    801031e0 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801031bd:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801031c3:	0f b6 89 a0 17 11 80 	movzbl -0x7feee860(%ecx),%ecx
801031ca:	39 c1                	cmp    %eax,%ecx
801031cc:	74 1f                	je     801031ed <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801031ce:	83 c2 01             	add    $0x1,%edx
801031d1:	eb e2                	jmp    801031b5 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801031d3:	83 ec 0c             	sub    $0xc,%esp
801031d6:	68 78 6a 10 80       	push   $0x80106a78
801031db:	e8 68 d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031e0:	83 ec 0c             	sub    $0xc,%esp
801031e3:	68 9c 69 10 80       	push   $0x8010699c
801031e8:	e8 5b d1 ff ff       	call   80100348 <panic>
      return &cpus[i];
801031ed:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801031f3:	05 a0 17 11 80       	add    $0x801117a0,%eax
}
801031f8:	c9                   	leave  
801031f9:	c3                   	ret    

801031fa <cpuid>:
cpuid() {
801031fa:	55                   	push   %ebp
801031fb:	89 e5                	mov    %esp,%ebp
801031fd:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103200:	e8 99 ff ff ff       	call   8010319e <mycpu>
80103205:	2d a0 17 11 80       	sub    $0x801117a0,%eax
8010320a:	c1 f8 04             	sar    $0x4,%eax
8010320d:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103213:	c9                   	leave  
80103214:	c3                   	ret    

80103215 <myproc>:
myproc(void) {
80103215:	55                   	push   %ebp
80103216:	89 e5                	mov    %esp,%ebp
80103218:	53                   	push   %ebx
80103219:	83 ec 04             	sub    $0x4,%esp
  pushcli();
8010321c:	e8 b6 08 00 00       	call   80103ad7 <pushcli>
  c = mycpu();
80103221:	e8 78 ff ff ff       	call   8010319e <mycpu>
  p = c->proc;
80103226:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
8010322c:	e8 e3 08 00 00       	call   80103b14 <popcli>
}
80103231:	89 d8                	mov    %ebx,%eax
80103233:	83 c4 04             	add    $0x4,%esp
80103236:	5b                   	pop    %ebx
80103237:	5d                   	pop    %ebp
80103238:	c3                   	ret    

80103239 <userinit>:
{
80103239:	55                   	push   %ebp
8010323a:	89 e5                	mov    %esp,%ebp
8010323c:	53                   	push   %ebx
8010323d:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103240:	e8 3b fe ff ff       	call   80103080 <allocproc>
80103245:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103247:	a3 bc 95 10 80       	mov    %eax,0x801095bc
  if((p->pgdir = setupkvm()) == 0)
8010324c:	e8 a2 2f 00 00       	call   801061f3 <setupkvm>
80103251:	89 43 04             	mov    %eax,0x4(%ebx)
80103254:	85 c0                	test   %eax,%eax
80103256:	0f 84 b7 00 00 00    	je     80103313 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010325c:	83 ec 04             	sub    $0x4,%esp
8010325f:	68 2c 00 00 00       	push   $0x2c
80103264:	68 60 94 10 80       	push   $0x80109460
80103269:	50                   	push   %eax
8010326a:	e8 8f 2c 00 00       	call   80105efe <inituvm>
  p->sz = PGSIZE;
8010326f:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103275:	83 c4 0c             	add    $0xc,%esp
80103278:	6a 4c                	push   $0x4c
8010327a:	6a 00                	push   $0x0
8010327c:	ff 73 18             	pushl  0x18(%ebx)
8010327f:	e8 dc 09 00 00       	call   80103c60 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103284:	8b 43 18             	mov    0x18(%ebx),%eax
80103287:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010328d:	8b 43 18             	mov    0x18(%ebx),%eax
80103290:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103296:	8b 43 18             	mov    0x18(%ebx),%eax
80103299:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010329d:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801032a1:	8b 43 18             	mov    0x18(%ebx),%eax
801032a4:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032a8:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801032ac:	8b 43 18             	mov    0x18(%ebx),%eax
801032af:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801032b6:	8b 43 18             	mov    0x18(%ebx),%eax
801032b9:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801032c0:	8b 43 18             	mov    0x18(%ebx),%eax
801032c3:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801032ca:	8d 43 6c             	lea    0x6c(%ebx),%eax
801032cd:	83 c4 0c             	add    $0xc,%esp
801032d0:	6a 10                	push   $0x10
801032d2:	68 c5 69 10 80       	push   $0x801069c5
801032d7:	50                   	push   %eax
801032d8:	e8 ea 0a 00 00       	call   80103dc7 <safestrcpy>
  p->cwd = namei("/");
801032dd:	c7 04 24 ce 69 10 80 	movl   $0x801069ce,(%esp)
801032e4:	e8 f8 e8 ff ff       	call   80101be1 <namei>
801032e9:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801032ec:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
801032f3:	e8 bc 08 00 00       	call   80103bb4 <acquire>
  p->state = RUNNABLE;
801032f8:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801032ff:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
80103306:	e8 0e 09 00 00       	call   80103c19 <release>
}
8010330b:	83 c4 10             	add    $0x10,%esp
8010330e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103311:	c9                   	leave  
80103312:	c3                   	ret    
    panic("userinit: out of memory?");
80103313:	83 ec 0c             	sub    $0xc,%esp
80103316:	68 ac 69 10 80       	push   $0x801069ac
8010331b:	e8 28 d0 ff ff       	call   80100348 <panic>

80103320 <growproc>:
{
80103320:	55                   	push   %ebp
80103321:	89 e5                	mov    %esp,%ebp
80103323:	56                   	push   %esi
80103324:	53                   	push   %ebx
80103325:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103328:	e8 e8 fe ff ff       	call   80103215 <myproc>
8010332d:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010332f:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103331:	85 f6                	test   %esi,%esi
80103333:	7f 21                	jg     80103356 <growproc+0x36>
  } else if(n < 0){
80103335:	85 f6                	test   %esi,%esi
80103337:	79 33                	jns    8010336c <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103339:	83 ec 04             	sub    $0x4,%esp
8010333c:	01 c6                	add    %eax,%esi
8010333e:	56                   	push   %esi
8010333f:	50                   	push   %eax
80103340:	ff 73 04             	pushl  0x4(%ebx)
80103343:	e8 bf 2c 00 00       	call   80106007 <deallocuvm>
80103348:	83 c4 10             	add    $0x10,%esp
8010334b:	85 c0                	test   %eax,%eax
8010334d:	75 1d                	jne    8010336c <growproc+0x4c>
      return -1;
8010334f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103354:	eb 29                	jmp    8010337f <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103356:	83 ec 04             	sub    $0x4,%esp
80103359:	01 c6                	add    %eax,%esi
8010335b:	56                   	push   %esi
8010335c:	50                   	push   %eax
8010335d:	ff 73 04             	pushl  0x4(%ebx)
80103360:	e8 34 2d 00 00       	call   80106099 <allocuvm>
80103365:	83 c4 10             	add    $0x10,%esp
80103368:	85 c0                	test   %eax,%eax
8010336a:	74 1a                	je     80103386 <growproc+0x66>
  curproc->sz = sz;
8010336c:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010336e:	83 ec 0c             	sub    $0xc,%esp
80103371:	53                   	push   %ebx
80103372:	e8 6f 2a 00 00       	call   80105de6 <switchuvm>
  return 0;
80103377:	83 c4 10             	add    $0x10,%esp
8010337a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010337f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103382:	5b                   	pop    %ebx
80103383:	5e                   	pop    %esi
80103384:	5d                   	pop    %ebp
80103385:	c3                   	ret    
      return -1;
80103386:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010338b:	eb f2                	jmp    8010337f <growproc+0x5f>

8010338d <fork>:
{
8010338d:	55                   	push   %ebp
8010338e:	89 e5                	mov    %esp,%ebp
80103390:	57                   	push   %edi
80103391:	56                   	push   %esi
80103392:	53                   	push   %ebx
80103393:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103396:	e8 7a fe ff ff       	call   80103215 <myproc>
8010339b:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
8010339d:	e8 de fc ff ff       	call   80103080 <allocproc>
801033a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801033a5:	85 c0                	test   %eax,%eax
801033a7:	0f 84 e0 00 00 00    	je     8010348d <fork+0x100>
801033ad:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801033af:	83 ec 08             	sub    $0x8,%esp
801033b2:	ff 33                	pushl  (%ebx)
801033b4:	ff 73 04             	pushl  0x4(%ebx)
801033b7:	e8 e8 2e 00 00       	call   801062a4 <copyuvm>
801033bc:	89 47 04             	mov    %eax,0x4(%edi)
801033bf:	83 c4 10             	add    $0x10,%esp
801033c2:	85 c0                	test   %eax,%eax
801033c4:	74 2a                	je     801033f0 <fork+0x63>
  np->sz = curproc->sz;
801033c6:	8b 03                	mov    (%ebx),%eax
801033c8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801033cb:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801033cd:	89 c8                	mov    %ecx,%eax
801033cf:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801033d2:	8b 73 18             	mov    0x18(%ebx),%esi
801033d5:	8b 79 18             	mov    0x18(%ecx),%edi
801033d8:	b9 13 00 00 00       	mov    $0x13,%ecx
801033dd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801033df:	8b 40 18             	mov    0x18(%eax),%eax
801033e2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801033e9:	be 00 00 00 00       	mov    $0x0,%esi
801033ee:	eb 29                	jmp    80103419 <fork+0x8c>
    kfree(np->kstack);
801033f0:	83 ec 0c             	sub    $0xc,%esp
801033f3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801033f6:	ff 73 08             	pushl  0x8(%ebx)
801033f9:	e8 a6 eb ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
801033fe:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103405:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
8010340c:	83 c4 10             	add    $0x10,%esp
8010340f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103414:	eb 6d                	jmp    80103483 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
80103416:	83 c6 01             	add    $0x1,%esi
80103419:	83 fe 0f             	cmp    $0xf,%esi
8010341c:	7f 1d                	jg     8010343b <fork+0xae>
    if(curproc->ofile[i])
8010341e:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103422:	85 c0                	test   %eax,%eax
80103424:	74 f0                	je     80103416 <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103426:	83 ec 0c             	sub    $0xc,%esp
80103429:	50                   	push   %eax
8010342a:	e8 5f d8 ff ff       	call   80100c8e <filedup>
8010342f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103432:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103436:	83 c4 10             	add    $0x10,%esp
80103439:	eb db                	jmp    80103416 <fork+0x89>
  np->cwd = idup(curproc->cwd);
8010343b:	83 ec 0c             	sub    $0xc,%esp
8010343e:	ff 73 68             	pushl  0x68(%ebx)
80103441:	e8 0b e1 ff ff       	call   80101551 <idup>
80103446:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103449:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010344c:	83 c3 6c             	add    $0x6c,%ebx
8010344f:	8d 47 6c             	lea    0x6c(%edi),%eax
80103452:	83 c4 0c             	add    $0xc,%esp
80103455:	6a 10                	push   $0x10
80103457:	53                   	push   %ebx
80103458:	50                   	push   %eax
80103459:	e8 69 09 00 00       	call   80103dc7 <safestrcpy>
  pid = np->pid;
8010345e:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103461:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
80103468:	e8 47 07 00 00       	call   80103bb4 <acquire>
  np->state = RUNNABLE;
8010346d:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103474:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010347b:	e8 99 07 00 00       	call   80103c19 <release>
  return pid;
80103480:	83 c4 10             	add    $0x10,%esp
}
80103483:	89 d8                	mov    %ebx,%eax
80103485:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103488:	5b                   	pop    %ebx
80103489:	5e                   	pop    %esi
8010348a:	5f                   	pop    %edi
8010348b:	5d                   	pop    %ebp
8010348c:	c3                   	ret    
    return -1;
8010348d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103492:	eb ef                	jmp    80103483 <fork+0xf6>

80103494 <scheduler>:
{
80103494:	55                   	push   %ebp
80103495:	89 e5                	mov    %esp,%ebp
80103497:	56                   	push   %esi
80103498:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103499:	e8 00 fd ff ff       	call   8010319e <mycpu>
8010349e:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801034a0:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801034a7:	00 00 00 
801034aa:	eb 5a                	jmp    80103506 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801034ac:	83 c3 7c             	add    $0x7c,%ebx
801034af:	81 fb 74 3c 11 80    	cmp    $0x80113c74,%ebx
801034b5:	73 3f                	jae    801034f6 <scheduler+0x62>
      if(p->state != RUNNABLE)
801034b7:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801034bb:	75 ef                	jne    801034ac <scheduler+0x18>
      c->proc = p;
801034bd:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801034c3:	83 ec 0c             	sub    $0xc,%esp
801034c6:	53                   	push   %ebx
801034c7:	e8 1a 29 00 00       	call   80105de6 <switchuvm>
      p->state = RUNNING;
801034cc:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801034d3:	83 c4 08             	add    $0x8,%esp
801034d6:	ff 73 1c             	pushl  0x1c(%ebx)
801034d9:	8d 46 04             	lea    0x4(%esi),%eax
801034dc:	50                   	push   %eax
801034dd:	e8 38 09 00 00       	call   80103e1a <swtch>
      switchkvm();
801034e2:	e8 ed 28 00 00       	call   80105dd4 <switchkvm>
      c->proc = 0;
801034e7:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801034ee:	00 00 00 
801034f1:	83 c4 10             	add    $0x10,%esp
801034f4:	eb b6                	jmp    801034ac <scheduler+0x18>
    release(&ptable.lock);
801034f6:	83 ec 0c             	sub    $0xc,%esp
801034f9:	68 40 1d 11 80       	push   $0x80111d40
801034fe:	e8 16 07 00 00       	call   80103c19 <release>
    sti();
80103503:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103506:	fb                   	sti    
    acquire(&ptable.lock);
80103507:	83 ec 0c             	sub    $0xc,%esp
8010350a:	68 40 1d 11 80       	push   $0x80111d40
8010350f:	e8 a0 06 00 00       	call   80103bb4 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103514:	83 c4 10             	add    $0x10,%esp
80103517:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
8010351c:	eb 91                	jmp    801034af <scheduler+0x1b>

8010351e <sched>:
{
8010351e:	55                   	push   %ebp
8010351f:	89 e5                	mov    %esp,%ebp
80103521:	56                   	push   %esi
80103522:	53                   	push   %ebx
  struct proc *p = myproc();
80103523:	e8 ed fc ff ff       	call   80103215 <myproc>
80103528:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010352a:	83 ec 0c             	sub    $0xc,%esp
8010352d:	68 40 1d 11 80       	push   $0x80111d40
80103532:	e8 3d 06 00 00       	call   80103b74 <holding>
80103537:	83 c4 10             	add    $0x10,%esp
8010353a:	85 c0                	test   %eax,%eax
8010353c:	74 4f                	je     8010358d <sched+0x6f>
  if(mycpu()->ncli != 1)
8010353e:	e8 5b fc ff ff       	call   8010319e <mycpu>
80103543:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010354a:	75 4e                	jne    8010359a <sched+0x7c>
  if(p->state == RUNNING)
8010354c:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103550:	74 55                	je     801035a7 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103552:	9c                   	pushf  
80103553:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103554:	f6 c4 02             	test   $0x2,%ah
80103557:	75 5b                	jne    801035b4 <sched+0x96>
  intena = mycpu()->intena;
80103559:	e8 40 fc ff ff       	call   8010319e <mycpu>
8010355e:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103564:	e8 35 fc ff ff       	call   8010319e <mycpu>
80103569:	83 ec 08             	sub    $0x8,%esp
8010356c:	ff 70 04             	pushl  0x4(%eax)
8010356f:	83 c3 1c             	add    $0x1c,%ebx
80103572:	53                   	push   %ebx
80103573:	e8 a2 08 00 00       	call   80103e1a <swtch>
  mycpu()->intena = intena;
80103578:	e8 21 fc ff ff       	call   8010319e <mycpu>
8010357d:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103583:	83 c4 10             	add    $0x10,%esp
80103586:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103589:	5b                   	pop    %ebx
8010358a:	5e                   	pop    %esi
8010358b:	5d                   	pop    %ebp
8010358c:	c3                   	ret    
    panic("sched ptable.lock");
8010358d:	83 ec 0c             	sub    $0xc,%esp
80103590:	68 d0 69 10 80       	push   $0x801069d0
80103595:	e8 ae cd ff ff       	call   80100348 <panic>
    panic("sched locks");
8010359a:	83 ec 0c             	sub    $0xc,%esp
8010359d:	68 e2 69 10 80       	push   $0x801069e2
801035a2:	e8 a1 cd ff ff       	call   80100348 <panic>
    panic("sched running");
801035a7:	83 ec 0c             	sub    $0xc,%esp
801035aa:	68 ee 69 10 80       	push   $0x801069ee
801035af:	e8 94 cd ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801035b4:	83 ec 0c             	sub    $0xc,%esp
801035b7:	68 fc 69 10 80       	push   $0x801069fc
801035bc:	e8 87 cd ff ff       	call   80100348 <panic>

801035c1 <exit>:
{
801035c1:	55                   	push   %ebp
801035c2:	89 e5                	mov    %esp,%ebp
801035c4:	56                   	push   %esi
801035c5:	53                   	push   %ebx
  struct proc *curproc = myproc();
801035c6:	e8 4a fc ff ff       	call   80103215 <myproc>
  if(curproc == initproc)
801035cb:	39 05 bc 95 10 80    	cmp    %eax,0x801095bc
801035d1:	74 09                	je     801035dc <exit+0x1b>
801035d3:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801035d5:	bb 00 00 00 00       	mov    $0x0,%ebx
801035da:	eb 10                	jmp    801035ec <exit+0x2b>
    panic("init exiting");
801035dc:	83 ec 0c             	sub    $0xc,%esp
801035df:	68 10 6a 10 80       	push   $0x80106a10
801035e4:	e8 5f cd ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801035e9:	83 c3 01             	add    $0x1,%ebx
801035ec:	83 fb 0f             	cmp    $0xf,%ebx
801035ef:	7f 1e                	jg     8010360f <exit+0x4e>
    if(curproc->ofile[fd]){
801035f1:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801035f5:	85 c0                	test   %eax,%eax
801035f7:	74 f0                	je     801035e9 <exit+0x28>
      fileclose(curproc->ofile[fd]);
801035f9:	83 ec 0c             	sub    $0xc,%esp
801035fc:	50                   	push   %eax
801035fd:	e8 d1 d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103602:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103609:	00 
8010360a:	83 c4 10             	add    $0x10,%esp
8010360d:	eb da                	jmp    801035e9 <exit+0x28>
  begin_op();
8010360f:	e8 b9 f1 ff ff       	call   801027cd <begin_op>
  iput(curproc->cwd);
80103614:	83 ec 0c             	sub    $0xc,%esp
80103617:	ff 76 68             	pushl  0x68(%esi)
8010361a:	e8 69 e0 ff ff       	call   80101688 <iput>
  end_op();
8010361f:	e8 23 f2 ff ff       	call   80102847 <end_op>
  curproc->cwd = 0;
80103624:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010362b:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
80103632:	e8 7d 05 00 00       	call   80103bb4 <acquire>
  wakeup1(curproc->parent);
80103637:	8b 46 14             	mov    0x14(%esi),%eax
8010363a:	e8 16 fa ff ff       	call   80103055 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010363f:	83 c4 10             	add    $0x10,%esp
80103642:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103647:	eb 03                	jmp    8010364c <exit+0x8b>
80103649:	83 c3 7c             	add    $0x7c,%ebx
8010364c:	81 fb 74 3c 11 80    	cmp    $0x80113c74,%ebx
80103652:	73 1a                	jae    8010366e <exit+0xad>
    if(p->parent == curproc){
80103654:	39 73 14             	cmp    %esi,0x14(%ebx)
80103657:	75 f0                	jne    80103649 <exit+0x88>
      p->parent = initproc;
80103659:	a1 bc 95 10 80       	mov    0x801095bc,%eax
8010365e:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103661:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103665:	75 e2                	jne    80103649 <exit+0x88>
        wakeup1(initproc);
80103667:	e8 e9 f9 ff ff       	call   80103055 <wakeup1>
8010366c:	eb db                	jmp    80103649 <exit+0x88>
  curproc->state = ZOMBIE;
8010366e:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103675:	e8 a4 fe ff ff       	call   8010351e <sched>
  panic("zombie exit");
8010367a:	83 ec 0c             	sub    $0xc,%esp
8010367d:	68 1d 6a 10 80       	push   $0x80106a1d
80103682:	e8 c1 cc ff ff       	call   80100348 <panic>

80103687 <yield>:
{
80103687:	55                   	push   %ebp
80103688:	89 e5                	mov    %esp,%ebp
8010368a:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010368d:	68 40 1d 11 80       	push   $0x80111d40
80103692:	e8 1d 05 00 00       	call   80103bb4 <acquire>
  myproc()->state = RUNNABLE;
80103697:	e8 79 fb ff ff       	call   80103215 <myproc>
8010369c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801036a3:	e8 76 fe ff ff       	call   8010351e <sched>
  release(&ptable.lock);
801036a8:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
801036af:	e8 65 05 00 00       	call   80103c19 <release>
}
801036b4:	83 c4 10             	add    $0x10,%esp
801036b7:	c9                   	leave  
801036b8:	c3                   	ret    

801036b9 <sleep>:
{
801036b9:	55                   	push   %ebp
801036ba:	89 e5                	mov    %esp,%ebp
801036bc:	56                   	push   %esi
801036bd:	53                   	push   %ebx
801036be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801036c1:	e8 4f fb ff ff       	call   80103215 <myproc>
  if(p == 0)
801036c6:	85 c0                	test   %eax,%eax
801036c8:	74 66                	je     80103730 <sleep+0x77>
801036ca:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801036cc:	85 db                	test   %ebx,%ebx
801036ce:	74 6d                	je     8010373d <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801036d0:	81 fb 40 1d 11 80    	cmp    $0x80111d40,%ebx
801036d6:	74 18                	je     801036f0 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801036d8:	83 ec 0c             	sub    $0xc,%esp
801036db:	68 40 1d 11 80       	push   $0x80111d40
801036e0:	e8 cf 04 00 00       	call   80103bb4 <acquire>
    release(lk);
801036e5:	89 1c 24             	mov    %ebx,(%esp)
801036e8:	e8 2c 05 00 00       	call   80103c19 <release>
801036ed:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801036f0:	8b 45 08             	mov    0x8(%ebp),%eax
801036f3:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801036f6:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801036fd:	e8 1c fe ff ff       	call   8010351e <sched>
  p->chan = 0;
80103702:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103709:	81 fb 40 1d 11 80    	cmp    $0x80111d40,%ebx
8010370f:	74 18                	je     80103729 <sleep+0x70>
    release(&ptable.lock);
80103711:	83 ec 0c             	sub    $0xc,%esp
80103714:	68 40 1d 11 80       	push   $0x80111d40
80103719:	e8 fb 04 00 00       	call   80103c19 <release>
    acquire(lk);
8010371e:	89 1c 24             	mov    %ebx,(%esp)
80103721:	e8 8e 04 00 00       	call   80103bb4 <acquire>
80103726:	83 c4 10             	add    $0x10,%esp
}
80103729:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010372c:	5b                   	pop    %ebx
8010372d:	5e                   	pop    %esi
8010372e:	5d                   	pop    %ebp
8010372f:	c3                   	ret    
    panic("sleep");
80103730:	83 ec 0c             	sub    $0xc,%esp
80103733:	68 29 6a 10 80       	push   $0x80106a29
80103738:	e8 0b cc ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010373d:	83 ec 0c             	sub    $0xc,%esp
80103740:	68 2f 6a 10 80       	push   $0x80106a2f
80103745:	e8 fe cb ff ff       	call   80100348 <panic>

8010374a <wait>:
{
8010374a:	55                   	push   %ebp
8010374b:	89 e5                	mov    %esp,%ebp
8010374d:	56                   	push   %esi
8010374e:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010374f:	e8 c1 fa ff ff       	call   80103215 <myproc>
80103754:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103756:	83 ec 0c             	sub    $0xc,%esp
80103759:	68 40 1d 11 80       	push   $0x80111d40
8010375e:	e8 51 04 00 00       	call   80103bb4 <acquire>
80103763:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103766:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010376b:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103770:	eb 5b                	jmp    801037cd <wait+0x83>
        pid = p->pid;
80103772:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103775:	83 ec 0c             	sub    $0xc,%esp
80103778:	ff 73 08             	pushl  0x8(%ebx)
8010377b:	e8 24 e8 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
80103780:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103787:	83 c4 04             	add    $0x4,%esp
8010378a:	ff 73 04             	pushl  0x4(%ebx)
8010378d:	e8 f1 29 00 00       	call   80106183 <freevm>
        p->pid = 0;
80103792:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103799:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801037a0:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801037a4:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801037ab:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801037b2:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
801037b9:	e8 5b 04 00 00       	call   80103c19 <release>
        return pid;
801037be:	83 c4 10             	add    $0x10,%esp
}
801037c1:	89 f0                	mov    %esi,%eax
801037c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037c6:	5b                   	pop    %ebx
801037c7:	5e                   	pop    %esi
801037c8:	5d                   	pop    %ebp
801037c9:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037ca:	83 c3 7c             	add    $0x7c,%ebx
801037cd:	81 fb 74 3c 11 80    	cmp    $0x80113c74,%ebx
801037d3:	73 12                	jae    801037e7 <wait+0x9d>
      if(p->parent != curproc)
801037d5:	39 73 14             	cmp    %esi,0x14(%ebx)
801037d8:	75 f0                	jne    801037ca <wait+0x80>
      if(p->state == ZOMBIE){
801037da:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801037de:	74 92                	je     80103772 <wait+0x28>
      havekids = 1;
801037e0:	b8 01 00 00 00       	mov    $0x1,%eax
801037e5:	eb e3                	jmp    801037ca <wait+0x80>
    if(!havekids || curproc->killed){
801037e7:	85 c0                	test   %eax,%eax
801037e9:	74 06                	je     801037f1 <wait+0xa7>
801037eb:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801037ef:	74 17                	je     80103808 <wait+0xbe>
      release(&ptable.lock);
801037f1:	83 ec 0c             	sub    $0xc,%esp
801037f4:	68 40 1d 11 80       	push   $0x80111d40
801037f9:	e8 1b 04 00 00       	call   80103c19 <release>
      return -1;
801037fe:	83 c4 10             	add    $0x10,%esp
80103801:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103806:	eb b9                	jmp    801037c1 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103808:	83 ec 08             	sub    $0x8,%esp
8010380b:	68 40 1d 11 80       	push   $0x80111d40
80103810:	56                   	push   %esi
80103811:	e8 a3 fe ff ff       	call   801036b9 <sleep>
    havekids = 0;
80103816:	83 c4 10             	add    $0x10,%esp
80103819:	e9 48 ff ff ff       	jmp    80103766 <wait+0x1c>

8010381e <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010381e:	55                   	push   %ebp
8010381f:	89 e5                	mov    %esp,%ebp
80103821:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103824:	68 40 1d 11 80       	push   $0x80111d40
80103829:	e8 86 03 00 00       	call   80103bb4 <acquire>
  wakeup1(chan);
8010382e:	8b 45 08             	mov    0x8(%ebp),%eax
80103831:	e8 1f f8 ff ff       	call   80103055 <wakeup1>
  release(&ptable.lock);
80103836:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010383d:	e8 d7 03 00 00       	call   80103c19 <release>
}
80103842:	83 c4 10             	add    $0x10,%esp
80103845:	c9                   	leave  
80103846:	c3                   	ret    

80103847 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103847:	55                   	push   %ebp
80103848:	89 e5                	mov    %esp,%ebp
8010384a:	53                   	push   %ebx
8010384b:	83 ec 10             	sub    $0x10,%esp
8010384e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103851:	68 40 1d 11 80       	push   $0x80111d40
80103856:	e8 59 03 00 00       	call   80103bb4 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010385b:	83 c4 10             	add    $0x10,%esp
8010385e:	b8 74 1d 11 80       	mov    $0x80111d74,%eax
80103863:	3d 74 3c 11 80       	cmp    $0x80113c74,%eax
80103868:	73 3a                	jae    801038a4 <kill+0x5d>
    if(p->pid == pid){
8010386a:	39 58 10             	cmp    %ebx,0x10(%eax)
8010386d:	74 05                	je     80103874 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010386f:	83 c0 7c             	add    $0x7c,%eax
80103872:	eb ef                	jmp    80103863 <kill+0x1c>
      p->killed = 1;
80103874:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
8010387b:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
8010387f:	74 1a                	je     8010389b <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103881:	83 ec 0c             	sub    $0xc,%esp
80103884:	68 40 1d 11 80       	push   $0x80111d40
80103889:	e8 8b 03 00 00       	call   80103c19 <release>
      return 0;
8010388e:	83 c4 10             	add    $0x10,%esp
80103891:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103896:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103899:	c9                   	leave  
8010389a:	c3                   	ret    
        p->state = RUNNABLE;
8010389b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801038a2:	eb dd                	jmp    80103881 <kill+0x3a>
  release(&ptable.lock);
801038a4:	83 ec 0c             	sub    $0xc,%esp
801038a7:	68 40 1d 11 80       	push   $0x80111d40
801038ac:	e8 68 03 00 00       	call   80103c19 <release>
  return -1;
801038b1:	83 c4 10             	add    $0x10,%esp
801038b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801038b9:	eb db                	jmp    80103896 <kill+0x4f>

801038bb <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801038bb:	55                   	push   %ebp
801038bc:	89 e5                	mov    %esp,%ebp
801038be:	56                   	push   %esi
801038bf:	53                   	push   %ebx
801038c0:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038c3:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
801038c8:	eb 33                	jmp    801038fd <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801038ca:	b8 40 6a 10 80       	mov    $0x80106a40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801038cf:	8d 53 6c             	lea    0x6c(%ebx),%edx
801038d2:	52                   	push   %edx
801038d3:	50                   	push   %eax
801038d4:	ff 73 10             	pushl  0x10(%ebx)
801038d7:	68 44 6a 10 80       	push   $0x80106a44
801038dc:	e8 2a cd ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801038e1:	83 c4 10             	add    $0x10,%esp
801038e4:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801038e8:	74 39                	je     80103923 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801038ea:	83 ec 0c             	sub    $0xc,%esp
801038ed:	68 bb 6d 10 80       	push   $0x80106dbb
801038f2:	e8 14 cd ff ff       	call   8010060b <cprintf>
801038f7:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038fa:	83 c3 7c             	add    $0x7c,%ebx
801038fd:	81 fb 74 3c 11 80    	cmp    $0x80113c74,%ebx
80103903:	73 61                	jae    80103966 <procdump+0xab>
    if(p->state == UNUSED)
80103905:	8b 43 0c             	mov    0xc(%ebx),%eax
80103908:	85 c0                	test   %eax,%eax
8010390a:	74 ee                	je     801038fa <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010390c:	83 f8 05             	cmp    $0x5,%eax
8010390f:	77 b9                	ja     801038ca <procdump+0xf>
80103911:	8b 04 85 a0 6a 10 80 	mov    -0x7fef9560(,%eax,4),%eax
80103918:	85 c0                	test   %eax,%eax
8010391a:	75 b3                	jne    801038cf <procdump+0x14>
      state = "???";
8010391c:	b8 40 6a 10 80       	mov    $0x80106a40,%eax
80103921:	eb ac                	jmp    801038cf <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103923:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103926:	8b 40 0c             	mov    0xc(%eax),%eax
80103929:	83 c0 08             	add    $0x8,%eax
8010392c:	83 ec 08             	sub    $0x8,%esp
8010392f:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103932:	52                   	push   %edx
80103933:	50                   	push   %eax
80103934:	e8 5a 01 00 00       	call   80103a93 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103939:	83 c4 10             	add    $0x10,%esp
8010393c:	be 00 00 00 00       	mov    $0x0,%esi
80103941:	eb 14                	jmp    80103957 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103943:	83 ec 08             	sub    $0x8,%esp
80103946:	50                   	push   %eax
80103947:	68 81 64 10 80       	push   $0x80106481
8010394c:	e8 ba cc ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103951:	83 c6 01             	add    $0x1,%esi
80103954:	83 c4 10             	add    $0x10,%esp
80103957:	83 fe 09             	cmp    $0x9,%esi
8010395a:	7f 8e                	jg     801038ea <procdump+0x2f>
8010395c:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103960:	85 c0                	test   %eax,%eax
80103962:	75 df                	jne    80103943 <procdump+0x88>
80103964:	eb 84                	jmp    801038ea <procdump+0x2f>
  }
}
80103966:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103969:	5b                   	pop    %ebx
8010396a:	5e                   	pop    %esi
8010396b:	5d                   	pop    %ebp
8010396c:	c3                   	ret    

8010396d <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
8010396d:	55                   	push   %ebp
8010396e:	89 e5                	mov    %esp,%ebp
80103970:	53                   	push   %ebx
80103971:	83 ec 0c             	sub    $0xc,%esp
80103974:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103977:	68 b8 6a 10 80       	push   $0x80106ab8
8010397c:	8d 43 04             	lea    0x4(%ebx),%eax
8010397f:	50                   	push   %eax
80103980:	e8 f3 00 00 00       	call   80103a78 <initlock>
  lk->name = name;
80103985:	8b 45 0c             	mov    0xc(%ebp),%eax
80103988:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
8010398b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103991:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103998:	83 c4 10             	add    $0x10,%esp
8010399b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010399e:	c9                   	leave  
8010399f:	c3                   	ret    

801039a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
801039a0:	55                   	push   %ebp
801039a1:	89 e5                	mov    %esp,%ebp
801039a3:	56                   	push   %esi
801039a4:	53                   	push   %ebx
801039a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
801039a8:	8d 73 04             	lea    0x4(%ebx),%esi
801039ab:	83 ec 0c             	sub    $0xc,%esp
801039ae:	56                   	push   %esi
801039af:	e8 00 02 00 00       	call   80103bb4 <acquire>
  while (lk->locked) {
801039b4:	83 c4 10             	add    $0x10,%esp
801039b7:	eb 0d                	jmp    801039c6 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
801039b9:	83 ec 08             	sub    $0x8,%esp
801039bc:	56                   	push   %esi
801039bd:	53                   	push   %ebx
801039be:	e8 f6 fc ff ff       	call   801036b9 <sleep>
801039c3:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
801039c6:	83 3b 00             	cmpl   $0x0,(%ebx)
801039c9:	75 ee                	jne    801039b9 <acquiresleep+0x19>
  }
  lk->locked = 1;
801039cb:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
801039d1:	e8 3f f8 ff ff       	call   80103215 <myproc>
801039d6:	8b 40 10             	mov    0x10(%eax),%eax
801039d9:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
801039dc:	83 ec 0c             	sub    $0xc,%esp
801039df:	56                   	push   %esi
801039e0:	e8 34 02 00 00       	call   80103c19 <release>
}
801039e5:	83 c4 10             	add    $0x10,%esp
801039e8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039eb:	5b                   	pop    %ebx
801039ec:	5e                   	pop    %esi
801039ed:	5d                   	pop    %ebp
801039ee:	c3                   	ret    

801039ef <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
801039ef:	55                   	push   %ebp
801039f0:	89 e5                	mov    %esp,%ebp
801039f2:	56                   	push   %esi
801039f3:	53                   	push   %ebx
801039f4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
801039f7:	8d 73 04             	lea    0x4(%ebx),%esi
801039fa:	83 ec 0c             	sub    $0xc,%esp
801039fd:	56                   	push   %esi
801039fe:	e8 b1 01 00 00       	call   80103bb4 <acquire>
  lk->locked = 0;
80103a03:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a09:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103a10:	89 1c 24             	mov    %ebx,(%esp)
80103a13:	e8 06 fe ff ff       	call   8010381e <wakeup>
  release(&lk->lk);
80103a18:	89 34 24             	mov    %esi,(%esp)
80103a1b:	e8 f9 01 00 00       	call   80103c19 <release>
}
80103a20:	83 c4 10             	add    $0x10,%esp
80103a23:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a26:	5b                   	pop    %ebx
80103a27:	5e                   	pop    %esi
80103a28:	5d                   	pop    %ebp
80103a29:	c3                   	ret    

80103a2a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	56                   	push   %esi
80103a2e:	53                   	push   %ebx
80103a2f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103a32:	8d 73 04             	lea    0x4(%ebx),%esi
80103a35:	83 ec 0c             	sub    $0xc,%esp
80103a38:	56                   	push   %esi
80103a39:	e8 76 01 00 00       	call   80103bb4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103a3e:	83 c4 10             	add    $0x10,%esp
80103a41:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a44:	75 17                	jne    80103a5d <holdingsleep+0x33>
80103a46:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103a4b:	83 ec 0c             	sub    $0xc,%esp
80103a4e:	56                   	push   %esi
80103a4f:	e8 c5 01 00 00       	call   80103c19 <release>
  return r;
}
80103a54:	89 d8                	mov    %ebx,%eax
80103a56:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a59:	5b                   	pop    %ebx
80103a5a:	5e                   	pop    %esi
80103a5b:	5d                   	pop    %ebp
80103a5c:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103a5d:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103a60:	e8 b0 f7 ff ff       	call   80103215 <myproc>
80103a65:	3b 58 10             	cmp    0x10(%eax),%ebx
80103a68:	74 07                	je     80103a71 <holdingsleep+0x47>
80103a6a:	bb 00 00 00 00       	mov    $0x0,%ebx
80103a6f:	eb da                	jmp    80103a4b <holdingsleep+0x21>
80103a71:	bb 01 00 00 00       	mov    $0x1,%ebx
80103a76:	eb d3                	jmp    80103a4b <holdingsleep+0x21>

80103a78 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103a78:	55                   	push   %ebp
80103a79:	89 e5                	mov    %esp,%ebp
80103a7b:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103a7e:	8b 55 0c             	mov    0xc(%ebp),%edx
80103a81:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103a84:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103a8a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103a91:	5d                   	pop    %ebp
80103a92:	c3                   	ret    

80103a93 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103a93:	55                   	push   %ebp
80103a94:	89 e5                	mov    %esp,%ebp
80103a96:	53                   	push   %ebx
80103a97:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103a9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103a9d:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103aa0:	b8 00 00 00 00       	mov    $0x0,%eax
80103aa5:	83 f8 09             	cmp    $0x9,%eax
80103aa8:	7f 25                	jg     80103acf <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103aaa:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103ab0:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103ab6:	77 17                	ja     80103acf <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103ab8:	8b 5a 04             	mov    0x4(%edx),%ebx
80103abb:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103abe:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103ac0:	83 c0 01             	add    $0x1,%eax
80103ac3:	eb e0                	jmp    80103aa5 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103ac5:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103acc:	83 c0 01             	add    $0x1,%eax
80103acf:	83 f8 09             	cmp    $0x9,%eax
80103ad2:	7e f1                	jle    80103ac5 <getcallerpcs+0x32>
}
80103ad4:	5b                   	pop    %ebx
80103ad5:	5d                   	pop    %ebp
80103ad6:	c3                   	ret    

80103ad7 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ad7:	55                   	push   %ebp
80103ad8:	89 e5                	mov    %esp,%ebp
80103ada:	53                   	push   %ebx
80103adb:	83 ec 04             	sub    $0x4,%esp
80103ade:	9c                   	pushf  
80103adf:	5b                   	pop    %ebx
  asm volatile("cli");
80103ae0:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103ae1:	e8 b8 f6 ff ff       	call   8010319e <mycpu>
80103ae6:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103aed:	74 12                	je     80103b01 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103aef:	e8 aa f6 ff ff       	call   8010319e <mycpu>
80103af4:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103afb:	83 c4 04             	add    $0x4,%esp
80103afe:	5b                   	pop    %ebx
80103aff:	5d                   	pop    %ebp
80103b00:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103b01:	e8 98 f6 ff ff       	call   8010319e <mycpu>
80103b06:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103b0c:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103b12:	eb db                	jmp    80103aef <pushcli+0x18>

80103b14 <popcli>:

void
popcli(void)
{
80103b14:	55                   	push   %ebp
80103b15:	89 e5                	mov    %esp,%ebp
80103b17:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103b1a:	9c                   	pushf  
80103b1b:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103b1c:	f6 c4 02             	test   $0x2,%ah
80103b1f:	75 28                	jne    80103b49 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103b21:	e8 78 f6 ff ff       	call   8010319e <mycpu>
80103b26:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103b2c:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103b2f:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103b35:	85 d2                	test   %edx,%edx
80103b37:	78 1d                	js     80103b56 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103b39:	e8 60 f6 ff ff       	call   8010319e <mycpu>
80103b3e:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103b45:	74 1c                	je     80103b63 <popcli+0x4f>
    sti();
}
80103b47:	c9                   	leave  
80103b48:	c3                   	ret    
    panic("popcli - interruptible");
80103b49:	83 ec 0c             	sub    $0xc,%esp
80103b4c:	68 c3 6a 10 80       	push   $0x80106ac3
80103b51:	e8 f2 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103b56:	83 ec 0c             	sub    $0xc,%esp
80103b59:	68 da 6a 10 80       	push   $0x80106ada
80103b5e:	e8 e5 c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103b63:	e8 36 f6 ff ff       	call   8010319e <mycpu>
80103b68:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103b6f:	74 d6                	je     80103b47 <popcli+0x33>
  asm volatile("sti");
80103b71:	fb                   	sti    
}
80103b72:	eb d3                	jmp    80103b47 <popcli+0x33>

80103b74 <holding>:
{
80103b74:	55                   	push   %ebp
80103b75:	89 e5                	mov    %esp,%ebp
80103b77:	53                   	push   %ebx
80103b78:	83 ec 04             	sub    $0x4,%esp
80103b7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103b7e:	e8 54 ff ff ff       	call   80103ad7 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103b83:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b86:	75 12                	jne    80103b9a <holding+0x26>
80103b88:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103b8d:	e8 82 ff ff ff       	call   80103b14 <popcli>
}
80103b92:	89 d8                	mov    %ebx,%eax
80103b94:	83 c4 04             	add    $0x4,%esp
80103b97:	5b                   	pop    %ebx
80103b98:	5d                   	pop    %ebp
80103b99:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103b9a:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103b9d:	e8 fc f5 ff ff       	call   8010319e <mycpu>
80103ba2:	39 c3                	cmp    %eax,%ebx
80103ba4:	74 07                	je     80103bad <holding+0x39>
80103ba6:	bb 00 00 00 00       	mov    $0x0,%ebx
80103bab:	eb e0                	jmp    80103b8d <holding+0x19>
80103bad:	bb 01 00 00 00       	mov    $0x1,%ebx
80103bb2:	eb d9                	jmp    80103b8d <holding+0x19>

80103bb4 <acquire>:
{
80103bb4:	55                   	push   %ebp
80103bb5:	89 e5                	mov    %esp,%ebp
80103bb7:	53                   	push   %ebx
80103bb8:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103bbb:	e8 17 ff ff ff       	call   80103ad7 <pushcli>
  if(holding(lk))
80103bc0:	83 ec 0c             	sub    $0xc,%esp
80103bc3:	ff 75 08             	pushl  0x8(%ebp)
80103bc6:	e8 a9 ff ff ff       	call   80103b74 <holding>
80103bcb:	83 c4 10             	add    $0x10,%esp
80103bce:	85 c0                	test   %eax,%eax
80103bd0:	75 3a                	jne    80103c0c <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103bd2:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103bd5:	b8 01 00 00 00       	mov    $0x1,%eax
80103bda:	f0 87 02             	lock xchg %eax,(%edx)
80103bdd:	85 c0                	test   %eax,%eax
80103bdf:	75 f1                	jne    80103bd2 <acquire+0x1e>
  __sync_synchronize();
80103be1:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103be6:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103be9:	e8 b0 f5 ff ff       	call   8010319e <mycpu>
80103bee:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80103bf4:	83 c0 0c             	add    $0xc,%eax
80103bf7:	83 ec 08             	sub    $0x8,%esp
80103bfa:	50                   	push   %eax
80103bfb:	8d 45 08             	lea    0x8(%ebp),%eax
80103bfe:	50                   	push   %eax
80103bff:	e8 8f fe ff ff       	call   80103a93 <getcallerpcs>
}
80103c04:	83 c4 10             	add    $0x10,%esp
80103c07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c0a:	c9                   	leave  
80103c0b:	c3                   	ret    
    panic("acquire");
80103c0c:	83 ec 0c             	sub    $0xc,%esp
80103c0f:	68 e1 6a 10 80       	push   $0x80106ae1
80103c14:	e8 2f c7 ff ff       	call   80100348 <panic>

80103c19 <release>:
{
80103c19:	55                   	push   %ebp
80103c1a:	89 e5                	mov    %esp,%ebp
80103c1c:	53                   	push   %ebx
80103c1d:	83 ec 10             	sub    $0x10,%esp
80103c20:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103c23:	53                   	push   %ebx
80103c24:	e8 4b ff ff ff       	call   80103b74 <holding>
80103c29:	83 c4 10             	add    $0x10,%esp
80103c2c:	85 c0                	test   %eax,%eax
80103c2e:	74 23                	je     80103c53 <release+0x3a>
  lk->pcs[0] = 0;
80103c30:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103c37:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103c3e:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103c43:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103c49:	e8 c6 fe ff ff       	call   80103b14 <popcli>
}
80103c4e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c51:	c9                   	leave  
80103c52:	c3                   	ret    
    panic("release");
80103c53:	83 ec 0c             	sub    $0xc,%esp
80103c56:	68 e9 6a 10 80       	push   $0x80106ae9
80103c5b:	e8 e8 c6 ff ff       	call   80100348 <panic>

80103c60 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103c60:	55                   	push   %ebp
80103c61:	89 e5                	mov    %esp,%ebp
80103c63:	57                   	push   %edi
80103c64:	53                   	push   %ebx
80103c65:	8b 55 08             	mov    0x8(%ebp),%edx
80103c68:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103c6b:	f6 c2 03             	test   $0x3,%dl
80103c6e:	75 05                	jne    80103c75 <memset+0x15>
80103c70:	f6 c1 03             	test   $0x3,%cl
80103c73:	74 0e                	je     80103c83 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103c75:	89 d7                	mov    %edx,%edi
80103c77:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c7a:	fc                   	cld    
80103c7b:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103c7d:	89 d0                	mov    %edx,%eax
80103c7f:	5b                   	pop    %ebx
80103c80:	5f                   	pop    %edi
80103c81:	5d                   	pop    %ebp
80103c82:	c3                   	ret    
    c &= 0xFF;
80103c83:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103c87:	c1 e9 02             	shr    $0x2,%ecx
80103c8a:	89 f8                	mov    %edi,%eax
80103c8c:	c1 e0 18             	shl    $0x18,%eax
80103c8f:	89 fb                	mov    %edi,%ebx
80103c91:	c1 e3 10             	shl    $0x10,%ebx
80103c94:	09 d8                	or     %ebx,%eax
80103c96:	89 fb                	mov    %edi,%ebx
80103c98:	c1 e3 08             	shl    $0x8,%ebx
80103c9b:	09 d8                	or     %ebx,%eax
80103c9d:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103c9f:	89 d7                	mov    %edx,%edi
80103ca1:	fc                   	cld    
80103ca2:	f3 ab                	rep stos %eax,%es:(%edi)
80103ca4:	eb d7                	jmp    80103c7d <memset+0x1d>

80103ca6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103ca6:	55                   	push   %ebp
80103ca7:	89 e5                	mov    %esp,%ebp
80103ca9:	56                   	push   %esi
80103caa:	53                   	push   %ebx
80103cab:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103cae:	8b 55 0c             	mov    0xc(%ebp),%edx
80103cb1:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103cb4:	8d 70 ff             	lea    -0x1(%eax),%esi
80103cb7:	85 c0                	test   %eax,%eax
80103cb9:	74 1c                	je     80103cd7 <memcmp+0x31>
    if(*s1 != *s2)
80103cbb:	0f b6 01             	movzbl (%ecx),%eax
80103cbe:	0f b6 1a             	movzbl (%edx),%ebx
80103cc1:	38 d8                	cmp    %bl,%al
80103cc3:	75 0a                	jne    80103ccf <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103cc5:	83 c1 01             	add    $0x1,%ecx
80103cc8:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103ccb:	89 f0                	mov    %esi,%eax
80103ccd:	eb e5                	jmp    80103cb4 <memcmp+0xe>
      return *s1 - *s2;
80103ccf:	0f b6 c0             	movzbl %al,%eax
80103cd2:	0f b6 db             	movzbl %bl,%ebx
80103cd5:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103cd7:	5b                   	pop    %ebx
80103cd8:	5e                   	pop    %esi
80103cd9:	5d                   	pop    %ebp
80103cda:	c3                   	ret    

80103cdb <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103cdb:	55                   	push   %ebp
80103cdc:	89 e5                	mov    %esp,%ebp
80103cde:	56                   	push   %esi
80103cdf:	53                   	push   %ebx
80103ce0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ce3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ce6:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103ce9:	39 c1                	cmp    %eax,%ecx
80103ceb:	73 3a                	jae    80103d27 <memmove+0x4c>
80103ced:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103cf0:	39 c3                	cmp    %eax,%ebx
80103cf2:	76 37                	jbe    80103d2b <memmove+0x50>
    s += n;
    d += n;
80103cf4:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103cf7:	eb 0d                	jmp    80103d06 <memmove+0x2b>
      *--d = *--s;
80103cf9:	83 eb 01             	sub    $0x1,%ebx
80103cfc:	83 e9 01             	sub    $0x1,%ecx
80103cff:	0f b6 13             	movzbl (%ebx),%edx
80103d02:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103d04:	89 f2                	mov    %esi,%edx
80103d06:	8d 72 ff             	lea    -0x1(%edx),%esi
80103d09:	85 d2                	test   %edx,%edx
80103d0b:	75 ec                	jne    80103cf9 <memmove+0x1e>
80103d0d:	eb 14                	jmp    80103d23 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103d0f:	0f b6 11             	movzbl (%ecx),%edx
80103d12:	88 13                	mov    %dl,(%ebx)
80103d14:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103d17:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103d1a:	89 f2                	mov    %esi,%edx
80103d1c:	8d 72 ff             	lea    -0x1(%edx),%esi
80103d1f:	85 d2                	test   %edx,%edx
80103d21:	75 ec                	jne    80103d0f <memmove+0x34>

  return dst;
}
80103d23:	5b                   	pop    %ebx
80103d24:	5e                   	pop    %esi
80103d25:	5d                   	pop    %ebp
80103d26:	c3                   	ret    
80103d27:	89 c3                	mov    %eax,%ebx
80103d29:	eb f1                	jmp    80103d1c <memmove+0x41>
80103d2b:	89 c3                	mov    %eax,%ebx
80103d2d:	eb ed                	jmp    80103d1c <memmove+0x41>

80103d2f <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103d2f:	55                   	push   %ebp
80103d30:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103d32:	ff 75 10             	pushl  0x10(%ebp)
80103d35:	ff 75 0c             	pushl  0xc(%ebp)
80103d38:	ff 75 08             	pushl  0x8(%ebp)
80103d3b:	e8 9b ff ff ff       	call   80103cdb <memmove>
}
80103d40:	c9                   	leave  
80103d41:	c3                   	ret    

80103d42 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103d42:	55                   	push   %ebp
80103d43:	89 e5                	mov    %esp,%ebp
80103d45:	53                   	push   %ebx
80103d46:	8b 55 08             	mov    0x8(%ebp),%edx
80103d49:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103d4c:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103d4f:	eb 09                	jmp    80103d5a <strncmp+0x18>
    n--, p++, q++;
80103d51:	83 e8 01             	sub    $0x1,%eax
80103d54:	83 c2 01             	add    $0x1,%edx
80103d57:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103d5a:	85 c0                	test   %eax,%eax
80103d5c:	74 0b                	je     80103d69 <strncmp+0x27>
80103d5e:	0f b6 1a             	movzbl (%edx),%ebx
80103d61:	84 db                	test   %bl,%bl
80103d63:	74 04                	je     80103d69 <strncmp+0x27>
80103d65:	3a 19                	cmp    (%ecx),%bl
80103d67:	74 e8                	je     80103d51 <strncmp+0xf>
  if(n == 0)
80103d69:	85 c0                	test   %eax,%eax
80103d6b:	74 0b                	je     80103d78 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103d6d:	0f b6 02             	movzbl (%edx),%eax
80103d70:	0f b6 11             	movzbl (%ecx),%edx
80103d73:	29 d0                	sub    %edx,%eax
}
80103d75:	5b                   	pop    %ebx
80103d76:	5d                   	pop    %ebp
80103d77:	c3                   	ret    
    return 0;
80103d78:	b8 00 00 00 00       	mov    $0x0,%eax
80103d7d:	eb f6                	jmp    80103d75 <strncmp+0x33>

80103d7f <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103d7f:	55                   	push   %ebp
80103d80:	89 e5                	mov    %esp,%ebp
80103d82:	57                   	push   %edi
80103d83:	56                   	push   %esi
80103d84:	53                   	push   %ebx
80103d85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103d88:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103d8b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d8e:	eb 04                	jmp    80103d94 <strncpy+0x15>
80103d90:	89 fb                	mov    %edi,%ebx
80103d92:	89 f0                	mov    %esi,%eax
80103d94:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d97:	85 c9                	test   %ecx,%ecx
80103d99:	7e 1d                	jle    80103db8 <strncpy+0x39>
80103d9b:	8d 7b 01             	lea    0x1(%ebx),%edi
80103d9e:	8d 70 01             	lea    0x1(%eax),%esi
80103da1:	0f b6 1b             	movzbl (%ebx),%ebx
80103da4:	88 18                	mov    %bl,(%eax)
80103da6:	89 d1                	mov    %edx,%ecx
80103da8:	84 db                	test   %bl,%bl
80103daa:	75 e4                	jne    80103d90 <strncpy+0x11>
80103dac:	89 f0                	mov    %esi,%eax
80103dae:	eb 08                	jmp    80103db8 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103db0:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103db3:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103db5:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103db8:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103dbb:	85 d2                	test   %edx,%edx
80103dbd:	7f f1                	jg     80103db0 <strncpy+0x31>
  return os;
}
80103dbf:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc2:	5b                   	pop    %ebx
80103dc3:	5e                   	pop    %esi
80103dc4:	5f                   	pop    %edi
80103dc5:	5d                   	pop    %ebp
80103dc6:	c3                   	ret    

80103dc7 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103dc7:	55                   	push   %ebp
80103dc8:	89 e5                	mov    %esp,%ebp
80103dca:	57                   	push   %edi
80103dcb:	56                   	push   %esi
80103dcc:	53                   	push   %ebx
80103dcd:	8b 45 08             	mov    0x8(%ebp),%eax
80103dd0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103dd3:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103dd6:	85 d2                	test   %edx,%edx
80103dd8:	7e 23                	jle    80103dfd <safestrcpy+0x36>
80103dda:	89 c1                	mov    %eax,%ecx
80103ddc:	eb 04                	jmp    80103de2 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103dde:	89 fb                	mov    %edi,%ebx
80103de0:	89 f1                	mov    %esi,%ecx
80103de2:	83 ea 01             	sub    $0x1,%edx
80103de5:	85 d2                	test   %edx,%edx
80103de7:	7e 11                	jle    80103dfa <safestrcpy+0x33>
80103de9:	8d 7b 01             	lea    0x1(%ebx),%edi
80103dec:	8d 71 01             	lea    0x1(%ecx),%esi
80103def:	0f b6 1b             	movzbl (%ebx),%ebx
80103df2:	88 19                	mov    %bl,(%ecx)
80103df4:	84 db                	test   %bl,%bl
80103df6:	75 e6                	jne    80103dde <safestrcpy+0x17>
80103df8:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103dfa:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103dfd:	5b                   	pop    %ebx
80103dfe:	5e                   	pop    %esi
80103dff:	5f                   	pop    %edi
80103e00:	5d                   	pop    %ebp
80103e01:	c3                   	ret    

80103e02 <strlen>:

int
strlen(const char *s)
{
80103e02:	55                   	push   %ebp
80103e03:	89 e5                	mov    %esp,%ebp
80103e05:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103e08:	b8 00 00 00 00       	mov    $0x0,%eax
80103e0d:	eb 03                	jmp    80103e12 <strlen+0x10>
80103e0f:	83 c0 01             	add    $0x1,%eax
80103e12:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103e16:	75 f7                	jne    80103e0f <strlen+0xd>
    ;
  return n;
}
80103e18:	5d                   	pop    %ebp
80103e19:	c3                   	ret    

80103e1a <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103e1a:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103e1e:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103e22:	55                   	push   %ebp
  pushl %ebx
80103e23:	53                   	push   %ebx
  pushl %esi
80103e24:	56                   	push   %esi
  pushl %edi
80103e25:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103e26:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103e28:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103e2a:	5f                   	pop    %edi
  popl %esi
80103e2b:	5e                   	pop    %esi
  popl %ebx
80103e2c:	5b                   	pop    %ebx
  popl %ebp
80103e2d:	5d                   	pop    %ebp
  ret
80103e2e:	c3                   	ret    

80103e2f <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103e2f:	55                   	push   %ebp
80103e30:	89 e5                	mov    %esp,%ebp
80103e32:	53                   	push   %ebx
80103e33:	83 ec 04             	sub    $0x4,%esp
80103e36:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103e39:	e8 d7 f3 ff ff       	call   80103215 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103e3e:	8b 00                	mov    (%eax),%eax
80103e40:	39 d8                	cmp    %ebx,%eax
80103e42:	76 19                	jbe    80103e5d <fetchint+0x2e>
80103e44:	8d 53 04             	lea    0x4(%ebx),%edx
80103e47:	39 d0                	cmp    %edx,%eax
80103e49:	72 19                	jb     80103e64 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103e4b:	8b 13                	mov    (%ebx),%edx
80103e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e50:	89 10                	mov    %edx,(%eax)
  return 0;
80103e52:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103e57:	83 c4 04             	add    $0x4,%esp
80103e5a:	5b                   	pop    %ebx
80103e5b:	5d                   	pop    %ebp
80103e5c:	c3                   	ret    
    return -1;
80103e5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e62:	eb f3                	jmp    80103e57 <fetchint+0x28>
80103e64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e69:	eb ec                	jmp    80103e57 <fetchint+0x28>

80103e6b <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103e6b:	55                   	push   %ebp
80103e6c:	89 e5                	mov    %esp,%ebp
80103e6e:	53                   	push   %ebx
80103e6f:	83 ec 04             	sub    $0x4,%esp
80103e72:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103e75:	e8 9b f3 ff ff       	call   80103215 <myproc>

  if(addr >= curproc->sz)
80103e7a:	39 18                	cmp    %ebx,(%eax)
80103e7c:	76 26                	jbe    80103ea4 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103e7e:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e81:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103e83:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103e85:	89 d8                	mov    %ebx,%eax
80103e87:	39 d0                	cmp    %edx,%eax
80103e89:	73 0e                	jae    80103e99 <fetchstr+0x2e>
    if(*s == 0)
80103e8b:	80 38 00             	cmpb   $0x0,(%eax)
80103e8e:	74 05                	je     80103e95 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103e90:	83 c0 01             	add    $0x1,%eax
80103e93:	eb f2                	jmp    80103e87 <fetchstr+0x1c>
      return s - *pp;
80103e95:	29 d8                	sub    %ebx,%eax
80103e97:	eb 05                	jmp    80103e9e <fetchstr+0x33>
  }
  return -1;
80103e99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103e9e:	83 c4 04             	add    $0x4,%esp
80103ea1:	5b                   	pop    %ebx
80103ea2:	5d                   	pop    %ebp
80103ea3:	c3                   	ret    
    return -1;
80103ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ea9:	eb f3                	jmp    80103e9e <fetchstr+0x33>

80103eab <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103eab:	55                   	push   %ebp
80103eac:	89 e5                	mov    %esp,%ebp
80103eae:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103eb1:	e8 5f f3 ff ff       	call   80103215 <myproc>
80103eb6:	8b 50 18             	mov    0x18(%eax),%edx
80103eb9:	8b 45 08             	mov    0x8(%ebp),%eax
80103ebc:	c1 e0 02             	shl    $0x2,%eax
80103ebf:	03 42 44             	add    0x44(%edx),%eax
80103ec2:	83 ec 08             	sub    $0x8,%esp
80103ec5:	ff 75 0c             	pushl  0xc(%ebp)
80103ec8:	83 c0 04             	add    $0x4,%eax
80103ecb:	50                   	push   %eax
80103ecc:	e8 5e ff ff ff       	call   80103e2f <fetchint>
}
80103ed1:	c9                   	leave  
80103ed2:	c3                   	ret    

80103ed3 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103ed3:	55                   	push   %ebp
80103ed4:	89 e5                	mov    %esp,%ebp
80103ed6:	56                   	push   %esi
80103ed7:	53                   	push   %ebx
80103ed8:	83 ec 10             	sub    $0x10,%esp
80103edb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103ede:	e8 32 f3 ff ff       	call   80103215 <myproc>
80103ee3:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103ee5:	83 ec 08             	sub    $0x8,%esp
80103ee8:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103eeb:	50                   	push   %eax
80103eec:	ff 75 08             	pushl  0x8(%ebp)
80103eef:	e8 b7 ff ff ff       	call   80103eab <argint>
80103ef4:	83 c4 10             	add    $0x10,%esp
80103ef7:	85 c0                	test   %eax,%eax
80103ef9:	78 24                	js     80103f1f <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103efb:	85 db                	test   %ebx,%ebx
80103efd:	78 27                	js     80103f26 <argptr+0x53>
80103eff:	8b 16                	mov    (%esi),%edx
80103f01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f04:	39 c2                	cmp    %eax,%edx
80103f06:	76 25                	jbe    80103f2d <argptr+0x5a>
80103f08:	01 c3                	add    %eax,%ebx
80103f0a:	39 da                	cmp    %ebx,%edx
80103f0c:	72 26                	jb     80103f34 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103f0e:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f11:	89 02                	mov    %eax,(%edx)
  return 0;
80103f13:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f18:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f1b:	5b                   	pop    %ebx
80103f1c:	5e                   	pop    %esi
80103f1d:	5d                   	pop    %ebp
80103f1e:	c3                   	ret    
    return -1;
80103f1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f24:	eb f2                	jmp    80103f18 <argptr+0x45>
    return -1;
80103f26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f2b:	eb eb                	jmp    80103f18 <argptr+0x45>
80103f2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f32:	eb e4                	jmp    80103f18 <argptr+0x45>
80103f34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f39:	eb dd                	jmp    80103f18 <argptr+0x45>

80103f3b <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80103f3b:	55                   	push   %ebp
80103f3c:	89 e5                	mov    %esp,%ebp
80103f3e:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80103f41:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103f44:	50                   	push   %eax
80103f45:	ff 75 08             	pushl  0x8(%ebp)
80103f48:	e8 5e ff ff ff       	call   80103eab <argint>
80103f4d:	83 c4 10             	add    $0x10,%esp
80103f50:	85 c0                	test   %eax,%eax
80103f52:	78 13                	js     80103f67 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80103f54:	83 ec 08             	sub    $0x8,%esp
80103f57:	ff 75 0c             	pushl  0xc(%ebp)
80103f5a:	ff 75 f4             	pushl  -0xc(%ebp)
80103f5d:	e8 09 ff ff ff       	call   80103e6b <fetchstr>
80103f62:	83 c4 10             	add    $0x10,%esp
}
80103f65:	c9                   	leave  
80103f66:	c3                   	ret    
    return -1;
80103f67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f6c:	eb f7                	jmp    80103f65 <argstr+0x2a>

80103f6e <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
80103f6e:	55                   	push   %ebp
80103f6f:	89 e5                	mov    %esp,%ebp
80103f71:	53                   	push   %ebx
80103f72:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80103f75:	e8 9b f2 ff ff       	call   80103215 <myproc>
80103f7a:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80103f7c:	8b 40 18             	mov    0x18(%eax),%eax
80103f7f:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80103f82:	8d 50 ff             	lea    -0x1(%eax),%edx
80103f85:	83 fa 15             	cmp    $0x15,%edx
80103f88:	77 18                	ja     80103fa2 <syscall+0x34>
80103f8a:	8b 14 85 20 6b 10 80 	mov    -0x7fef94e0(,%eax,4),%edx
80103f91:	85 d2                	test   %edx,%edx
80103f93:	74 0d                	je     80103fa2 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80103f95:	ff d2                	call   *%edx
80103f97:	8b 53 18             	mov    0x18(%ebx),%edx
80103f9a:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80103f9d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103fa0:	c9                   	leave  
80103fa1:	c3                   	ret    
            curproc->pid, curproc->name, num);
80103fa2:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80103fa5:	50                   	push   %eax
80103fa6:	52                   	push   %edx
80103fa7:	ff 73 10             	pushl  0x10(%ebx)
80103faa:	68 f1 6a 10 80       	push   $0x80106af1
80103faf:	e8 57 c6 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80103fb4:	8b 43 18             	mov    0x18(%ebx),%eax
80103fb7:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80103fbe:	83 c4 10             	add    $0x10,%esp
}
80103fc1:	eb da                	jmp    80103f9d <syscall+0x2f>

80103fc3 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80103fc3:	55                   	push   %ebp
80103fc4:	89 e5                	mov    %esp,%ebp
80103fc6:	56                   	push   %esi
80103fc7:	53                   	push   %ebx
80103fc8:	83 ec 18             	sub    $0x18,%esp
80103fcb:	89 d6                	mov    %edx,%esi
80103fcd:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80103fcf:	8d 55 f4             	lea    -0xc(%ebp),%edx
80103fd2:	52                   	push   %edx
80103fd3:	50                   	push   %eax
80103fd4:	e8 d2 fe ff ff       	call   80103eab <argint>
80103fd9:	83 c4 10             	add    $0x10,%esp
80103fdc:	85 c0                	test   %eax,%eax
80103fde:	78 2e                	js     8010400e <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80103fe0:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80103fe4:	77 2f                	ja     80104015 <argfd+0x52>
80103fe6:	e8 2a f2 ff ff       	call   80103215 <myproc>
80103feb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103fee:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80103ff2:	85 c0                	test   %eax,%eax
80103ff4:	74 26                	je     8010401c <argfd+0x59>
    return -1;
  if(pfd)
80103ff6:	85 f6                	test   %esi,%esi
80103ff8:	74 02                	je     80103ffc <argfd+0x39>
    *pfd = fd;
80103ffa:	89 16                	mov    %edx,(%esi)
  if(pf)
80103ffc:	85 db                	test   %ebx,%ebx
80103ffe:	74 23                	je     80104023 <argfd+0x60>
    *pf = f;
80104000:	89 03                	mov    %eax,(%ebx)
  return 0;
80104002:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104007:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010400a:	5b                   	pop    %ebx
8010400b:	5e                   	pop    %esi
8010400c:	5d                   	pop    %ebp
8010400d:	c3                   	ret    
    return -1;
8010400e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104013:	eb f2                	jmp    80104007 <argfd+0x44>
    return -1;
80104015:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010401a:	eb eb                	jmp    80104007 <argfd+0x44>
8010401c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104021:	eb e4                	jmp    80104007 <argfd+0x44>
  return 0;
80104023:	b8 00 00 00 00       	mov    $0x0,%eax
80104028:	eb dd                	jmp    80104007 <argfd+0x44>

8010402a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010402a:	55                   	push   %ebp
8010402b:	89 e5                	mov    %esp,%ebp
8010402d:	53                   	push   %ebx
8010402e:	83 ec 04             	sub    $0x4,%esp
80104031:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104033:	e8 dd f1 ff ff       	call   80103215 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104038:	ba 00 00 00 00       	mov    $0x0,%edx
8010403d:	83 fa 0f             	cmp    $0xf,%edx
80104040:	7f 18                	jg     8010405a <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104042:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104047:	74 05                	je     8010404e <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104049:	83 c2 01             	add    $0x1,%edx
8010404c:	eb ef                	jmp    8010403d <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010404e:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104052:	89 d0                	mov    %edx,%eax
80104054:	83 c4 04             	add    $0x4,%esp
80104057:	5b                   	pop    %ebx
80104058:	5d                   	pop    %ebp
80104059:	c3                   	ret    
  return -1;
8010405a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
8010405f:	eb f1                	jmp    80104052 <fdalloc+0x28>

80104061 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104061:	55                   	push   %ebp
80104062:	89 e5                	mov    %esp,%ebp
80104064:	56                   	push   %esi
80104065:	53                   	push   %ebx
80104066:	83 ec 10             	sub    $0x10,%esp
80104069:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010406b:	b8 20 00 00 00       	mov    $0x20,%eax
80104070:	89 c6                	mov    %eax,%esi
80104072:	39 43 58             	cmp    %eax,0x58(%ebx)
80104075:	76 2e                	jbe    801040a5 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104077:	6a 10                	push   $0x10
80104079:	50                   	push   %eax
8010407a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010407d:	50                   	push   %eax
8010407e:	53                   	push   %ebx
8010407f:	e8 ef d6 ff ff       	call   80101773 <readi>
80104084:	83 c4 10             	add    $0x10,%esp
80104087:	83 f8 10             	cmp    $0x10,%eax
8010408a:	75 0c                	jne    80104098 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
8010408c:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104091:	75 1e                	jne    801040b1 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104093:	8d 46 10             	lea    0x10(%esi),%eax
80104096:	eb d8                	jmp    80104070 <isdirempty+0xf>
      panic("isdirempty: readi");
80104098:	83 ec 0c             	sub    $0xc,%esp
8010409b:	68 7c 6b 10 80       	push   $0x80106b7c
801040a0:	e8 a3 c2 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801040a5:	b8 01 00 00 00       	mov    $0x1,%eax
}
801040aa:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040ad:	5b                   	pop    %ebx
801040ae:	5e                   	pop    %esi
801040af:	5d                   	pop    %ebp
801040b0:	c3                   	ret    
      return 0;
801040b1:	b8 00 00 00 00       	mov    $0x0,%eax
801040b6:	eb f2                	jmp    801040aa <isdirempty+0x49>

801040b8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801040b8:	55                   	push   %ebp
801040b9:	89 e5                	mov    %esp,%ebp
801040bb:	57                   	push   %edi
801040bc:	56                   	push   %esi
801040bd:	53                   	push   %ebx
801040be:	83 ec 44             	sub    $0x44,%esp
801040c1:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801040c4:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801040c7:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801040ca:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801040cd:	52                   	push   %edx
801040ce:	50                   	push   %eax
801040cf:	e8 25 db ff ff       	call   80101bf9 <nameiparent>
801040d4:	89 c6                	mov    %eax,%esi
801040d6:	83 c4 10             	add    $0x10,%esp
801040d9:	85 c0                	test   %eax,%eax
801040db:	0f 84 3a 01 00 00    	je     8010421b <create+0x163>
    return 0;
  ilock(dp);
801040e1:	83 ec 0c             	sub    $0xc,%esp
801040e4:	50                   	push   %eax
801040e5:	e8 97 d4 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801040ea:	83 c4 0c             	add    $0xc,%esp
801040ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801040f0:	50                   	push   %eax
801040f1:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801040f4:	50                   	push   %eax
801040f5:	56                   	push   %esi
801040f6:	e8 b5 d8 ff ff       	call   801019b0 <dirlookup>
801040fb:	89 c3                	mov    %eax,%ebx
801040fd:	83 c4 10             	add    $0x10,%esp
80104100:	85 c0                	test   %eax,%eax
80104102:	74 3f                	je     80104143 <create+0x8b>
    iunlockput(dp);
80104104:	83 ec 0c             	sub    $0xc,%esp
80104107:	56                   	push   %esi
80104108:	e8 1b d6 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010410d:	89 1c 24             	mov    %ebx,(%esp)
80104110:	e8 6c d4 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104115:	83 c4 10             	add    $0x10,%esp
80104118:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010411d:	75 11                	jne    80104130 <create+0x78>
8010411f:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104124:	75 0a                	jne    80104130 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104126:	89 d8                	mov    %ebx,%eax
80104128:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010412b:	5b                   	pop    %ebx
8010412c:	5e                   	pop    %esi
8010412d:	5f                   	pop    %edi
8010412e:	5d                   	pop    %ebp
8010412f:	c3                   	ret    
    iunlockput(ip);
80104130:	83 ec 0c             	sub    $0xc,%esp
80104133:	53                   	push   %ebx
80104134:	e8 ef d5 ff ff       	call   80101728 <iunlockput>
    return 0;
80104139:	83 c4 10             	add    $0x10,%esp
8010413c:	bb 00 00 00 00       	mov    $0x0,%ebx
80104141:	eb e3                	jmp    80104126 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104143:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104147:	83 ec 08             	sub    $0x8,%esp
8010414a:	50                   	push   %eax
8010414b:	ff 36                	pushl  (%esi)
8010414d:	e8 2c d2 ff ff       	call   8010137e <ialloc>
80104152:	89 c3                	mov    %eax,%ebx
80104154:	83 c4 10             	add    $0x10,%esp
80104157:	85 c0                	test   %eax,%eax
80104159:	74 55                	je     801041b0 <create+0xf8>
  ilock(ip);
8010415b:	83 ec 0c             	sub    $0xc,%esp
8010415e:	50                   	push   %eax
8010415f:	e8 1d d4 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104164:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104168:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010416c:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104170:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104176:	89 1c 24             	mov    %ebx,(%esp)
80104179:	e8 a2 d2 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010417e:	83 c4 10             	add    $0x10,%esp
80104181:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104186:	74 35                	je     801041bd <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104188:	83 ec 04             	sub    $0x4,%esp
8010418b:	ff 73 04             	pushl  0x4(%ebx)
8010418e:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104191:	50                   	push   %eax
80104192:	56                   	push   %esi
80104193:	e8 98 d9 ff ff       	call   80101b30 <dirlink>
80104198:	83 c4 10             	add    $0x10,%esp
8010419b:	85 c0                	test   %eax,%eax
8010419d:	78 6f                	js     8010420e <create+0x156>
  iunlockput(dp);
8010419f:	83 ec 0c             	sub    $0xc,%esp
801041a2:	56                   	push   %esi
801041a3:	e8 80 d5 ff ff       	call   80101728 <iunlockput>
  return ip;
801041a8:	83 c4 10             	add    $0x10,%esp
801041ab:	e9 76 ff ff ff       	jmp    80104126 <create+0x6e>
    panic("create: ialloc");
801041b0:	83 ec 0c             	sub    $0xc,%esp
801041b3:	68 8e 6b 10 80       	push   $0x80106b8e
801041b8:	e8 8b c1 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801041bd:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801041c1:	83 c0 01             	add    $0x1,%eax
801041c4:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801041c8:	83 ec 0c             	sub    $0xc,%esp
801041cb:	56                   	push   %esi
801041cc:	e8 4f d2 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801041d1:	83 c4 0c             	add    $0xc,%esp
801041d4:	ff 73 04             	pushl  0x4(%ebx)
801041d7:	68 9e 6b 10 80       	push   $0x80106b9e
801041dc:	53                   	push   %ebx
801041dd:	e8 4e d9 ff ff       	call   80101b30 <dirlink>
801041e2:	83 c4 10             	add    $0x10,%esp
801041e5:	85 c0                	test   %eax,%eax
801041e7:	78 18                	js     80104201 <create+0x149>
801041e9:	83 ec 04             	sub    $0x4,%esp
801041ec:	ff 76 04             	pushl  0x4(%esi)
801041ef:	68 9d 6b 10 80       	push   $0x80106b9d
801041f4:	53                   	push   %ebx
801041f5:	e8 36 d9 ff ff       	call   80101b30 <dirlink>
801041fa:	83 c4 10             	add    $0x10,%esp
801041fd:	85 c0                	test   %eax,%eax
801041ff:	79 87                	jns    80104188 <create+0xd0>
      panic("create dots");
80104201:	83 ec 0c             	sub    $0xc,%esp
80104204:	68 a0 6b 10 80       	push   $0x80106ba0
80104209:	e8 3a c1 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010420e:	83 ec 0c             	sub    $0xc,%esp
80104211:	68 ac 6b 10 80       	push   $0x80106bac
80104216:	e8 2d c1 ff ff       	call   80100348 <panic>
    return 0;
8010421b:	89 c3                	mov    %eax,%ebx
8010421d:	e9 04 ff ff ff       	jmp    80104126 <create+0x6e>

80104222 <sys_dup>:
{
80104222:	55                   	push   %ebp
80104223:	89 e5                	mov    %esp,%ebp
80104225:	53                   	push   %ebx
80104226:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104229:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010422c:	ba 00 00 00 00       	mov    $0x0,%edx
80104231:	b8 00 00 00 00       	mov    $0x0,%eax
80104236:	e8 88 fd ff ff       	call   80103fc3 <argfd>
8010423b:	85 c0                	test   %eax,%eax
8010423d:	78 23                	js     80104262 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010423f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104242:	e8 e3 fd ff ff       	call   8010402a <fdalloc>
80104247:	89 c3                	mov    %eax,%ebx
80104249:	85 c0                	test   %eax,%eax
8010424b:	78 1c                	js     80104269 <sys_dup+0x47>
  filedup(f);
8010424d:	83 ec 0c             	sub    $0xc,%esp
80104250:	ff 75 f4             	pushl  -0xc(%ebp)
80104253:	e8 36 ca ff ff       	call   80100c8e <filedup>
  return fd;
80104258:	83 c4 10             	add    $0x10,%esp
}
8010425b:	89 d8                	mov    %ebx,%eax
8010425d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104260:	c9                   	leave  
80104261:	c3                   	ret    
    return -1;
80104262:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104267:	eb f2                	jmp    8010425b <sys_dup+0x39>
    return -1;
80104269:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010426e:	eb eb                	jmp    8010425b <sys_dup+0x39>

80104270 <sys_read>:
{
80104270:	55                   	push   %ebp
80104271:	89 e5                	mov    %esp,%ebp
80104273:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104276:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104279:	ba 00 00 00 00       	mov    $0x0,%edx
8010427e:	b8 00 00 00 00       	mov    $0x0,%eax
80104283:	e8 3b fd ff ff       	call   80103fc3 <argfd>
80104288:	85 c0                	test   %eax,%eax
8010428a:	78 43                	js     801042cf <sys_read+0x5f>
8010428c:	83 ec 08             	sub    $0x8,%esp
8010428f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104292:	50                   	push   %eax
80104293:	6a 02                	push   $0x2
80104295:	e8 11 fc ff ff       	call   80103eab <argint>
8010429a:	83 c4 10             	add    $0x10,%esp
8010429d:	85 c0                	test   %eax,%eax
8010429f:	78 35                	js     801042d6 <sys_read+0x66>
801042a1:	83 ec 04             	sub    $0x4,%esp
801042a4:	ff 75 f0             	pushl  -0x10(%ebp)
801042a7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801042aa:	50                   	push   %eax
801042ab:	6a 01                	push   $0x1
801042ad:	e8 21 fc ff ff       	call   80103ed3 <argptr>
801042b2:	83 c4 10             	add    $0x10,%esp
801042b5:	85 c0                	test   %eax,%eax
801042b7:	78 24                	js     801042dd <sys_read+0x6d>
  return fileread(f, p, n);
801042b9:	83 ec 04             	sub    $0x4,%esp
801042bc:	ff 75 f0             	pushl  -0x10(%ebp)
801042bf:	ff 75 ec             	pushl  -0x14(%ebp)
801042c2:	ff 75 f4             	pushl  -0xc(%ebp)
801042c5:	e8 0d cb ff ff       	call   80100dd7 <fileread>
801042ca:	83 c4 10             	add    $0x10,%esp
}
801042cd:	c9                   	leave  
801042ce:	c3                   	ret    
    return -1;
801042cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042d4:	eb f7                	jmp    801042cd <sys_read+0x5d>
801042d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042db:	eb f0                	jmp    801042cd <sys_read+0x5d>
801042dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042e2:	eb e9                	jmp    801042cd <sys_read+0x5d>

801042e4 <sys_write>:
{
801042e4:	55                   	push   %ebp
801042e5:	89 e5                	mov    %esp,%ebp
801042e7:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801042ea:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042ed:	ba 00 00 00 00       	mov    $0x0,%edx
801042f2:	b8 00 00 00 00       	mov    $0x0,%eax
801042f7:	e8 c7 fc ff ff       	call   80103fc3 <argfd>
801042fc:	85 c0                	test   %eax,%eax
801042fe:	78 43                	js     80104343 <sys_write+0x5f>
80104300:	83 ec 08             	sub    $0x8,%esp
80104303:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104306:	50                   	push   %eax
80104307:	6a 02                	push   $0x2
80104309:	e8 9d fb ff ff       	call   80103eab <argint>
8010430e:	83 c4 10             	add    $0x10,%esp
80104311:	85 c0                	test   %eax,%eax
80104313:	78 35                	js     8010434a <sys_write+0x66>
80104315:	83 ec 04             	sub    $0x4,%esp
80104318:	ff 75 f0             	pushl  -0x10(%ebp)
8010431b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010431e:	50                   	push   %eax
8010431f:	6a 01                	push   $0x1
80104321:	e8 ad fb ff ff       	call   80103ed3 <argptr>
80104326:	83 c4 10             	add    $0x10,%esp
80104329:	85 c0                	test   %eax,%eax
8010432b:	78 24                	js     80104351 <sys_write+0x6d>
  return filewrite(f, p, n);
8010432d:	83 ec 04             	sub    $0x4,%esp
80104330:	ff 75 f0             	pushl  -0x10(%ebp)
80104333:	ff 75 ec             	pushl  -0x14(%ebp)
80104336:	ff 75 f4             	pushl  -0xc(%ebp)
80104339:	e8 1e cb ff ff       	call   80100e5c <filewrite>
8010433e:	83 c4 10             	add    $0x10,%esp
}
80104341:	c9                   	leave  
80104342:	c3                   	ret    
    return -1;
80104343:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104348:	eb f7                	jmp    80104341 <sys_write+0x5d>
8010434a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010434f:	eb f0                	jmp    80104341 <sys_write+0x5d>
80104351:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104356:	eb e9                	jmp    80104341 <sys_write+0x5d>

80104358 <sys_close>:
{
80104358:	55                   	push   %ebp
80104359:	89 e5                	mov    %esp,%ebp
8010435b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010435e:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104361:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104364:	b8 00 00 00 00       	mov    $0x0,%eax
80104369:	e8 55 fc ff ff       	call   80103fc3 <argfd>
8010436e:	85 c0                	test   %eax,%eax
80104370:	78 25                	js     80104397 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104372:	e8 9e ee ff ff       	call   80103215 <myproc>
80104377:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010437a:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104381:	00 
  fileclose(f);
80104382:	83 ec 0c             	sub    $0xc,%esp
80104385:	ff 75 f0             	pushl  -0x10(%ebp)
80104388:	e8 46 c9 ff ff       	call   80100cd3 <fileclose>
  return 0;
8010438d:	83 c4 10             	add    $0x10,%esp
80104390:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104395:	c9                   	leave  
80104396:	c3                   	ret    
    return -1;
80104397:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010439c:	eb f7                	jmp    80104395 <sys_close+0x3d>

8010439e <sys_fstat>:
{
8010439e:	55                   	push   %ebp
8010439f:	89 e5                	mov    %esp,%ebp
801043a1:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801043a4:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043a7:	ba 00 00 00 00       	mov    $0x0,%edx
801043ac:	b8 00 00 00 00       	mov    $0x0,%eax
801043b1:	e8 0d fc ff ff       	call   80103fc3 <argfd>
801043b6:	85 c0                	test   %eax,%eax
801043b8:	78 2a                	js     801043e4 <sys_fstat+0x46>
801043ba:	83 ec 04             	sub    $0x4,%esp
801043bd:	6a 14                	push   $0x14
801043bf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043c2:	50                   	push   %eax
801043c3:	6a 01                	push   $0x1
801043c5:	e8 09 fb ff ff       	call   80103ed3 <argptr>
801043ca:	83 c4 10             	add    $0x10,%esp
801043cd:	85 c0                	test   %eax,%eax
801043cf:	78 1a                	js     801043eb <sys_fstat+0x4d>
  return filestat(f, st);
801043d1:	83 ec 08             	sub    $0x8,%esp
801043d4:	ff 75 f0             	pushl  -0x10(%ebp)
801043d7:	ff 75 f4             	pushl  -0xc(%ebp)
801043da:	e8 b1 c9 ff ff       	call   80100d90 <filestat>
801043df:	83 c4 10             	add    $0x10,%esp
}
801043e2:	c9                   	leave  
801043e3:	c3                   	ret    
    return -1;
801043e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043e9:	eb f7                	jmp    801043e2 <sys_fstat+0x44>
801043eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f0:	eb f0                	jmp    801043e2 <sys_fstat+0x44>

801043f2 <sys_link>:
{
801043f2:	55                   	push   %ebp
801043f3:	89 e5                	mov    %esp,%ebp
801043f5:	56                   	push   %esi
801043f6:	53                   	push   %ebx
801043f7:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801043fa:	8d 45 e0             	lea    -0x20(%ebp),%eax
801043fd:	50                   	push   %eax
801043fe:	6a 00                	push   $0x0
80104400:	e8 36 fb ff ff       	call   80103f3b <argstr>
80104405:	83 c4 10             	add    $0x10,%esp
80104408:	85 c0                	test   %eax,%eax
8010440a:	0f 88 32 01 00 00    	js     80104542 <sys_link+0x150>
80104410:	83 ec 08             	sub    $0x8,%esp
80104413:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104416:	50                   	push   %eax
80104417:	6a 01                	push   $0x1
80104419:	e8 1d fb ff ff       	call   80103f3b <argstr>
8010441e:	83 c4 10             	add    $0x10,%esp
80104421:	85 c0                	test   %eax,%eax
80104423:	0f 88 20 01 00 00    	js     80104549 <sys_link+0x157>
  begin_op();
80104429:	e8 9f e3 ff ff       	call   801027cd <begin_op>
  if((ip = namei(old)) == 0){
8010442e:	83 ec 0c             	sub    $0xc,%esp
80104431:	ff 75 e0             	pushl  -0x20(%ebp)
80104434:	e8 a8 d7 ff ff       	call   80101be1 <namei>
80104439:	89 c3                	mov    %eax,%ebx
8010443b:	83 c4 10             	add    $0x10,%esp
8010443e:	85 c0                	test   %eax,%eax
80104440:	0f 84 99 00 00 00    	je     801044df <sys_link+0xed>
  ilock(ip);
80104446:	83 ec 0c             	sub    $0xc,%esp
80104449:	50                   	push   %eax
8010444a:	e8 32 d1 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010444f:	83 c4 10             	add    $0x10,%esp
80104452:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104457:	0f 84 8e 00 00 00    	je     801044eb <sys_link+0xf9>
  ip->nlink++;
8010445d:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104461:	83 c0 01             	add    $0x1,%eax
80104464:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104468:	83 ec 0c             	sub    $0xc,%esp
8010446b:	53                   	push   %ebx
8010446c:	e8 af cf ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104471:	89 1c 24             	mov    %ebx,(%esp)
80104474:	e8 ca d1 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104479:	83 c4 08             	add    $0x8,%esp
8010447c:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010447f:	50                   	push   %eax
80104480:	ff 75 e4             	pushl  -0x1c(%ebp)
80104483:	e8 71 d7 ff ff       	call   80101bf9 <nameiparent>
80104488:	89 c6                	mov    %eax,%esi
8010448a:	83 c4 10             	add    $0x10,%esp
8010448d:	85 c0                	test   %eax,%eax
8010448f:	74 7e                	je     8010450f <sys_link+0x11d>
  ilock(dp);
80104491:	83 ec 0c             	sub    $0xc,%esp
80104494:	50                   	push   %eax
80104495:	e8 e7 d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010449a:	83 c4 10             	add    $0x10,%esp
8010449d:	8b 03                	mov    (%ebx),%eax
8010449f:	39 06                	cmp    %eax,(%esi)
801044a1:	75 60                	jne    80104503 <sys_link+0x111>
801044a3:	83 ec 04             	sub    $0x4,%esp
801044a6:	ff 73 04             	pushl  0x4(%ebx)
801044a9:	8d 45 ea             	lea    -0x16(%ebp),%eax
801044ac:	50                   	push   %eax
801044ad:	56                   	push   %esi
801044ae:	e8 7d d6 ff ff       	call   80101b30 <dirlink>
801044b3:	83 c4 10             	add    $0x10,%esp
801044b6:	85 c0                	test   %eax,%eax
801044b8:	78 49                	js     80104503 <sys_link+0x111>
  iunlockput(dp);
801044ba:	83 ec 0c             	sub    $0xc,%esp
801044bd:	56                   	push   %esi
801044be:	e8 65 d2 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801044c3:	89 1c 24             	mov    %ebx,(%esp)
801044c6:	e8 bd d1 ff ff       	call   80101688 <iput>
  end_op();
801044cb:	e8 77 e3 ff ff       	call   80102847 <end_op>
  return 0;
801044d0:	83 c4 10             	add    $0x10,%esp
801044d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801044db:	5b                   	pop    %ebx
801044dc:	5e                   	pop    %esi
801044dd:	5d                   	pop    %ebp
801044de:	c3                   	ret    
    end_op();
801044df:	e8 63 e3 ff ff       	call   80102847 <end_op>
    return -1;
801044e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044e9:	eb ed                	jmp    801044d8 <sys_link+0xe6>
    iunlockput(ip);
801044eb:	83 ec 0c             	sub    $0xc,%esp
801044ee:	53                   	push   %ebx
801044ef:	e8 34 d2 ff ff       	call   80101728 <iunlockput>
    end_op();
801044f4:	e8 4e e3 ff ff       	call   80102847 <end_op>
    return -1;
801044f9:	83 c4 10             	add    $0x10,%esp
801044fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104501:	eb d5                	jmp    801044d8 <sys_link+0xe6>
    iunlockput(dp);
80104503:	83 ec 0c             	sub    $0xc,%esp
80104506:	56                   	push   %esi
80104507:	e8 1c d2 ff ff       	call   80101728 <iunlockput>
    goto bad;
8010450c:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010450f:	83 ec 0c             	sub    $0xc,%esp
80104512:	53                   	push   %ebx
80104513:	e8 69 d0 ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104518:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010451c:	83 e8 01             	sub    $0x1,%eax
8010451f:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104523:	89 1c 24             	mov    %ebx,(%esp)
80104526:	e8 f5 ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010452b:	89 1c 24             	mov    %ebx,(%esp)
8010452e:	e8 f5 d1 ff ff       	call   80101728 <iunlockput>
  end_op();
80104533:	e8 0f e3 ff ff       	call   80102847 <end_op>
  return -1;
80104538:	83 c4 10             	add    $0x10,%esp
8010453b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104540:	eb 96                	jmp    801044d8 <sys_link+0xe6>
    return -1;
80104542:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104547:	eb 8f                	jmp    801044d8 <sys_link+0xe6>
80104549:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010454e:	eb 88                	jmp    801044d8 <sys_link+0xe6>

80104550 <sys_unlink>:
{
80104550:	55                   	push   %ebp
80104551:	89 e5                	mov    %esp,%ebp
80104553:	57                   	push   %edi
80104554:	56                   	push   %esi
80104555:	53                   	push   %ebx
80104556:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104559:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010455c:	50                   	push   %eax
8010455d:	6a 00                	push   $0x0
8010455f:	e8 d7 f9 ff ff       	call   80103f3b <argstr>
80104564:	83 c4 10             	add    $0x10,%esp
80104567:	85 c0                	test   %eax,%eax
80104569:	0f 88 83 01 00 00    	js     801046f2 <sys_unlink+0x1a2>
  begin_op();
8010456f:	e8 59 e2 ff ff       	call   801027cd <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104574:	83 ec 08             	sub    $0x8,%esp
80104577:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010457a:	50                   	push   %eax
8010457b:	ff 75 c4             	pushl  -0x3c(%ebp)
8010457e:	e8 76 d6 ff ff       	call   80101bf9 <nameiparent>
80104583:	89 c6                	mov    %eax,%esi
80104585:	83 c4 10             	add    $0x10,%esp
80104588:	85 c0                	test   %eax,%eax
8010458a:	0f 84 ed 00 00 00    	je     8010467d <sys_unlink+0x12d>
  ilock(dp);
80104590:	83 ec 0c             	sub    $0xc,%esp
80104593:	50                   	push   %eax
80104594:	e8 e8 cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104599:	83 c4 08             	add    $0x8,%esp
8010459c:	68 9e 6b 10 80       	push   $0x80106b9e
801045a1:	8d 45 ca             	lea    -0x36(%ebp),%eax
801045a4:	50                   	push   %eax
801045a5:	e8 f1 d3 ff ff       	call   8010199b <namecmp>
801045aa:	83 c4 10             	add    $0x10,%esp
801045ad:	85 c0                	test   %eax,%eax
801045af:	0f 84 fc 00 00 00    	je     801046b1 <sys_unlink+0x161>
801045b5:	83 ec 08             	sub    $0x8,%esp
801045b8:	68 9d 6b 10 80       	push   $0x80106b9d
801045bd:	8d 45 ca             	lea    -0x36(%ebp),%eax
801045c0:	50                   	push   %eax
801045c1:	e8 d5 d3 ff ff       	call   8010199b <namecmp>
801045c6:	83 c4 10             	add    $0x10,%esp
801045c9:	85 c0                	test   %eax,%eax
801045cb:	0f 84 e0 00 00 00    	je     801046b1 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801045d1:	83 ec 04             	sub    $0x4,%esp
801045d4:	8d 45 c0             	lea    -0x40(%ebp),%eax
801045d7:	50                   	push   %eax
801045d8:	8d 45 ca             	lea    -0x36(%ebp),%eax
801045db:	50                   	push   %eax
801045dc:	56                   	push   %esi
801045dd:	e8 ce d3 ff ff       	call   801019b0 <dirlookup>
801045e2:	89 c3                	mov    %eax,%ebx
801045e4:	83 c4 10             	add    $0x10,%esp
801045e7:	85 c0                	test   %eax,%eax
801045e9:	0f 84 c2 00 00 00    	je     801046b1 <sys_unlink+0x161>
  ilock(ip);
801045ef:	83 ec 0c             	sub    $0xc,%esp
801045f2:	50                   	push   %eax
801045f3:	e8 89 cf ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801045f8:	83 c4 10             	add    $0x10,%esp
801045fb:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104600:	0f 8e 83 00 00 00    	jle    80104689 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104606:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010460b:	0f 84 85 00 00 00    	je     80104696 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104611:	83 ec 04             	sub    $0x4,%esp
80104614:	6a 10                	push   $0x10
80104616:	6a 00                	push   $0x0
80104618:	8d 7d d8             	lea    -0x28(%ebp),%edi
8010461b:	57                   	push   %edi
8010461c:	e8 3f f6 ff ff       	call   80103c60 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104621:	6a 10                	push   $0x10
80104623:	ff 75 c0             	pushl  -0x40(%ebp)
80104626:	57                   	push   %edi
80104627:	56                   	push   %esi
80104628:	e8 43 d2 ff ff       	call   80101870 <writei>
8010462d:	83 c4 20             	add    $0x20,%esp
80104630:	83 f8 10             	cmp    $0x10,%eax
80104633:	0f 85 90 00 00 00    	jne    801046c9 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104639:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010463e:	0f 84 92 00 00 00    	je     801046d6 <sys_unlink+0x186>
  iunlockput(dp);
80104644:	83 ec 0c             	sub    $0xc,%esp
80104647:	56                   	push   %esi
80104648:	e8 db d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010464d:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104651:	83 e8 01             	sub    $0x1,%eax
80104654:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104658:	89 1c 24             	mov    %ebx,(%esp)
8010465b:	e8 c0 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104660:	89 1c 24             	mov    %ebx,(%esp)
80104663:	e8 c0 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
80104668:	e8 da e1 ff ff       	call   80102847 <end_op>
  return 0;
8010466d:	83 c4 10             	add    $0x10,%esp
80104670:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104675:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104678:	5b                   	pop    %ebx
80104679:	5e                   	pop    %esi
8010467a:	5f                   	pop    %edi
8010467b:	5d                   	pop    %ebp
8010467c:	c3                   	ret    
    end_op();
8010467d:	e8 c5 e1 ff ff       	call   80102847 <end_op>
    return -1;
80104682:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104687:	eb ec                	jmp    80104675 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104689:	83 ec 0c             	sub    $0xc,%esp
8010468c:	68 bc 6b 10 80       	push   $0x80106bbc
80104691:	e8 b2 bc ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104696:	89 d8                	mov    %ebx,%eax
80104698:	e8 c4 f9 ff ff       	call   80104061 <isdirempty>
8010469d:	85 c0                	test   %eax,%eax
8010469f:	0f 85 6c ff ff ff    	jne    80104611 <sys_unlink+0xc1>
    iunlockput(ip);
801046a5:	83 ec 0c             	sub    $0xc,%esp
801046a8:	53                   	push   %ebx
801046a9:	e8 7a d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
801046ae:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801046b1:	83 ec 0c             	sub    $0xc,%esp
801046b4:	56                   	push   %esi
801046b5:	e8 6e d0 ff ff       	call   80101728 <iunlockput>
  end_op();
801046ba:	e8 88 e1 ff ff       	call   80102847 <end_op>
  return -1;
801046bf:	83 c4 10             	add    $0x10,%esp
801046c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046c7:	eb ac                	jmp    80104675 <sys_unlink+0x125>
    panic("unlink: writei");
801046c9:	83 ec 0c             	sub    $0xc,%esp
801046cc:	68 ce 6b 10 80       	push   $0x80106bce
801046d1:	e8 72 bc ff ff       	call   80100348 <panic>
    dp->nlink--;
801046d6:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801046da:	83 e8 01             	sub    $0x1,%eax
801046dd:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801046e1:	83 ec 0c             	sub    $0xc,%esp
801046e4:	56                   	push   %esi
801046e5:	e8 36 cd ff ff       	call   80101420 <iupdate>
801046ea:	83 c4 10             	add    $0x10,%esp
801046ed:	e9 52 ff ff ff       	jmp    80104644 <sys_unlink+0xf4>
    return -1;
801046f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046f7:	e9 79 ff ff ff       	jmp    80104675 <sys_unlink+0x125>

801046fc <sys_open>:

int
sys_open(void)
{
801046fc:	55                   	push   %ebp
801046fd:	89 e5                	mov    %esp,%ebp
801046ff:	57                   	push   %edi
80104700:	56                   	push   %esi
80104701:	53                   	push   %ebx
80104702:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104705:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104708:	50                   	push   %eax
80104709:	6a 00                	push   $0x0
8010470b:	e8 2b f8 ff ff       	call   80103f3b <argstr>
80104710:	83 c4 10             	add    $0x10,%esp
80104713:	85 c0                	test   %eax,%eax
80104715:	0f 88 30 01 00 00    	js     8010484b <sys_open+0x14f>
8010471b:	83 ec 08             	sub    $0x8,%esp
8010471e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104721:	50                   	push   %eax
80104722:	6a 01                	push   $0x1
80104724:	e8 82 f7 ff ff       	call   80103eab <argint>
80104729:	83 c4 10             	add    $0x10,%esp
8010472c:	85 c0                	test   %eax,%eax
8010472e:	0f 88 21 01 00 00    	js     80104855 <sys_open+0x159>
    return -1;

  begin_op();
80104734:	e8 94 e0 ff ff       	call   801027cd <begin_op>

  if(omode & O_CREATE){
80104739:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010473d:	0f 84 84 00 00 00    	je     801047c7 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104743:	83 ec 0c             	sub    $0xc,%esp
80104746:	6a 00                	push   $0x0
80104748:	b9 00 00 00 00       	mov    $0x0,%ecx
8010474d:	ba 02 00 00 00       	mov    $0x2,%edx
80104752:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104755:	e8 5e f9 ff ff       	call   801040b8 <create>
8010475a:	89 c6                	mov    %eax,%esi
    if(ip == 0){
8010475c:	83 c4 10             	add    $0x10,%esp
8010475f:	85 c0                	test   %eax,%eax
80104761:	74 58                	je     801047bb <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104763:	e8 c5 c4 ff ff       	call   80100c2d <filealloc>
80104768:	89 c3                	mov    %eax,%ebx
8010476a:	85 c0                	test   %eax,%eax
8010476c:	0f 84 ae 00 00 00    	je     80104820 <sys_open+0x124>
80104772:	e8 b3 f8 ff ff       	call   8010402a <fdalloc>
80104777:	89 c7                	mov    %eax,%edi
80104779:	85 c0                	test   %eax,%eax
8010477b:	0f 88 9f 00 00 00    	js     80104820 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104781:	83 ec 0c             	sub    $0xc,%esp
80104784:	56                   	push   %esi
80104785:	e8 b9 ce ff ff       	call   80101643 <iunlock>
  end_op();
8010478a:	e8 b8 e0 ff ff       	call   80102847 <end_op>

  f->type = FD_INODE;
8010478f:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104795:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104798:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010479f:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047a2:	83 c4 10             	add    $0x10,%esp
801047a5:	a8 01                	test   $0x1,%al
801047a7:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801047ab:	a8 03                	test   $0x3,%al
801047ad:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801047b1:	89 f8                	mov    %edi,%eax
801047b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801047b6:	5b                   	pop    %ebx
801047b7:	5e                   	pop    %esi
801047b8:	5f                   	pop    %edi
801047b9:	5d                   	pop    %ebp
801047ba:	c3                   	ret    
      end_op();
801047bb:	e8 87 e0 ff ff       	call   80102847 <end_op>
      return -1;
801047c0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801047c5:	eb ea                	jmp    801047b1 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801047c7:	83 ec 0c             	sub    $0xc,%esp
801047ca:	ff 75 e4             	pushl  -0x1c(%ebp)
801047cd:	e8 0f d4 ff ff       	call   80101be1 <namei>
801047d2:	89 c6                	mov    %eax,%esi
801047d4:	83 c4 10             	add    $0x10,%esp
801047d7:	85 c0                	test   %eax,%eax
801047d9:	74 39                	je     80104814 <sys_open+0x118>
    ilock(ip);
801047db:	83 ec 0c             	sub    $0xc,%esp
801047de:	50                   	push   %eax
801047df:	e8 9d cd ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801047e4:	83 c4 10             	add    $0x10,%esp
801047e7:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801047ec:	0f 85 71 ff ff ff    	jne    80104763 <sys_open+0x67>
801047f2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801047f6:	0f 84 67 ff ff ff    	je     80104763 <sys_open+0x67>
      iunlockput(ip);
801047fc:	83 ec 0c             	sub    $0xc,%esp
801047ff:	56                   	push   %esi
80104800:	e8 23 cf ff ff       	call   80101728 <iunlockput>
      end_op();
80104805:	e8 3d e0 ff ff       	call   80102847 <end_op>
      return -1;
8010480a:	83 c4 10             	add    $0x10,%esp
8010480d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104812:	eb 9d                	jmp    801047b1 <sys_open+0xb5>
      end_op();
80104814:	e8 2e e0 ff ff       	call   80102847 <end_op>
      return -1;
80104819:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010481e:	eb 91                	jmp    801047b1 <sys_open+0xb5>
    if(f)
80104820:	85 db                	test   %ebx,%ebx
80104822:	74 0c                	je     80104830 <sys_open+0x134>
      fileclose(f);
80104824:	83 ec 0c             	sub    $0xc,%esp
80104827:	53                   	push   %ebx
80104828:	e8 a6 c4 ff ff       	call   80100cd3 <fileclose>
8010482d:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104830:	83 ec 0c             	sub    $0xc,%esp
80104833:	56                   	push   %esi
80104834:	e8 ef ce ff ff       	call   80101728 <iunlockput>
    end_op();
80104839:	e8 09 e0 ff ff       	call   80102847 <end_op>
    return -1;
8010483e:	83 c4 10             	add    $0x10,%esp
80104841:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104846:	e9 66 ff ff ff       	jmp    801047b1 <sys_open+0xb5>
    return -1;
8010484b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104850:	e9 5c ff ff ff       	jmp    801047b1 <sys_open+0xb5>
80104855:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010485a:	e9 52 ff ff ff       	jmp    801047b1 <sys_open+0xb5>

8010485f <sys_mkdir>:

int
sys_mkdir(void)
{
8010485f:	55                   	push   %ebp
80104860:	89 e5                	mov    %esp,%ebp
80104862:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104865:	e8 63 df ff ff       	call   801027cd <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010486a:	83 ec 08             	sub    $0x8,%esp
8010486d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104870:	50                   	push   %eax
80104871:	6a 00                	push   $0x0
80104873:	e8 c3 f6 ff ff       	call   80103f3b <argstr>
80104878:	83 c4 10             	add    $0x10,%esp
8010487b:	85 c0                	test   %eax,%eax
8010487d:	78 36                	js     801048b5 <sys_mkdir+0x56>
8010487f:	83 ec 0c             	sub    $0xc,%esp
80104882:	6a 00                	push   $0x0
80104884:	b9 00 00 00 00       	mov    $0x0,%ecx
80104889:	ba 01 00 00 00       	mov    $0x1,%edx
8010488e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104891:	e8 22 f8 ff ff       	call   801040b8 <create>
80104896:	83 c4 10             	add    $0x10,%esp
80104899:	85 c0                	test   %eax,%eax
8010489b:	74 18                	je     801048b5 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
8010489d:	83 ec 0c             	sub    $0xc,%esp
801048a0:	50                   	push   %eax
801048a1:	e8 82 ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048a6:	e8 9c df ff ff       	call   80102847 <end_op>
  return 0;
801048ab:	83 c4 10             	add    $0x10,%esp
801048ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048b3:	c9                   	leave  
801048b4:	c3                   	ret    
    end_op();
801048b5:	e8 8d df ff ff       	call   80102847 <end_op>
    return -1;
801048ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048bf:	eb f2                	jmp    801048b3 <sys_mkdir+0x54>

801048c1 <sys_mknod>:

int
sys_mknod(void)
{
801048c1:	55                   	push   %ebp
801048c2:	89 e5                	mov    %esp,%ebp
801048c4:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801048c7:	e8 01 df ff ff       	call   801027cd <begin_op>
  if((argstr(0, &path)) < 0 ||
801048cc:	83 ec 08             	sub    $0x8,%esp
801048cf:	8d 45 f4             	lea    -0xc(%ebp),%eax
801048d2:	50                   	push   %eax
801048d3:	6a 00                	push   $0x0
801048d5:	e8 61 f6 ff ff       	call   80103f3b <argstr>
801048da:	83 c4 10             	add    $0x10,%esp
801048dd:	85 c0                	test   %eax,%eax
801048df:	78 62                	js     80104943 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
801048e1:	83 ec 08             	sub    $0x8,%esp
801048e4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801048e7:	50                   	push   %eax
801048e8:	6a 01                	push   $0x1
801048ea:	e8 bc f5 ff ff       	call   80103eab <argint>
  if((argstr(0, &path)) < 0 ||
801048ef:	83 c4 10             	add    $0x10,%esp
801048f2:	85 c0                	test   %eax,%eax
801048f4:	78 4d                	js     80104943 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
801048f6:	83 ec 08             	sub    $0x8,%esp
801048f9:	8d 45 ec             	lea    -0x14(%ebp),%eax
801048fc:	50                   	push   %eax
801048fd:	6a 02                	push   $0x2
801048ff:	e8 a7 f5 ff ff       	call   80103eab <argint>
     argint(1, &major) < 0 ||
80104904:	83 c4 10             	add    $0x10,%esp
80104907:	85 c0                	test   %eax,%eax
80104909:	78 38                	js     80104943 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
8010490b:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
8010490f:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104913:	83 ec 0c             	sub    $0xc,%esp
80104916:	50                   	push   %eax
80104917:	ba 03 00 00 00       	mov    $0x3,%edx
8010491c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491f:	e8 94 f7 ff ff       	call   801040b8 <create>
80104924:	83 c4 10             	add    $0x10,%esp
80104927:	85 c0                	test   %eax,%eax
80104929:	74 18                	je     80104943 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
8010492b:	83 ec 0c             	sub    $0xc,%esp
8010492e:	50                   	push   %eax
8010492f:	e8 f4 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104934:	e8 0e df ff ff       	call   80102847 <end_op>
  return 0;
80104939:	83 c4 10             	add    $0x10,%esp
8010493c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104941:	c9                   	leave  
80104942:	c3                   	ret    
    end_op();
80104943:	e8 ff de ff ff       	call   80102847 <end_op>
    return -1;
80104948:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010494d:	eb f2                	jmp    80104941 <sys_mknod+0x80>

8010494f <sys_chdir>:

int
sys_chdir(void)
{
8010494f:	55                   	push   %ebp
80104950:	89 e5                	mov    %esp,%ebp
80104952:	56                   	push   %esi
80104953:	53                   	push   %ebx
80104954:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104957:	e8 b9 e8 ff ff       	call   80103215 <myproc>
8010495c:	89 c6                	mov    %eax,%esi
  
  begin_op();
8010495e:	e8 6a de ff ff       	call   801027cd <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104963:	83 ec 08             	sub    $0x8,%esp
80104966:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104969:	50                   	push   %eax
8010496a:	6a 00                	push   $0x0
8010496c:	e8 ca f5 ff ff       	call   80103f3b <argstr>
80104971:	83 c4 10             	add    $0x10,%esp
80104974:	85 c0                	test   %eax,%eax
80104976:	78 52                	js     801049ca <sys_chdir+0x7b>
80104978:	83 ec 0c             	sub    $0xc,%esp
8010497b:	ff 75 f4             	pushl  -0xc(%ebp)
8010497e:	e8 5e d2 ff ff       	call   80101be1 <namei>
80104983:	89 c3                	mov    %eax,%ebx
80104985:	83 c4 10             	add    $0x10,%esp
80104988:	85 c0                	test   %eax,%eax
8010498a:	74 3e                	je     801049ca <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
8010498c:	83 ec 0c             	sub    $0xc,%esp
8010498f:	50                   	push   %eax
80104990:	e8 ec cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104995:	83 c4 10             	add    $0x10,%esp
80104998:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010499d:	75 37                	jne    801049d6 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010499f:	83 ec 0c             	sub    $0xc,%esp
801049a2:	53                   	push   %ebx
801049a3:	e8 9b cc ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
801049a8:	83 c4 04             	add    $0x4,%esp
801049ab:	ff 76 68             	pushl  0x68(%esi)
801049ae:	e8 d5 cc ff ff       	call   80101688 <iput>
  end_op();
801049b3:	e8 8f de ff ff       	call   80102847 <end_op>
  curproc->cwd = ip;
801049b8:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
801049bb:	83 c4 10             	add    $0x10,%esp
801049be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801049c6:	5b                   	pop    %ebx
801049c7:	5e                   	pop    %esi
801049c8:	5d                   	pop    %ebp
801049c9:	c3                   	ret    
    end_op();
801049ca:	e8 78 de ff ff       	call   80102847 <end_op>
    return -1;
801049cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049d4:	eb ed                	jmp    801049c3 <sys_chdir+0x74>
    iunlockput(ip);
801049d6:	83 ec 0c             	sub    $0xc,%esp
801049d9:	53                   	push   %ebx
801049da:	e8 49 cd ff ff       	call   80101728 <iunlockput>
    end_op();
801049df:	e8 63 de ff ff       	call   80102847 <end_op>
    return -1;
801049e4:	83 c4 10             	add    $0x10,%esp
801049e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049ec:	eb d5                	jmp    801049c3 <sys_chdir+0x74>

801049ee <sys_exec>:

int
sys_exec(void)
{
801049ee:	55                   	push   %ebp
801049ef:	89 e5                	mov    %esp,%ebp
801049f1:	53                   	push   %ebx
801049f2:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801049f8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049fb:	50                   	push   %eax
801049fc:	6a 00                	push   $0x0
801049fe:	e8 38 f5 ff ff       	call   80103f3b <argstr>
80104a03:	83 c4 10             	add    $0x10,%esp
80104a06:	85 c0                	test   %eax,%eax
80104a08:	0f 88 a8 00 00 00    	js     80104ab6 <sys_exec+0xc8>
80104a0e:	83 ec 08             	sub    $0x8,%esp
80104a11:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104a17:	50                   	push   %eax
80104a18:	6a 01                	push   $0x1
80104a1a:	e8 8c f4 ff ff       	call   80103eab <argint>
80104a1f:	83 c4 10             	add    $0x10,%esp
80104a22:	85 c0                	test   %eax,%eax
80104a24:	0f 88 93 00 00 00    	js     80104abd <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104a2a:	83 ec 04             	sub    $0x4,%esp
80104a2d:	68 80 00 00 00       	push   $0x80
80104a32:	6a 00                	push   $0x0
80104a34:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104a3a:	50                   	push   %eax
80104a3b:	e8 20 f2 ff ff       	call   80103c60 <memset>
80104a40:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104a43:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104a48:	83 fb 1f             	cmp    $0x1f,%ebx
80104a4b:	77 77                	ja     80104ac4 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104a4d:	83 ec 08             	sub    $0x8,%esp
80104a50:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104a56:	50                   	push   %eax
80104a57:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104a5d:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104a60:	50                   	push   %eax
80104a61:	e8 c9 f3 ff ff       	call   80103e2f <fetchint>
80104a66:	83 c4 10             	add    $0x10,%esp
80104a69:	85 c0                	test   %eax,%eax
80104a6b:	78 5e                	js     80104acb <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104a6d:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104a73:	85 c0                	test   %eax,%eax
80104a75:	74 1d                	je     80104a94 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104a77:	83 ec 08             	sub    $0x8,%esp
80104a7a:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104a81:	52                   	push   %edx
80104a82:	50                   	push   %eax
80104a83:	e8 e3 f3 ff ff       	call   80103e6b <fetchstr>
80104a88:	83 c4 10             	add    $0x10,%esp
80104a8b:	85 c0                	test   %eax,%eax
80104a8d:	78 46                	js     80104ad5 <sys_exec+0xe7>
  for(i=0;; i++){
80104a8f:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104a92:	eb b4                	jmp    80104a48 <sys_exec+0x5a>
      argv[i] = 0;
80104a94:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104a9b:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104a9f:	83 ec 08             	sub    $0x8,%esp
80104aa2:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104aa8:	50                   	push   %eax
80104aa9:	ff 75 f4             	pushl  -0xc(%ebp)
80104aac:	e8 21 be ff ff       	call   801008d2 <exec>
80104ab1:	83 c4 10             	add    $0x10,%esp
80104ab4:	eb 1a                	jmp    80104ad0 <sys_exec+0xe2>
    return -1;
80104ab6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104abb:	eb 13                	jmp    80104ad0 <sys_exec+0xe2>
80104abd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ac2:	eb 0c                	jmp    80104ad0 <sys_exec+0xe2>
      return -1;
80104ac4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ac9:	eb 05                	jmp    80104ad0 <sys_exec+0xe2>
      return -1;
80104acb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104ad0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ad3:	c9                   	leave  
80104ad4:	c3                   	ret    
      return -1;
80104ad5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ada:	eb f4                	jmp    80104ad0 <sys_exec+0xe2>

80104adc <sys_pipe>:

int
sys_pipe(void)
{
80104adc:	55                   	push   %ebp
80104add:	89 e5                	mov    %esp,%ebp
80104adf:	53                   	push   %ebx
80104ae0:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104ae3:	6a 08                	push   $0x8
80104ae5:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ae8:	50                   	push   %eax
80104ae9:	6a 00                	push   $0x0
80104aeb:	e8 e3 f3 ff ff       	call   80103ed3 <argptr>
80104af0:	83 c4 10             	add    $0x10,%esp
80104af3:	85 c0                	test   %eax,%eax
80104af5:	78 77                	js     80104b6e <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104af7:	83 ec 08             	sub    $0x8,%esp
80104afa:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104afd:	50                   	push   %eax
80104afe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b01:	50                   	push   %eax
80104b02:	e8 4d e2 ff ff       	call   80102d54 <pipealloc>
80104b07:	83 c4 10             	add    $0x10,%esp
80104b0a:	85 c0                	test   %eax,%eax
80104b0c:	78 67                	js     80104b75 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104b0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b11:	e8 14 f5 ff ff       	call   8010402a <fdalloc>
80104b16:	89 c3                	mov    %eax,%ebx
80104b18:	85 c0                	test   %eax,%eax
80104b1a:	78 21                	js     80104b3d <sys_pipe+0x61>
80104b1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b1f:	e8 06 f5 ff ff       	call   8010402a <fdalloc>
80104b24:	85 c0                	test   %eax,%eax
80104b26:	78 15                	js     80104b3d <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104b28:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b2b:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104b2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b30:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104b33:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b38:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104b3b:	c9                   	leave  
80104b3c:	c3                   	ret    
    if(fd0 >= 0)
80104b3d:	85 db                	test   %ebx,%ebx
80104b3f:	78 0d                	js     80104b4e <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104b41:	e8 cf e6 ff ff       	call   80103215 <myproc>
80104b46:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104b4d:	00 
    fileclose(rf);
80104b4e:	83 ec 0c             	sub    $0xc,%esp
80104b51:	ff 75 f0             	pushl  -0x10(%ebp)
80104b54:	e8 7a c1 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104b59:	83 c4 04             	add    $0x4,%esp
80104b5c:	ff 75 ec             	pushl  -0x14(%ebp)
80104b5f:	e8 6f c1 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104b64:	83 c4 10             	add    $0x10,%esp
80104b67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b6c:	eb ca                	jmp    80104b38 <sys_pipe+0x5c>
    return -1;
80104b6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b73:	eb c3                	jmp    80104b38 <sys_pipe+0x5c>
    return -1;
80104b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b7a:	eb bc                	jmp    80104b38 <sys_pipe+0x5c>

80104b7c <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104b7c:	55                   	push   %ebp
80104b7d:	89 e5                	mov    %esp,%ebp
80104b7f:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104b82:	e8 06 e8 ff ff       	call   8010338d <fork>
}
80104b87:	c9                   	leave  
80104b88:	c3                   	ret    

80104b89 <sys_exit>:

int
sys_exit(void)
{
80104b89:	55                   	push   %ebp
80104b8a:	89 e5                	mov    %esp,%ebp
80104b8c:	83 ec 08             	sub    $0x8,%esp
  exit();
80104b8f:	e8 2d ea ff ff       	call   801035c1 <exit>
  return 0;  // not reached
}
80104b94:	b8 00 00 00 00       	mov    $0x0,%eax
80104b99:	c9                   	leave  
80104b9a:	c3                   	ret    

80104b9b <sys_wait>:

int
sys_wait(void)
{
80104b9b:	55                   	push   %ebp
80104b9c:	89 e5                	mov    %esp,%ebp
80104b9e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104ba1:	e8 a4 eb ff ff       	call   8010374a <wait>
}
80104ba6:	c9                   	leave  
80104ba7:	c3                   	ret    

80104ba8 <sys_kill>:

int
sys_kill(void)
{
80104ba8:	55                   	push   %ebp
80104ba9:	89 e5                	mov    %esp,%ebp
80104bab:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104bae:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb1:	50                   	push   %eax
80104bb2:	6a 00                	push   $0x0
80104bb4:	e8 f2 f2 ff ff       	call   80103eab <argint>
80104bb9:	83 c4 10             	add    $0x10,%esp
80104bbc:	85 c0                	test   %eax,%eax
80104bbe:	78 10                	js     80104bd0 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104bc0:	83 ec 0c             	sub    $0xc,%esp
80104bc3:	ff 75 f4             	pushl  -0xc(%ebp)
80104bc6:	e8 7c ec ff ff       	call   80103847 <kill>
80104bcb:	83 c4 10             	add    $0x10,%esp
}
80104bce:	c9                   	leave  
80104bcf:	c3                   	ret    
    return -1;
80104bd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd5:	eb f7                	jmp    80104bce <sys_kill+0x26>

80104bd7 <sys_getpid>:

int
sys_getpid(void)
{
80104bd7:	55                   	push   %ebp
80104bd8:	89 e5                	mov    %esp,%ebp
80104bda:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104bdd:	e8 33 e6 ff ff       	call   80103215 <myproc>
80104be2:	8b 40 10             	mov    0x10(%eax),%eax
}
80104be5:	c9                   	leave  
80104be6:	c3                   	ret    

80104be7 <sys_sbrk>:

int
sys_sbrk(void)
{
80104be7:	55                   	push   %ebp
80104be8:	89 e5                	mov    %esp,%ebp
80104bea:	53                   	push   %ebx
80104beb:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104bee:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bf1:	50                   	push   %eax
80104bf2:	6a 00                	push   $0x0
80104bf4:	e8 b2 f2 ff ff       	call   80103eab <argint>
80104bf9:	83 c4 10             	add    $0x10,%esp
80104bfc:	85 c0                	test   %eax,%eax
80104bfe:	78 27                	js     80104c27 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104c00:	e8 10 e6 ff ff       	call   80103215 <myproc>
80104c05:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104c07:	83 ec 0c             	sub    $0xc,%esp
80104c0a:	ff 75 f4             	pushl  -0xc(%ebp)
80104c0d:	e8 0e e7 ff ff       	call   80103320 <growproc>
80104c12:	83 c4 10             	add    $0x10,%esp
80104c15:	85 c0                	test   %eax,%eax
80104c17:	78 07                	js     80104c20 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104c19:	89 d8                	mov    %ebx,%eax
80104c1b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c1e:	c9                   	leave  
80104c1f:	c3                   	ret    
    return -1;
80104c20:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104c25:	eb f2                	jmp    80104c19 <sys_sbrk+0x32>
    return -1;
80104c27:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104c2c:	eb eb                	jmp    80104c19 <sys_sbrk+0x32>

80104c2e <sys_sleep>:

int
sys_sleep(void)
{
80104c2e:	55                   	push   %ebp
80104c2f:	89 e5                	mov    %esp,%ebp
80104c31:	53                   	push   %ebx
80104c32:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104c35:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c38:	50                   	push   %eax
80104c39:	6a 00                	push   $0x0
80104c3b:	e8 6b f2 ff ff       	call   80103eab <argint>
80104c40:	83 c4 10             	add    $0x10,%esp
80104c43:	85 c0                	test   %eax,%eax
80104c45:	78 75                	js     80104cbc <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104c47:	83 ec 0c             	sub    $0xc,%esp
80104c4a:	68 80 3c 11 80       	push   $0x80113c80
80104c4f:	e8 60 ef ff ff       	call   80103bb4 <acquire>
  ticks0 = ticks;
80104c54:	8b 1d c0 44 11 80    	mov    0x801144c0,%ebx
  while(ticks - ticks0 < n){
80104c5a:	83 c4 10             	add    $0x10,%esp
80104c5d:	a1 c0 44 11 80       	mov    0x801144c0,%eax
80104c62:	29 d8                	sub    %ebx,%eax
80104c64:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104c67:	73 39                	jae    80104ca2 <sys_sleep+0x74>
    if(myproc()->killed){
80104c69:	e8 a7 e5 ff ff       	call   80103215 <myproc>
80104c6e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104c72:	75 17                	jne    80104c8b <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104c74:	83 ec 08             	sub    $0x8,%esp
80104c77:	68 80 3c 11 80       	push   $0x80113c80
80104c7c:	68 c0 44 11 80       	push   $0x801144c0
80104c81:	e8 33 ea ff ff       	call   801036b9 <sleep>
80104c86:	83 c4 10             	add    $0x10,%esp
80104c89:	eb d2                	jmp    80104c5d <sys_sleep+0x2f>
      release(&tickslock);
80104c8b:	83 ec 0c             	sub    $0xc,%esp
80104c8e:	68 80 3c 11 80       	push   $0x80113c80
80104c93:	e8 81 ef ff ff       	call   80103c19 <release>
      return -1;
80104c98:	83 c4 10             	add    $0x10,%esp
80104c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca0:	eb 15                	jmp    80104cb7 <sys_sleep+0x89>
  }
  release(&tickslock);
80104ca2:	83 ec 0c             	sub    $0xc,%esp
80104ca5:	68 80 3c 11 80       	push   $0x80113c80
80104caa:	e8 6a ef ff ff       	call   80103c19 <release>
  return 0;
80104caf:	83 c4 10             	add    $0x10,%esp
80104cb2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104cb7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104cba:	c9                   	leave  
80104cbb:	c3                   	ret    
    return -1;
80104cbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cc1:	eb f4                	jmp    80104cb7 <sys_sleep+0x89>

80104cc3 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104cc3:	55                   	push   %ebp
80104cc4:	89 e5                	mov    %esp,%ebp
80104cc6:	53                   	push   %ebx
80104cc7:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104cca:	68 80 3c 11 80       	push   $0x80113c80
80104ccf:	e8 e0 ee ff ff       	call   80103bb4 <acquire>
  xticks = ticks;
80104cd4:	8b 1d c0 44 11 80    	mov    0x801144c0,%ebx
  release(&tickslock);
80104cda:	c7 04 24 80 3c 11 80 	movl   $0x80113c80,(%esp)
80104ce1:	e8 33 ef ff ff       	call   80103c19 <release>
  return xticks;
}
80104ce6:	89 d8                	mov    %ebx,%eax
80104ce8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ceb:	c9                   	leave  
80104cec:	c3                   	ret    

80104ced <sys_dump_physmem>:

int
sys_dump_physmem(int *frames, int *pids, int numframes)
{
80104ced:	55                   	push   %ebp
80104cee:	89 e5                	mov    %esp,%ebp
    return 0;
}
80104cf0:	b8 00 00 00 00       	mov    $0x0,%eax
80104cf5:	5d                   	pop    %ebp
80104cf6:	c3                   	ret    

80104cf7 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104cf7:	1e                   	push   %ds
  pushl %es
80104cf8:	06                   	push   %es
  pushl %fs
80104cf9:	0f a0                	push   %fs
  pushl %gs
80104cfb:	0f a8                	push   %gs
  pushal
80104cfd:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104cfe:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104d02:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104d04:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104d06:	54                   	push   %esp
  call trap
80104d07:	e8 e3 00 00 00       	call   80104def <trap>
  addl $4, %esp
80104d0c:	83 c4 04             	add    $0x4,%esp

80104d0f <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104d0f:	61                   	popa   
  popl %gs
80104d10:	0f a9                	pop    %gs
  popl %fs
80104d12:	0f a1                	pop    %fs
  popl %es
80104d14:	07                   	pop    %es
  popl %ds
80104d15:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104d16:	83 c4 08             	add    $0x8,%esp
  iret
80104d19:	cf                   	iret   

80104d1a <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104d1a:	55                   	push   %ebp
80104d1b:	89 e5                	mov    %esp,%ebp
80104d1d:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104d20:	b8 00 00 00 00       	mov    $0x0,%eax
80104d25:	eb 4a                	jmp    80104d71 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104d27:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104d2e:	66 89 0c c5 c0 3c 11 	mov    %cx,-0x7feec340(,%eax,8)
80104d35:	80 
80104d36:	66 c7 04 c5 c2 3c 11 	movw   $0x8,-0x7feec33e(,%eax,8)
80104d3d:	80 08 00 
80104d40:	c6 04 c5 c4 3c 11 80 	movb   $0x0,-0x7feec33c(,%eax,8)
80104d47:	00 
80104d48:	0f b6 14 c5 c5 3c 11 	movzbl -0x7feec33b(,%eax,8),%edx
80104d4f:	80 
80104d50:	83 e2 f0             	and    $0xfffffff0,%edx
80104d53:	83 ca 0e             	or     $0xe,%edx
80104d56:	83 e2 8f             	and    $0xffffff8f,%edx
80104d59:	83 ca 80             	or     $0xffffff80,%edx
80104d5c:	88 14 c5 c5 3c 11 80 	mov    %dl,-0x7feec33b(,%eax,8)
80104d63:	c1 e9 10             	shr    $0x10,%ecx
80104d66:	66 89 0c c5 c6 3c 11 	mov    %cx,-0x7feec33a(,%eax,8)
80104d6d:	80 
  for(i = 0; i < 256; i++)
80104d6e:	83 c0 01             	add    $0x1,%eax
80104d71:	3d ff 00 00 00       	cmp    $0xff,%eax
80104d76:	7e af                	jle    80104d27 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104d78:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104d7e:	66 89 15 c0 3e 11 80 	mov    %dx,0x80113ec0
80104d85:	66 c7 05 c2 3e 11 80 	movw   $0x8,0x80113ec2
80104d8c:	08 00 
80104d8e:	c6 05 c4 3e 11 80 00 	movb   $0x0,0x80113ec4
80104d95:	0f b6 05 c5 3e 11 80 	movzbl 0x80113ec5,%eax
80104d9c:	83 c8 0f             	or     $0xf,%eax
80104d9f:	83 e0 ef             	and    $0xffffffef,%eax
80104da2:	83 c8 e0             	or     $0xffffffe0,%eax
80104da5:	a2 c5 3e 11 80       	mov    %al,0x80113ec5
80104daa:	c1 ea 10             	shr    $0x10,%edx
80104dad:	66 89 15 c6 3e 11 80 	mov    %dx,0x80113ec6

  initlock(&tickslock, "time");
80104db4:	83 ec 08             	sub    $0x8,%esp
80104db7:	68 dd 6b 10 80       	push   $0x80106bdd
80104dbc:	68 80 3c 11 80       	push   $0x80113c80
80104dc1:	e8 b2 ec ff ff       	call   80103a78 <initlock>
}
80104dc6:	83 c4 10             	add    $0x10,%esp
80104dc9:	c9                   	leave  
80104dca:	c3                   	ret    

80104dcb <idtinit>:

void
idtinit(void)
{
80104dcb:	55                   	push   %ebp
80104dcc:	89 e5                	mov    %esp,%ebp
80104dce:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104dd1:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104dd7:	b8 c0 3c 11 80       	mov    $0x80113cc0,%eax
80104ddc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104de0:	c1 e8 10             	shr    $0x10,%eax
80104de3:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104de7:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104dea:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104ded:	c9                   	leave  
80104dee:	c3                   	ret    

80104def <trap>:

void
trap(struct trapframe *tf)
{
80104def:	55                   	push   %ebp
80104df0:	89 e5                	mov    %esp,%ebp
80104df2:	57                   	push   %edi
80104df3:	56                   	push   %esi
80104df4:	53                   	push   %ebx
80104df5:	83 ec 1c             	sub    $0x1c,%esp
80104df8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104dfb:	8b 43 30             	mov    0x30(%ebx),%eax
80104dfe:	83 f8 40             	cmp    $0x40,%eax
80104e01:	74 13                	je     80104e16 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104e03:	83 e8 20             	sub    $0x20,%eax
80104e06:	83 f8 1f             	cmp    $0x1f,%eax
80104e09:	0f 87 3a 01 00 00    	ja     80104f49 <trap+0x15a>
80104e0f:	ff 24 85 84 6c 10 80 	jmp    *-0x7fef937c(,%eax,4)
    if(myproc()->killed)
80104e16:	e8 fa e3 ff ff       	call   80103215 <myproc>
80104e1b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e1f:	75 1f                	jne    80104e40 <trap+0x51>
    myproc()->tf = tf;
80104e21:	e8 ef e3 ff ff       	call   80103215 <myproc>
80104e26:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104e29:	e8 40 f1 ff ff       	call   80103f6e <syscall>
    if(myproc()->killed)
80104e2e:	e8 e2 e3 ff ff       	call   80103215 <myproc>
80104e33:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e37:	74 7e                	je     80104eb7 <trap+0xc8>
      exit();
80104e39:	e8 83 e7 ff ff       	call   801035c1 <exit>
80104e3e:	eb 77                	jmp    80104eb7 <trap+0xc8>
      exit();
80104e40:	e8 7c e7 ff ff       	call   801035c1 <exit>
80104e45:	eb da                	jmp    80104e21 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104e47:	e8 ae e3 ff ff       	call   801031fa <cpuid>
80104e4c:	85 c0                	test   %eax,%eax
80104e4e:	74 6f                	je     80104ebf <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104e50:	e8 63 d5 ff ff       	call   801023b8 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104e55:	e8 bb e3 ff ff       	call   80103215 <myproc>
80104e5a:	85 c0                	test   %eax,%eax
80104e5c:	74 1c                	je     80104e7a <trap+0x8b>
80104e5e:	e8 b2 e3 ff ff       	call   80103215 <myproc>
80104e63:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e67:	74 11                	je     80104e7a <trap+0x8b>
80104e69:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104e6d:	83 e0 03             	and    $0x3,%eax
80104e70:	66 83 f8 03          	cmp    $0x3,%ax
80104e74:	0f 84 62 01 00 00    	je     80104fdc <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104e7a:	e8 96 e3 ff ff       	call   80103215 <myproc>
80104e7f:	85 c0                	test   %eax,%eax
80104e81:	74 0f                	je     80104e92 <trap+0xa3>
80104e83:	e8 8d e3 ff ff       	call   80103215 <myproc>
80104e88:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104e8c:	0f 84 54 01 00 00    	je     80104fe6 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104e92:	e8 7e e3 ff ff       	call   80103215 <myproc>
80104e97:	85 c0                	test   %eax,%eax
80104e99:	74 1c                	je     80104eb7 <trap+0xc8>
80104e9b:	e8 75 e3 ff ff       	call   80103215 <myproc>
80104ea0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ea4:	74 11                	je     80104eb7 <trap+0xc8>
80104ea6:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104eaa:	83 e0 03             	and    $0x3,%eax
80104ead:	66 83 f8 03          	cmp    $0x3,%ax
80104eb1:	0f 84 43 01 00 00    	je     80104ffa <trap+0x20b>
    exit();
}
80104eb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104eba:	5b                   	pop    %ebx
80104ebb:	5e                   	pop    %esi
80104ebc:	5f                   	pop    %edi
80104ebd:	5d                   	pop    %ebp
80104ebe:	c3                   	ret    
      acquire(&tickslock);
80104ebf:	83 ec 0c             	sub    $0xc,%esp
80104ec2:	68 80 3c 11 80       	push   $0x80113c80
80104ec7:	e8 e8 ec ff ff       	call   80103bb4 <acquire>
      ticks++;
80104ecc:	83 05 c0 44 11 80 01 	addl   $0x1,0x801144c0
      wakeup(&ticks);
80104ed3:	c7 04 24 c0 44 11 80 	movl   $0x801144c0,(%esp)
80104eda:	e8 3f e9 ff ff       	call   8010381e <wakeup>
      release(&tickslock);
80104edf:	c7 04 24 80 3c 11 80 	movl   $0x80113c80,(%esp)
80104ee6:	e8 2e ed ff ff       	call   80103c19 <release>
80104eeb:	83 c4 10             	add    $0x10,%esp
80104eee:	e9 5d ff ff ff       	jmp    80104e50 <trap+0x61>
    ideintr();
80104ef3:	e8 7b ce ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80104ef8:	e8 bb d4 ff ff       	call   801023b8 <lapiceoi>
    break;
80104efd:	e9 53 ff ff ff       	jmp    80104e55 <trap+0x66>
    kbdintr();
80104f02:	e8 f5 d2 ff ff       	call   801021fc <kbdintr>
    lapiceoi();
80104f07:	e8 ac d4 ff ff       	call   801023b8 <lapiceoi>
    break;
80104f0c:	e9 44 ff ff ff       	jmp    80104e55 <trap+0x66>
    uartintr();
80104f11:	e8 05 02 00 00       	call   8010511b <uartintr>
    lapiceoi();
80104f16:	e8 9d d4 ff ff       	call   801023b8 <lapiceoi>
    break;
80104f1b:	e9 35 ff ff ff       	jmp    80104e55 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80104f20:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80104f23:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80104f27:	e8 ce e2 ff ff       	call   801031fa <cpuid>
80104f2c:	57                   	push   %edi
80104f2d:	0f b7 f6             	movzwl %si,%esi
80104f30:	56                   	push   %esi
80104f31:	50                   	push   %eax
80104f32:	68 e8 6b 10 80       	push   $0x80106be8
80104f37:	e8 cf b6 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80104f3c:	e8 77 d4 ff ff       	call   801023b8 <lapiceoi>
    break;
80104f41:	83 c4 10             	add    $0x10,%esp
80104f44:	e9 0c ff ff ff       	jmp    80104e55 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80104f49:	e8 c7 e2 ff ff       	call   80103215 <myproc>
80104f4e:	85 c0                	test   %eax,%eax
80104f50:	74 5f                	je     80104fb1 <trap+0x1c2>
80104f52:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80104f56:	74 59                	je     80104fb1 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80104f58:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80104f5b:	8b 43 38             	mov    0x38(%ebx),%eax
80104f5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80104f61:	e8 94 e2 ff ff       	call   801031fa <cpuid>
80104f66:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104f69:	8b 53 34             	mov    0x34(%ebx),%edx
80104f6c:	89 55 dc             	mov    %edx,-0x24(%ebp)
80104f6f:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80104f72:	e8 9e e2 ff ff       	call   80103215 <myproc>
80104f77:	8d 48 6c             	lea    0x6c(%eax),%ecx
80104f7a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80104f7d:	e8 93 e2 ff ff       	call   80103215 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80104f82:	57                   	push   %edi
80104f83:	ff 75 e4             	pushl  -0x1c(%ebp)
80104f86:	ff 75 e0             	pushl  -0x20(%ebp)
80104f89:	ff 75 dc             	pushl  -0x24(%ebp)
80104f8c:	56                   	push   %esi
80104f8d:	ff 75 d8             	pushl  -0x28(%ebp)
80104f90:	ff 70 10             	pushl  0x10(%eax)
80104f93:	68 40 6c 10 80       	push   $0x80106c40
80104f98:	e8 6e b6 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80104f9d:	83 c4 20             	add    $0x20,%esp
80104fa0:	e8 70 e2 ff ff       	call   80103215 <myproc>
80104fa5:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80104fac:	e9 a4 fe ff ff       	jmp    80104e55 <trap+0x66>
80104fb1:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80104fb4:	8b 73 38             	mov    0x38(%ebx),%esi
80104fb7:	e8 3e e2 ff ff       	call   801031fa <cpuid>
80104fbc:	83 ec 0c             	sub    $0xc,%esp
80104fbf:	57                   	push   %edi
80104fc0:	56                   	push   %esi
80104fc1:	50                   	push   %eax
80104fc2:	ff 73 30             	pushl  0x30(%ebx)
80104fc5:	68 0c 6c 10 80       	push   $0x80106c0c
80104fca:	e8 3c b6 ff ff       	call   8010060b <cprintf>
      panic("trap");
80104fcf:	83 c4 14             	add    $0x14,%esp
80104fd2:	68 e2 6b 10 80       	push   $0x80106be2
80104fd7:	e8 6c b3 ff ff       	call   80100348 <panic>
    exit();
80104fdc:	e8 e0 e5 ff ff       	call   801035c1 <exit>
80104fe1:	e9 94 fe ff ff       	jmp    80104e7a <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80104fe6:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80104fea:	0f 85 a2 fe ff ff    	jne    80104e92 <trap+0xa3>
    yield();
80104ff0:	e8 92 e6 ff ff       	call   80103687 <yield>
80104ff5:	e9 98 fe ff ff       	jmp    80104e92 <trap+0xa3>
    exit();
80104ffa:	e8 c2 e5 ff ff       	call   801035c1 <exit>
80104fff:	e9 b3 fe ff ff       	jmp    80104eb7 <trap+0xc8>

80105004 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105004:	55                   	push   %ebp
80105005:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105007:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
8010500e:	74 15                	je     80105025 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105010:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105015:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105016:	a8 01                	test   $0x1,%al
80105018:	74 12                	je     8010502c <uartgetc+0x28>
8010501a:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010501f:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105020:	0f b6 c0             	movzbl %al,%eax
}
80105023:	5d                   	pop    %ebp
80105024:	c3                   	ret    
    return -1;
80105025:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010502a:	eb f7                	jmp    80105023 <uartgetc+0x1f>
    return -1;
8010502c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105031:	eb f0                	jmp    80105023 <uartgetc+0x1f>

80105033 <uartputc>:
  if(!uart)
80105033:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
8010503a:	74 3b                	je     80105077 <uartputc+0x44>
{
8010503c:	55                   	push   %ebp
8010503d:	89 e5                	mov    %esp,%ebp
8010503f:	53                   	push   %ebx
80105040:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105043:	bb 00 00 00 00       	mov    $0x0,%ebx
80105048:	eb 10                	jmp    8010505a <uartputc+0x27>
    microdelay(10);
8010504a:	83 ec 0c             	sub    $0xc,%esp
8010504d:	6a 0a                	push   $0xa
8010504f:	e8 83 d3 ff ff       	call   801023d7 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105054:	83 c3 01             	add    $0x1,%ebx
80105057:	83 c4 10             	add    $0x10,%esp
8010505a:	83 fb 7f             	cmp    $0x7f,%ebx
8010505d:	7f 0a                	jg     80105069 <uartputc+0x36>
8010505f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105064:	ec                   	in     (%dx),%al
80105065:	a8 20                	test   $0x20,%al
80105067:	74 e1                	je     8010504a <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105069:	8b 45 08             	mov    0x8(%ebp),%eax
8010506c:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105071:	ee                   	out    %al,(%dx)
}
80105072:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105075:	c9                   	leave  
80105076:	c3                   	ret    
80105077:	f3 c3                	repz ret 

80105079 <uartinit>:
{
80105079:	55                   	push   %ebp
8010507a:	89 e5                	mov    %esp,%ebp
8010507c:	56                   	push   %esi
8010507d:	53                   	push   %ebx
8010507e:	b9 00 00 00 00       	mov    $0x0,%ecx
80105083:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105088:	89 c8                	mov    %ecx,%eax
8010508a:	ee                   	out    %al,(%dx)
8010508b:	be fb 03 00 00       	mov    $0x3fb,%esi
80105090:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105095:	89 f2                	mov    %esi,%edx
80105097:	ee                   	out    %al,(%dx)
80105098:	b8 0c 00 00 00       	mov    $0xc,%eax
8010509d:	ba f8 03 00 00       	mov    $0x3f8,%edx
801050a2:	ee                   	out    %al,(%dx)
801050a3:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801050a8:	89 c8                	mov    %ecx,%eax
801050aa:	89 da                	mov    %ebx,%edx
801050ac:	ee                   	out    %al,(%dx)
801050ad:	b8 03 00 00 00       	mov    $0x3,%eax
801050b2:	89 f2                	mov    %esi,%edx
801050b4:	ee                   	out    %al,(%dx)
801050b5:	ba fc 03 00 00       	mov    $0x3fc,%edx
801050ba:	89 c8                	mov    %ecx,%eax
801050bc:	ee                   	out    %al,(%dx)
801050bd:	b8 01 00 00 00       	mov    $0x1,%eax
801050c2:	89 da                	mov    %ebx,%edx
801050c4:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801050c5:	ba fd 03 00 00       	mov    $0x3fd,%edx
801050ca:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801050cb:	3c ff                	cmp    $0xff,%al
801050cd:	74 45                	je     80105114 <uartinit+0x9b>
  uart = 1;
801050cf:	c7 05 c0 95 10 80 01 	movl   $0x1,0x801095c0
801050d6:	00 00 00 
801050d9:	ba fa 03 00 00       	mov    $0x3fa,%edx
801050de:	ec                   	in     (%dx),%al
801050df:	ba f8 03 00 00       	mov    $0x3f8,%edx
801050e4:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801050e5:	83 ec 08             	sub    $0x8,%esp
801050e8:	6a 00                	push   $0x0
801050ea:	6a 04                	push   $0x4
801050ec:	e8 8d ce ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801050f1:	83 c4 10             	add    $0x10,%esp
801050f4:	bb 04 6d 10 80       	mov    $0x80106d04,%ebx
801050f9:	eb 12                	jmp    8010510d <uartinit+0x94>
    uartputc(*p);
801050fb:	83 ec 0c             	sub    $0xc,%esp
801050fe:	0f be c0             	movsbl %al,%eax
80105101:	50                   	push   %eax
80105102:	e8 2c ff ff ff       	call   80105033 <uartputc>
  for(p="xv6...\n"; *p; p++)
80105107:	83 c3 01             	add    $0x1,%ebx
8010510a:	83 c4 10             	add    $0x10,%esp
8010510d:	0f b6 03             	movzbl (%ebx),%eax
80105110:	84 c0                	test   %al,%al
80105112:	75 e7                	jne    801050fb <uartinit+0x82>
}
80105114:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105117:	5b                   	pop    %ebx
80105118:	5e                   	pop    %esi
80105119:	5d                   	pop    %ebp
8010511a:	c3                   	ret    

8010511b <uartintr>:

void
uartintr(void)
{
8010511b:	55                   	push   %ebp
8010511c:	89 e5                	mov    %esp,%ebp
8010511e:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105121:	68 04 50 10 80       	push   $0x80105004
80105126:	e8 13 b6 ff ff       	call   8010073e <consoleintr>
}
8010512b:	83 c4 10             	add    $0x10,%esp
8010512e:	c9                   	leave  
8010512f:	c3                   	ret    

80105130 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105130:	6a 00                	push   $0x0
  pushl $0
80105132:	6a 00                	push   $0x0
  jmp alltraps
80105134:	e9 be fb ff ff       	jmp    80104cf7 <alltraps>

80105139 <vector1>:
.globl vector1
vector1:
  pushl $0
80105139:	6a 00                	push   $0x0
  pushl $1
8010513b:	6a 01                	push   $0x1
  jmp alltraps
8010513d:	e9 b5 fb ff ff       	jmp    80104cf7 <alltraps>

80105142 <vector2>:
.globl vector2
vector2:
  pushl $0
80105142:	6a 00                	push   $0x0
  pushl $2
80105144:	6a 02                	push   $0x2
  jmp alltraps
80105146:	e9 ac fb ff ff       	jmp    80104cf7 <alltraps>

8010514b <vector3>:
.globl vector3
vector3:
  pushl $0
8010514b:	6a 00                	push   $0x0
  pushl $3
8010514d:	6a 03                	push   $0x3
  jmp alltraps
8010514f:	e9 a3 fb ff ff       	jmp    80104cf7 <alltraps>

80105154 <vector4>:
.globl vector4
vector4:
  pushl $0
80105154:	6a 00                	push   $0x0
  pushl $4
80105156:	6a 04                	push   $0x4
  jmp alltraps
80105158:	e9 9a fb ff ff       	jmp    80104cf7 <alltraps>

8010515d <vector5>:
.globl vector5
vector5:
  pushl $0
8010515d:	6a 00                	push   $0x0
  pushl $5
8010515f:	6a 05                	push   $0x5
  jmp alltraps
80105161:	e9 91 fb ff ff       	jmp    80104cf7 <alltraps>

80105166 <vector6>:
.globl vector6
vector6:
  pushl $0
80105166:	6a 00                	push   $0x0
  pushl $6
80105168:	6a 06                	push   $0x6
  jmp alltraps
8010516a:	e9 88 fb ff ff       	jmp    80104cf7 <alltraps>

8010516f <vector7>:
.globl vector7
vector7:
  pushl $0
8010516f:	6a 00                	push   $0x0
  pushl $7
80105171:	6a 07                	push   $0x7
  jmp alltraps
80105173:	e9 7f fb ff ff       	jmp    80104cf7 <alltraps>

80105178 <vector8>:
.globl vector8
vector8:
  pushl $8
80105178:	6a 08                	push   $0x8
  jmp alltraps
8010517a:	e9 78 fb ff ff       	jmp    80104cf7 <alltraps>

8010517f <vector9>:
.globl vector9
vector9:
  pushl $0
8010517f:	6a 00                	push   $0x0
  pushl $9
80105181:	6a 09                	push   $0x9
  jmp alltraps
80105183:	e9 6f fb ff ff       	jmp    80104cf7 <alltraps>

80105188 <vector10>:
.globl vector10
vector10:
  pushl $10
80105188:	6a 0a                	push   $0xa
  jmp alltraps
8010518a:	e9 68 fb ff ff       	jmp    80104cf7 <alltraps>

8010518f <vector11>:
.globl vector11
vector11:
  pushl $11
8010518f:	6a 0b                	push   $0xb
  jmp alltraps
80105191:	e9 61 fb ff ff       	jmp    80104cf7 <alltraps>

80105196 <vector12>:
.globl vector12
vector12:
  pushl $12
80105196:	6a 0c                	push   $0xc
  jmp alltraps
80105198:	e9 5a fb ff ff       	jmp    80104cf7 <alltraps>

8010519d <vector13>:
.globl vector13
vector13:
  pushl $13
8010519d:	6a 0d                	push   $0xd
  jmp alltraps
8010519f:	e9 53 fb ff ff       	jmp    80104cf7 <alltraps>

801051a4 <vector14>:
.globl vector14
vector14:
  pushl $14
801051a4:	6a 0e                	push   $0xe
  jmp alltraps
801051a6:	e9 4c fb ff ff       	jmp    80104cf7 <alltraps>

801051ab <vector15>:
.globl vector15
vector15:
  pushl $0
801051ab:	6a 00                	push   $0x0
  pushl $15
801051ad:	6a 0f                	push   $0xf
  jmp alltraps
801051af:	e9 43 fb ff ff       	jmp    80104cf7 <alltraps>

801051b4 <vector16>:
.globl vector16
vector16:
  pushl $0
801051b4:	6a 00                	push   $0x0
  pushl $16
801051b6:	6a 10                	push   $0x10
  jmp alltraps
801051b8:	e9 3a fb ff ff       	jmp    80104cf7 <alltraps>

801051bd <vector17>:
.globl vector17
vector17:
  pushl $17
801051bd:	6a 11                	push   $0x11
  jmp alltraps
801051bf:	e9 33 fb ff ff       	jmp    80104cf7 <alltraps>

801051c4 <vector18>:
.globl vector18
vector18:
  pushl $0
801051c4:	6a 00                	push   $0x0
  pushl $18
801051c6:	6a 12                	push   $0x12
  jmp alltraps
801051c8:	e9 2a fb ff ff       	jmp    80104cf7 <alltraps>

801051cd <vector19>:
.globl vector19
vector19:
  pushl $0
801051cd:	6a 00                	push   $0x0
  pushl $19
801051cf:	6a 13                	push   $0x13
  jmp alltraps
801051d1:	e9 21 fb ff ff       	jmp    80104cf7 <alltraps>

801051d6 <vector20>:
.globl vector20
vector20:
  pushl $0
801051d6:	6a 00                	push   $0x0
  pushl $20
801051d8:	6a 14                	push   $0x14
  jmp alltraps
801051da:	e9 18 fb ff ff       	jmp    80104cf7 <alltraps>

801051df <vector21>:
.globl vector21
vector21:
  pushl $0
801051df:	6a 00                	push   $0x0
  pushl $21
801051e1:	6a 15                	push   $0x15
  jmp alltraps
801051e3:	e9 0f fb ff ff       	jmp    80104cf7 <alltraps>

801051e8 <vector22>:
.globl vector22
vector22:
  pushl $0
801051e8:	6a 00                	push   $0x0
  pushl $22
801051ea:	6a 16                	push   $0x16
  jmp alltraps
801051ec:	e9 06 fb ff ff       	jmp    80104cf7 <alltraps>

801051f1 <vector23>:
.globl vector23
vector23:
  pushl $0
801051f1:	6a 00                	push   $0x0
  pushl $23
801051f3:	6a 17                	push   $0x17
  jmp alltraps
801051f5:	e9 fd fa ff ff       	jmp    80104cf7 <alltraps>

801051fa <vector24>:
.globl vector24
vector24:
  pushl $0
801051fa:	6a 00                	push   $0x0
  pushl $24
801051fc:	6a 18                	push   $0x18
  jmp alltraps
801051fe:	e9 f4 fa ff ff       	jmp    80104cf7 <alltraps>

80105203 <vector25>:
.globl vector25
vector25:
  pushl $0
80105203:	6a 00                	push   $0x0
  pushl $25
80105205:	6a 19                	push   $0x19
  jmp alltraps
80105207:	e9 eb fa ff ff       	jmp    80104cf7 <alltraps>

8010520c <vector26>:
.globl vector26
vector26:
  pushl $0
8010520c:	6a 00                	push   $0x0
  pushl $26
8010520e:	6a 1a                	push   $0x1a
  jmp alltraps
80105210:	e9 e2 fa ff ff       	jmp    80104cf7 <alltraps>

80105215 <vector27>:
.globl vector27
vector27:
  pushl $0
80105215:	6a 00                	push   $0x0
  pushl $27
80105217:	6a 1b                	push   $0x1b
  jmp alltraps
80105219:	e9 d9 fa ff ff       	jmp    80104cf7 <alltraps>

8010521e <vector28>:
.globl vector28
vector28:
  pushl $0
8010521e:	6a 00                	push   $0x0
  pushl $28
80105220:	6a 1c                	push   $0x1c
  jmp alltraps
80105222:	e9 d0 fa ff ff       	jmp    80104cf7 <alltraps>

80105227 <vector29>:
.globl vector29
vector29:
  pushl $0
80105227:	6a 00                	push   $0x0
  pushl $29
80105229:	6a 1d                	push   $0x1d
  jmp alltraps
8010522b:	e9 c7 fa ff ff       	jmp    80104cf7 <alltraps>

80105230 <vector30>:
.globl vector30
vector30:
  pushl $0
80105230:	6a 00                	push   $0x0
  pushl $30
80105232:	6a 1e                	push   $0x1e
  jmp alltraps
80105234:	e9 be fa ff ff       	jmp    80104cf7 <alltraps>

80105239 <vector31>:
.globl vector31
vector31:
  pushl $0
80105239:	6a 00                	push   $0x0
  pushl $31
8010523b:	6a 1f                	push   $0x1f
  jmp alltraps
8010523d:	e9 b5 fa ff ff       	jmp    80104cf7 <alltraps>

80105242 <vector32>:
.globl vector32
vector32:
  pushl $0
80105242:	6a 00                	push   $0x0
  pushl $32
80105244:	6a 20                	push   $0x20
  jmp alltraps
80105246:	e9 ac fa ff ff       	jmp    80104cf7 <alltraps>

8010524b <vector33>:
.globl vector33
vector33:
  pushl $0
8010524b:	6a 00                	push   $0x0
  pushl $33
8010524d:	6a 21                	push   $0x21
  jmp alltraps
8010524f:	e9 a3 fa ff ff       	jmp    80104cf7 <alltraps>

80105254 <vector34>:
.globl vector34
vector34:
  pushl $0
80105254:	6a 00                	push   $0x0
  pushl $34
80105256:	6a 22                	push   $0x22
  jmp alltraps
80105258:	e9 9a fa ff ff       	jmp    80104cf7 <alltraps>

8010525d <vector35>:
.globl vector35
vector35:
  pushl $0
8010525d:	6a 00                	push   $0x0
  pushl $35
8010525f:	6a 23                	push   $0x23
  jmp alltraps
80105261:	e9 91 fa ff ff       	jmp    80104cf7 <alltraps>

80105266 <vector36>:
.globl vector36
vector36:
  pushl $0
80105266:	6a 00                	push   $0x0
  pushl $36
80105268:	6a 24                	push   $0x24
  jmp alltraps
8010526a:	e9 88 fa ff ff       	jmp    80104cf7 <alltraps>

8010526f <vector37>:
.globl vector37
vector37:
  pushl $0
8010526f:	6a 00                	push   $0x0
  pushl $37
80105271:	6a 25                	push   $0x25
  jmp alltraps
80105273:	e9 7f fa ff ff       	jmp    80104cf7 <alltraps>

80105278 <vector38>:
.globl vector38
vector38:
  pushl $0
80105278:	6a 00                	push   $0x0
  pushl $38
8010527a:	6a 26                	push   $0x26
  jmp alltraps
8010527c:	e9 76 fa ff ff       	jmp    80104cf7 <alltraps>

80105281 <vector39>:
.globl vector39
vector39:
  pushl $0
80105281:	6a 00                	push   $0x0
  pushl $39
80105283:	6a 27                	push   $0x27
  jmp alltraps
80105285:	e9 6d fa ff ff       	jmp    80104cf7 <alltraps>

8010528a <vector40>:
.globl vector40
vector40:
  pushl $0
8010528a:	6a 00                	push   $0x0
  pushl $40
8010528c:	6a 28                	push   $0x28
  jmp alltraps
8010528e:	e9 64 fa ff ff       	jmp    80104cf7 <alltraps>

80105293 <vector41>:
.globl vector41
vector41:
  pushl $0
80105293:	6a 00                	push   $0x0
  pushl $41
80105295:	6a 29                	push   $0x29
  jmp alltraps
80105297:	e9 5b fa ff ff       	jmp    80104cf7 <alltraps>

8010529c <vector42>:
.globl vector42
vector42:
  pushl $0
8010529c:	6a 00                	push   $0x0
  pushl $42
8010529e:	6a 2a                	push   $0x2a
  jmp alltraps
801052a0:	e9 52 fa ff ff       	jmp    80104cf7 <alltraps>

801052a5 <vector43>:
.globl vector43
vector43:
  pushl $0
801052a5:	6a 00                	push   $0x0
  pushl $43
801052a7:	6a 2b                	push   $0x2b
  jmp alltraps
801052a9:	e9 49 fa ff ff       	jmp    80104cf7 <alltraps>

801052ae <vector44>:
.globl vector44
vector44:
  pushl $0
801052ae:	6a 00                	push   $0x0
  pushl $44
801052b0:	6a 2c                	push   $0x2c
  jmp alltraps
801052b2:	e9 40 fa ff ff       	jmp    80104cf7 <alltraps>

801052b7 <vector45>:
.globl vector45
vector45:
  pushl $0
801052b7:	6a 00                	push   $0x0
  pushl $45
801052b9:	6a 2d                	push   $0x2d
  jmp alltraps
801052bb:	e9 37 fa ff ff       	jmp    80104cf7 <alltraps>

801052c0 <vector46>:
.globl vector46
vector46:
  pushl $0
801052c0:	6a 00                	push   $0x0
  pushl $46
801052c2:	6a 2e                	push   $0x2e
  jmp alltraps
801052c4:	e9 2e fa ff ff       	jmp    80104cf7 <alltraps>

801052c9 <vector47>:
.globl vector47
vector47:
  pushl $0
801052c9:	6a 00                	push   $0x0
  pushl $47
801052cb:	6a 2f                	push   $0x2f
  jmp alltraps
801052cd:	e9 25 fa ff ff       	jmp    80104cf7 <alltraps>

801052d2 <vector48>:
.globl vector48
vector48:
  pushl $0
801052d2:	6a 00                	push   $0x0
  pushl $48
801052d4:	6a 30                	push   $0x30
  jmp alltraps
801052d6:	e9 1c fa ff ff       	jmp    80104cf7 <alltraps>

801052db <vector49>:
.globl vector49
vector49:
  pushl $0
801052db:	6a 00                	push   $0x0
  pushl $49
801052dd:	6a 31                	push   $0x31
  jmp alltraps
801052df:	e9 13 fa ff ff       	jmp    80104cf7 <alltraps>

801052e4 <vector50>:
.globl vector50
vector50:
  pushl $0
801052e4:	6a 00                	push   $0x0
  pushl $50
801052e6:	6a 32                	push   $0x32
  jmp alltraps
801052e8:	e9 0a fa ff ff       	jmp    80104cf7 <alltraps>

801052ed <vector51>:
.globl vector51
vector51:
  pushl $0
801052ed:	6a 00                	push   $0x0
  pushl $51
801052ef:	6a 33                	push   $0x33
  jmp alltraps
801052f1:	e9 01 fa ff ff       	jmp    80104cf7 <alltraps>

801052f6 <vector52>:
.globl vector52
vector52:
  pushl $0
801052f6:	6a 00                	push   $0x0
  pushl $52
801052f8:	6a 34                	push   $0x34
  jmp alltraps
801052fa:	e9 f8 f9 ff ff       	jmp    80104cf7 <alltraps>

801052ff <vector53>:
.globl vector53
vector53:
  pushl $0
801052ff:	6a 00                	push   $0x0
  pushl $53
80105301:	6a 35                	push   $0x35
  jmp alltraps
80105303:	e9 ef f9 ff ff       	jmp    80104cf7 <alltraps>

80105308 <vector54>:
.globl vector54
vector54:
  pushl $0
80105308:	6a 00                	push   $0x0
  pushl $54
8010530a:	6a 36                	push   $0x36
  jmp alltraps
8010530c:	e9 e6 f9 ff ff       	jmp    80104cf7 <alltraps>

80105311 <vector55>:
.globl vector55
vector55:
  pushl $0
80105311:	6a 00                	push   $0x0
  pushl $55
80105313:	6a 37                	push   $0x37
  jmp alltraps
80105315:	e9 dd f9 ff ff       	jmp    80104cf7 <alltraps>

8010531a <vector56>:
.globl vector56
vector56:
  pushl $0
8010531a:	6a 00                	push   $0x0
  pushl $56
8010531c:	6a 38                	push   $0x38
  jmp alltraps
8010531e:	e9 d4 f9 ff ff       	jmp    80104cf7 <alltraps>

80105323 <vector57>:
.globl vector57
vector57:
  pushl $0
80105323:	6a 00                	push   $0x0
  pushl $57
80105325:	6a 39                	push   $0x39
  jmp alltraps
80105327:	e9 cb f9 ff ff       	jmp    80104cf7 <alltraps>

8010532c <vector58>:
.globl vector58
vector58:
  pushl $0
8010532c:	6a 00                	push   $0x0
  pushl $58
8010532e:	6a 3a                	push   $0x3a
  jmp alltraps
80105330:	e9 c2 f9 ff ff       	jmp    80104cf7 <alltraps>

80105335 <vector59>:
.globl vector59
vector59:
  pushl $0
80105335:	6a 00                	push   $0x0
  pushl $59
80105337:	6a 3b                	push   $0x3b
  jmp alltraps
80105339:	e9 b9 f9 ff ff       	jmp    80104cf7 <alltraps>

8010533e <vector60>:
.globl vector60
vector60:
  pushl $0
8010533e:	6a 00                	push   $0x0
  pushl $60
80105340:	6a 3c                	push   $0x3c
  jmp alltraps
80105342:	e9 b0 f9 ff ff       	jmp    80104cf7 <alltraps>

80105347 <vector61>:
.globl vector61
vector61:
  pushl $0
80105347:	6a 00                	push   $0x0
  pushl $61
80105349:	6a 3d                	push   $0x3d
  jmp alltraps
8010534b:	e9 a7 f9 ff ff       	jmp    80104cf7 <alltraps>

80105350 <vector62>:
.globl vector62
vector62:
  pushl $0
80105350:	6a 00                	push   $0x0
  pushl $62
80105352:	6a 3e                	push   $0x3e
  jmp alltraps
80105354:	e9 9e f9 ff ff       	jmp    80104cf7 <alltraps>

80105359 <vector63>:
.globl vector63
vector63:
  pushl $0
80105359:	6a 00                	push   $0x0
  pushl $63
8010535b:	6a 3f                	push   $0x3f
  jmp alltraps
8010535d:	e9 95 f9 ff ff       	jmp    80104cf7 <alltraps>

80105362 <vector64>:
.globl vector64
vector64:
  pushl $0
80105362:	6a 00                	push   $0x0
  pushl $64
80105364:	6a 40                	push   $0x40
  jmp alltraps
80105366:	e9 8c f9 ff ff       	jmp    80104cf7 <alltraps>

8010536b <vector65>:
.globl vector65
vector65:
  pushl $0
8010536b:	6a 00                	push   $0x0
  pushl $65
8010536d:	6a 41                	push   $0x41
  jmp alltraps
8010536f:	e9 83 f9 ff ff       	jmp    80104cf7 <alltraps>

80105374 <vector66>:
.globl vector66
vector66:
  pushl $0
80105374:	6a 00                	push   $0x0
  pushl $66
80105376:	6a 42                	push   $0x42
  jmp alltraps
80105378:	e9 7a f9 ff ff       	jmp    80104cf7 <alltraps>

8010537d <vector67>:
.globl vector67
vector67:
  pushl $0
8010537d:	6a 00                	push   $0x0
  pushl $67
8010537f:	6a 43                	push   $0x43
  jmp alltraps
80105381:	e9 71 f9 ff ff       	jmp    80104cf7 <alltraps>

80105386 <vector68>:
.globl vector68
vector68:
  pushl $0
80105386:	6a 00                	push   $0x0
  pushl $68
80105388:	6a 44                	push   $0x44
  jmp alltraps
8010538a:	e9 68 f9 ff ff       	jmp    80104cf7 <alltraps>

8010538f <vector69>:
.globl vector69
vector69:
  pushl $0
8010538f:	6a 00                	push   $0x0
  pushl $69
80105391:	6a 45                	push   $0x45
  jmp alltraps
80105393:	e9 5f f9 ff ff       	jmp    80104cf7 <alltraps>

80105398 <vector70>:
.globl vector70
vector70:
  pushl $0
80105398:	6a 00                	push   $0x0
  pushl $70
8010539a:	6a 46                	push   $0x46
  jmp alltraps
8010539c:	e9 56 f9 ff ff       	jmp    80104cf7 <alltraps>

801053a1 <vector71>:
.globl vector71
vector71:
  pushl $0
801053a1:	6a 00                	push   $0x0
  pushl $71
801053a3:	6a 47                	push   $0x47
  jmp alltraps
801053a5:	e9 4d f9 ff ff       	jmp    80104cf7 <alltraps>

801053aa <vector72>:
.globl vector72
vector72:
  pushl $0
801053aa:	6a 00                	push   $0x0
  pushl $72
801053ac:	6a 48                	push   $0x48
  jmp alltraps
801053ae:	e9 44 f9 ff ff       	jmp    80104cf7 <alltraps>

801053b3 <vector73>:
.globl vector73
vector73:
  pushl $0
801053b3:	6a 00                	push   $0x0
  pushl $73
801053b5:	6a 49                	push   $0x49
  jmp alltraps
801053b7:	e9 3b f9 ff ff       	jmp    80104cf7 <alltraps>

801053bc <vector74>:
.globl vector74
vector74:
  pushl $0
801053bc:	6a 00                	push   $0x0
  pushl $74
801053be:	6a 4a                	push   $0x4a
  jmp alltraps
801053c0:	e9 32 f9 ff ff       	jmp    80104cf7 <alltraps>

801053c5 <vector75>:
.globl vector75
vector75:
  pushl $0
801053c5:	6a 00                	push   $0x0
  pushl $75
801053c7:	6a 4b                	push   $0x4b
  jmp alltraps
801053c9:	e9 29 f9 ff ff       	jmp    80104cf7 <alltraps>

801053ce <vector76>:
.globl vector76
vector76:
  pushl $0
801053ce:	6a 00                	push   $0x0
  pushl $76
801053d0:	6a 4c                	push   $0x4c
  jmp alltraps
801053d2:	e9 20 f9 ff ff       	jmp    80104cf7 <alltraps>

801053d7 <vector77>:
.globl vector77
vector77:
  pushl $0
801053d7:	6a 00                	push   $0x0
  pushl $77
801053d9:	6a 4d                	push   $0x4d
  jmp alltraps
801053db:	e9 17 f9 ff ff       	jmp    80104cf7 <alltraps>

801053e0 <vector78>:
.globl vector78
vector78:
  pushl $0
801053e0:	6a 00                	push   $0x0
  pushl $78
801053e2:	6a 4e                	push   $0x4e
  jmp alltraps
801053e4:	e9 0e f9 ff ff       	jmp    80104cf7 <alltraps>

801053e9 <vector79>:
.globl vector79
vector79:
  pushl $0
801053e9:	6a 00                	push   $0x0
  pushl $79
801053eb:	6a 4f                	push   $0x4f
  jmp alltraps
801053ed:	e9 05 f9 ff ff       	jmp    80104cf7 <alltraps>

801053f2 <vector80>:
.globl vector80
vector80:
  pushl $0
801053f2:	6a 00                	push   $0x0
  pushl $80
801053f4:	6a 50                	push   $0x50
  jmp alltraps
801053f6:	e9 fc f8 ff ff       	jmp    80104cf7 <alltraps>

801053fb <vector81>:
.globl vector81
vector81:
  pushl $0
801053fb:	6a 00                	push   $0x0
  pushl $81
801053fd:	6a 51                	push   $0x51
  jmp alltraps
801053ff:	e9 f3 f8 ff ff       	jmp    80104cf7 <alltraps>

80105404 <vector82>:
.globl vector82
vector82:
  pushl $0
80105404:	6a 00                	push   $0x0
  pushl $82
80105406:	6a 52                	push   $0x52
  jmp alltraps
80105408:	e9 ea f8 ff ff       	jmp    80104cf7 <alltraps>

8010540d <vector83>:
.globl vector83
vector83:
  pushl $0
8010540d:	6a 00                	push   $0x0
  pushl $83
8010540f:	6a 53                	push   $0x53
  jmp alltraps
80105411:	e9 e1 f8 ff ff       	jmp    80104cf7 <alltraps>

80105416 <vector84>:
.globl vector84
vector84:
  pushl $0
80105416:	6a 00                	push   $0x0
  pushl $84
80105418:	6a 54                	push   $0x54
  jmp alltraps
8010541a:	e9 d8 f8 ff ff       	jmp    80104cf7 <alltraps>

8010541f <vector85>:
.globl vector85
vector85:
  pushl $0
8010541f:	6a 00                	push   $0x0
  pushl $85
80105421:	6a 55                	push   $0x55
  jmp alltraps
80105423:	e9 cf f8 ff ff       	jmp    80104cf7 <alltraps>

80105428 <vector86>:
.globl vector86
vector86:
  pushl $0
80105428:	6a 00                	push   $0x0
  pushl $86
8010542a:	6a 56                	push   $0x56
  jmp alltraps
8010542c:	e9 c6 f8 ff ff       	jmp    80104cf7 <alltraps>

80105431 <vector87>:
.globl vector87
vector87:
  pushl $0
80105431:	6a 00                	push   $0x0
  pushl $87
80105433:	6a 57                	push   $0x57
  jmp alltraps
80105435:	e9 bd f8 ff ff       	jmp    80104cf7 <alltraps>

8010543a <vector88>:
.globl vector88
vector88:
  pushl $0
8010543a:	6a 00                	push   $0x0
  pushl $88
8010543c:	6a 58                	push   $0x58
  jmp alltraps
8010543e:	e9 b4 f8 ff ff       	jmp    80104cf7 <alltraps>

80105443 <vector89>:
.globl vector89
vector89:
  pushl $0
80105443:	6a 00                	push   $0x0
  pushl $89
80105445:	6a 59                	push   $0x59
  jmp alltraps
80105447:	e9 ab f8 ff ff       	jmp    80104cf7 <alltraps>

8010544c <vector90>:
.globl vector90
vector90:
  pushl $0
8010544c:	6a 00                	push   $0x0
  pushl $90
8010544e:	6a 5a                	push   $0x5a
  jmp alltraps
80105450:	e9 a2 f8 ff ff       	jmp    80104cf7 <alltraps>

80105455 <vector91>:
.globl vector91
vector91:
  pushl $0
80105455:	6a 00                	push   $0x0
  pushl $91
80105457:	6a 5b                	push   $0x5b
  jmp alltraps
80105459:	e9 99 f8 ff ff       	jmp    80104cf7 <alltraps>

8010545e <vector92>:
.globl vector92
vector92:
  pushl $0
8010545e:	6a 00                	push   $0x0
  pushl $92
80105460:	6a 5c                	push   $0x5c
  jmp alltraps
80105462:	e9 90 f8 ff ff       	jmp    80104cf7 <alltraps>

80105467 <vector93>:
.globl vector93
vector93:
  pushl $0
80105467:	6a 00                	push   $0x0
  pushl $93
80105469:	6a 5d                	push   $0x5d
  jmp alltraps
8010546b:	e9 87 f8 ff ff       	jmp    80104cf7 <alltraps>

80105470 <vector94>:
.globl vector94
vector94:
  pushl $0
80105470:	6a 00                	push   $0x0
  pushl $94
80105472:	6a 5e                	push   $0x5e
  jmp alltraps
80105474:	e9 7e f8 ff ff       	jmp    80104cf7 <alltraps>

80105479 <vector95>:
.globl vector95
vector95:
  pushl $0
80105479:	6a 00                	push   $0x0
  pushl $95
8010547b:	6a 5f                	push   $0x5f
  jmp alltraps
8010547d:	e9 75 f8 ff ff       	jmp    80104cf7 <alltraps>

80105482 <vector96>:
.globl vector96
vector96:
  pushl $0
80105482:	6a 00                	push   $0x0
  pushl $96
80105484:	6a 60                	push   $0x60
  jmp alltraps
80105486:	e9 6c f8 ff ff       	jmp    80104cf7 <alltraps>

8010548b <vector97>:
.globl vector97
vector97:
  pushl $0
8010548b:	6a 00                	push   $0x0
  pushl $97
8010548d:	6a 61                	push   $0x61
  jmp alltraps
8010548f:	e9 63 f8 ff ff       	jmp    80104cf7 <alltraps>

80105494 <vector98>:
.globl vector98
vector98:
  pushl $0
80105494:	6a 00                	push   $0x0
  pushl $98
80105496:	6a 62                	push   $0x62
  jmp alltraps
80105498:	e9 5a f8 ff ff       	jmp    80104cf7 <alltraps>

8010549d <vector99>:
.globl vector99
vector99:
  pushl $0
8010549d:	6a 00                	push   $0x0
  pushl $99
8010549f:	6a 63                	push   $0x63
  jmp alltraps
801054a1:	e9 51 f8 ff ff       	jmp    80104cf7 <alltraps>

801054a6 <vector100>:
.globl vector100
vector100:
  pushl $0
801054a6:	6a 00                	push   $0x0
  pushl $100
801054a8:	6a 64                	push   $0x64
  jmp alltraps
801054aa:	e9 48 f8 ff ff       	jmp    80104cf7 <alltraps>

801054af <vector101>:
.globl vector101
vector101:
  pushl $0
801054af:	6a 00                	push   $0x0
  pushl $101
801054b1:	6a 65                	push   $0x65
  jmp alltraps
801054b3:	e9 3f f8 ff ff       	jmp    80104cf7 <alltraps>

801054b8 <vector102>:
.globl vector102
vector102:
  pushl $0
801054b8:	6a 00                	push   $0x0
  pushl $102
801054ba:	6a 66                	push   $0x66
  jmp alltraps
801054bc:	e9 36 f8 ff ff       	jmp    80104cf7 <alltraps>

801054c1 <vector103>:
.globl vector103
vector103:
  pushl $0
801054c1:	6a 00                	push   $0x0
  pushl $103
801054c3:	6a 67                	push   $0x67
  jmp alltraps
801054c5:	e9 2d f8 ff ff       	jmp    80104cf7 <alltraps>

801054ca <vector104>:
.globl vector104
vector104:
  pushl $0
801054ca:	6a 00                	push   $0x0
  pushl $104
801054cc:	6a 68                	push   $0x68
  jmp alltraps
801054ce:	e9 24 f8 ff ff       	jmp    80104cf7 <alltraps>

801054d3 <vector105>:
.globl vector105
vector105:
  pushl $0
801054d3:	6a 00                	push   $0x0
  pushl $105
801054d5:	6a 69                	push   $0x69
  jmp alltraps
801054d7:	e9 1b f8 ff ff       	jmp    80104cf7 <alltraps>

801054dc <vector106>:
.globl vector106
vector106:
  pushl $0
801054dc:	6a 00                	push   $0x0
  pushl $106
801054de:	6a 6a                	push   $0x6a
  jmp alltraps
801054e0:	e9 12 f8 ff ff       	jmp    80104cf7 <alltraps>

801054e5 <vector107>:
.globl vector107
vector107:
  pushl $0
801054e5:	6a 00                	push   $0x0
  pushl $107
801054e7:	6a 6b                	push   $0x6b
  jmp alltraps
801054e9:	e9 09 f8 ff ff       	jmp    80104cf7 <alltraps>

801054ee <vector108>:
.globl vector108
vector108:
  pushl $0
801054ee:	6a 00                	push   $0x0
  pushl $108
801054f0:	6a 6c                	push   $0x6c
  jmp alltraps
801054f2:	e9 00 f8 ff ff       	jmp    80104cf7 <alltraps>

801054f7 <vector109>:
.globl vector109
vector109:
  pushl $0
801054f7:	6a 00                	push   $0x0
  pushl $109
801054f9:	6a 6d                	push   $0x6d
  jmp alltraps
801054fb:	e9 f7 f7 ff ff       	jmp    80104cf7 <alltraps>

80105500 <vector110>:
.globl vector110
vector110:
  pushl $0
80105500:	6a 00                	push   $0x0
  pushl $110
80105502:	6a 6e                	push   $0x6e
  jmp alltraps
80105504:	e9 ee f7 ff ff       	jmp    80104cf7 <alltraps>

80105509 <vector111>:
.globl vector111
vector111:
  pushl $0
80105509:	6a 00                	push   $0x0
  pushl $111
8010550b:	6a 6f                	push   $0x6f
  jmp alltraps
8010550d:	e9 e5 f7 ff ff       	jmp    80104cf7 <alltraps>

80105512 <vector112>:
.globl vector112
vector112:
  pushl $0
80105512:	6a 00                	push   $0x0
  pushl $112
80105514:	6a 70                	push   $0x70
  jmp alltraps
80105516:	e9 dc f7 ff ff       	jmp    80104cf7 <alltraps>

8010551b <vector113>:
.globl vector113
vector113:
  pushl $0
8010551b:	6a 00                	push   $0x0
  pushl $113
8010551d:	6a 71                	push   $0x71
  jmp alltraps
8010551f:	e9 d3 f7 ff ff       	jmp    80104cf7 <alltraps>

80105524 <vector114>:
.globl vector114
vector114:
  pushl $0
80105524:	6a 00                	push   $0x0
  pushl $114
80105526:	6a 72                	push   $0x72
  jmp alltraps
80105528:	e9 ca f7 ff ff       	jmp    80104cf7 <alltraps>

8010552d <vector115>:
.globl vector115
vector115:
  pushl $0
8010552d:	6a 00                	push   $0x0
  pushl $115
8010552f:	6a 73                	push   $0x73
  jmp alltraps
80105531:	e9 c1 f7 ff ff       	jmp    80104cf7 <alltraps>

80105536 <vector116>:
.globl vector116
vector116:
  pushl $0
80105536:	6a 00                	push   $0x0
  pushl $116
80105538:	6a 74                	push   $0x74
  jmp alltraps
8010553a:	e9 b8 f7 ff ff       	jmp    80104cf7 <alltraps>

8010553f <vector117>:
.globl vector117
vector117:
  pushl $0
8010553f:	6a 00                	push   $0x0
  pushl $117
80105541:	6a 75                	push   $0x75
  jmp alltraps
80105543:	e9 af f7 ff ff       	jmp    80104cf7 <alltraps>

80105548 <vector118>:
.globl vector118
vector118:
  pushl $0
80105548:	6a 00                	push   $0x0
  pushl $118
8010554a:	6a 76                	push   $0x76
  jmp alltraps
8010554c:	e9 a6 f7 ff ff       	jmp    80104cf7 <alltraps>

80105551 <vector119>:
.globl vector119
vector119:
  pushl $0
80105551:	6a 00                	push   $0x0
  pushl $119
80105553:	6a 77                	push   $0x77
  jmp alltraps
80105555:	e9 9d f7 ff ff       	jmp    80104cf7 <alltraps>

8010555a <vector120>:
.globl vector120
vector120:
  pushl $0
8010555a:	6a 00                	push   $0x0
  pushl $120
8010555c:	6a 78                	push   $0x78
  jmp alltraps
8010555e:	e9 94 f7 ff ff       	jmp    80104cf7 <alltraps>

80105563 <vector121>:
.globl vector121
vector121:
  pushl $0
80105563:	6a 00                	push   $0x0
  pushl $121
80105565:	6a 79                	push   $0x79
  jmp alltraps
80105567:	e9 8b f7 ff ff       	jmp    80104cf7 <alltraps>

8010556c <vector122>:
.globl vector122
vector122:
  pushl $0
8010556c:	6a 00                	push   $0x0
  pushl $122
8010556e:	6a 7a                	push   $0x7a
  jmp alltraps
80105570:	e9 82 f7 ff ff       	jmp    80104cf7 <alltraps>

80105575 <vector123>:
.globl vector123
vector123:
  pushl $0
80105575:	6a 00                	push   $0x0
  pushl $123
80105577:	6a 7b                	push   $0x7b
  jmp alltraps
80105579:	e9 79 f7 ff ff       	jmp    80104cf7 <alltraps>

8010557e <vector124>:
.globl vector124
vector124:
  pushl $0
8010557e:	6a 00                	push   $0x0
  pushl $124
80105580:	6a 7c                	push   $0x7c
  jmp alltraps
80105582:	e9 70 f7 ff ff       	jmp    80104cf7 <alltraps>

80105587 <vector125>:
.globl vector125
vector125:
  pushl $0
80105587:	6a 00                	push   $0x0
  pushl $125
80105589:	6a 7d                	push   $0x7d
  jmp alltraps
8010558b:	e9 67 f7 ff ff       	jmp    80104cf7 <alltraps>

80105590 <vector126>:
.globl vector126
vector126:
  pushl $0
80105590:	6a 00                	push   $0x0
  pushl $126
80105592:	6a 7e                	push   $0x7e
  jmp alltraps
80105594:	e9 5e f7 ff ff       	jmp    80104cf7 <alltraps>

80105599 <vector127>:
.globl vector127
vector127:
  pushl $0
80105599:	6a 00                	push   $0x0
  pushl $127
8010559b:	6a 7f                	push   $0x7f
  jmp alltraps
8010559d:	e9 55 f7 ff ff       	jmp    80104cf7 <alltraps>

801055a2 <vector128>:
.globl vector128
vector128:
  pushl $0
801055a2:	6a 00                	push   $0x0
  pushl $128
801055a4:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801055a9:	e9 49 f7 ff ff       	jmp    80104cf7 <alltraps>

801055ae <vector129>:
.globl vector129
vector129:
  pushl $0
801055ae:	6a 00                	push   $0x0
  pushl $129
801055b0:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801055b5:	e9 3d f7 ff ff       	jmp    80104cf7 <alltraps>

801055ba <vector130>:
.globl vector130
vector130:
  pushl $0
801055ba:	6a 00                	push   $0x0
  pushl $130
801055bc:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801055c1:	e9 31 f7 ff ff       	jmp    80104cf7 <alltraps>

801055c6 <vector131>:
.globl vector131
vector131:
  pushl $0
801055c6:	6a 00                	push   $0x0
  pushl $131
801055c8:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801055cd:	e9 25 f7 ff ff       	jmp    80104cf7 <alltraps>

801055d2 <vector132>:
.globl vector132
vector132:
  pushl $0
801055d2:	6a 00                	push   $0x0
  pushl $132
801055d4:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801055d9:	e9 19 f7 ff ff       	jmp    80104cf7 <alltraps>

801055de <vector133>:
.globl vector133
vector133:
  pushl $0
801055de:	6a 00                	push   $0x0
  pushl $133
801055e0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801055e5:	e9 0d f7 ff ff       	jmp    80104cf7 <alltraps>

801055ea <vector134>:
.globl vector134
vector134:
  pushl $0
801055ea:	6a 00                	push   $0x0
  pushl $134
801055ec:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801055f1:	e9 01 f7 ff ff       	jmp    80104cf7 <alltraps>

801055f6 <vector135>:
.globl vector135
vector135:
  pushl $0
801055f6:	6a 00                	push   $0x0
  pushl $135
801055f8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801055fd:	e9 f5 f6 ff ff       	jmp    80104cf7 <alltraps>

80105602 <vector136>:
.globl vector136
vector136:
  pushl $0
80105602:	6a 00                	push   $0x0
  pushl $136
80105604:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105609:	e9 e9 f6 ff ff       	jmp    80104cf7 <alltraps>

8010560e <vector137>:
.globl vector137
vector137:
  pushl $0
8010560e:	6a 00                	push   $0x0
  pushl $137
80105610:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105615:	e9 dd f6 ff ff       	jmp    80104cf7 <alltraps>

8010561a <vector138>:
.globl vector138
vector138:
  pushl $0
8010561a:	6a 00                	push   $0x0
  pushl $138
8010561c:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105621:	e9 d1 f6 ff ff       	jmp    80104cf7 <alltraps>

80105626 <vector139>:
.globl vector139
vector139:
  pushl $0
80105626:	6a 00                	push   $0x0
  pushl $139
80105628:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010562d:	e9 c5 f6 ff ff       	jmp    80104cf7 <alltraps>

80105632 <vector140>:
.globl vector140
vector140:
  pushl $0
80105632:	6a 00                	push   $0x0
  pushl $140
80105634:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105639:	e9 b9 f6 ff ff       	jmp    80104cf7 <alltraps>

8010563e <vector141>:
.globl vector141
vector141:
  pushl $0
8010563e:	6a 00                	push   $0x0
  pushl $141
80105640:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105645:	e9 ad f6 ff ff       	jmp    80104cf7 <alltraps>

8010564a <vector142>:
.globl vector142
vector142:
  pushl $0
8010564a:	6a 00                	push   $0x0
  pushl $142
8010564c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105651:	e9 a1 f6 ff ff       	jmp    80104cf7 <alltraps>

80105656 <vector143>:
.globl vector143
vector143:
  pushl $0
80105656:	6a 00                	push   $0x0
  pushl $143
80105658:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010565d:	e9 95 f6 ff ff       	jmp    80104cf7 <alltraps>

80105662 <vector144>:
.globl vector144
vector144:
  pushl $0
80105662:	6a 00                	push   $0x0
  pushl $144
80105664:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105669:	e9 89 f6 ff ff       	jmp    80104cf7 <alltraps>

8010566e <vector145>:
.globl vector145
vector145:
  pushl $0
8010566e:	6a 00                	push   $0x0
  pushl $145
80105670:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105675:	e9 7d f6 ff ff       	jmp    80104cf7 <alltraps>

8010567a <vector146>:
.globl vector146
vector146:
  pushl $0
8010567a:	6a 00                	push   $0x0
  pushl $146
8010567c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105681:	e9 71 f6 ff ff       	jmp    80104cf7 <alltraps>

80105686 <vector147>:
.globl vector147
vector147:
  pushl $0
80105686:	6a 00                	push   $0x0
  pushl $147
80105688:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010568d:	e9 65 f6 ff ff       	jmp    80104cf7 <alltraps>

80105692 <vector148>:
.globl vector148
vector148:
  pushl $0
80105692:	6a 00                	push   $0x0
  pushl $148
80105694:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105699:	e9 59 f6 ff ff       	jmp    80104cf7 <alltraps>

8010569e <vector149>:
.globl vector149
vector149:
  pushl $0
8010569e:	6a 00                	push   $0x0
  pushl $149
801056a0:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801056a5:	e9 4d f6 ff ff       	jmp    80104cf7 <alltraps>

801056aa <vector150>:
.globl vector150
vector150:
  pushl $0
801056aa:	6a 00                	push   $0x0
  pushl $150
801056ac:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801056b1:	e9 41 f6 ff ff       	jmp    80104cf7 <alltraps>

801056b6 <vector151>:
.globl vector151
vector151:
  pushl $0
801056b6:	6a 00                	push   $0x0
  pushl $151
801056b8:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801056bd:	e9 35 f6 ff ff       	jmp    80104cf7 <alltraps>

801056c2 <vector152>:
.globl vector152
vector152:
  pushl $0
801056c2:	6a 00                	push   $0x0
  pushl $152
801056c4:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801056c9:	e9 29 f6 ff ff       	jmp    80104cf7 <alltraps>

801056ce <vector153>:
.globl vector153
vector153:
  pushl $0
801056ce:	6a 00                	push   $0x0
  pushl $153
801056d0:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801056d5:	e9 1d f6 ff ff       	jmp    80104cf7 <alltraps>

801056da <vector154>:
.globl vector154
vector154:
  pushl $0
801056da:	6a 00                	push   $0x0
  pushl $154
801056dc:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801056e1:	e9 11 f6 ff ff       	jmp    80104cf7 <alltraps>

801056e6 <vector155>:
.globl vector155
vector155:
  pushl $0
801056e6:	6a 00                	push   $0x0
  pushl $155
801056e8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801056ed:	e9 05 f6 ff ff       	jmp    80104cf7 <alltraps>

801056f2 <vector156>:
.globl vector156
vector156:
  pushl $0
801056f2:	6a 00                	push   $0x0
  pushl $156
801056f4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801056f9:	e9 f9 f5 ff ff       	jmp    80104cf7 <alltraps>

801056fe <vector157>:
.globl vector157
vector157:
  pushl $0
801056fe:	6a 00                	push   $0x0
  pushl $157
80105700:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105705:	e9 ed f5 ff ff       	jmp    80104cf7 <alltraps>

8010570a <vector158>:
.globl vector158
vector158:
  pushl $0
8010570a:	6a 00                	push   $0x0
  pushl $158
8010570c:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105711:	e9 e1 f5 ff ff       	jmp    80104cf7 <alltraps>

80105716 <vector159>:
.globl vector159
vector159:
  pushl $0
80105716:	6a 00                	push   $0x0
  pushl $159
80105718:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010571d:	e9 d5 f5 ff ff       	jmp    80104cf7 <alltraps>

80105722 <vector160>:
.globl vector160
vector160:
  pushl $0
80105722:	6a 00                	push   $0x0
  pushl $160
80105724:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105729:	e9 c9 f5 ff ff       	jmp    80104cf7 <alltraps>

8010572e <vector161>:
.globl vector161
vector161:
  pushl $0
8010572e:	6a 00                	push   $0x0
  pushl $161
80105730:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105735:	e9 bd f5 ff ff       	jmp    80104cf7 <alltraps>

8010573a <vector162>:
.globl vector162
vector162:
  pushl $0
8010573a:	6a 00                	push   $0x0
  pushl $162
8010573c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105741:	e9 b1 f5 ff ff       	jmp    80104cf7 <alltraps>

80105746 <vector163>:
.globl vector163
vector163:
  pushl $0
80105746:	6a 00                	push   $0x0
  pushl $163
80105748:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010574d:	e9 a5 f5 ff ff       	jmp    80104cf7 <alltraps>

80105752 <vector164>:
.globl vector164
vector164:
  pushl $0
80105752:	6a 00                	push   $0x0
  pushl $164
80105754:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105759:	e9 99 f5 ff ff       	jmp    80104cf7 <alltraps>

8010575e <vector165>:
.globl vector165
vector165:
  pushl $0
8010575e:	6a 00                	push   $0x0
  pushl $165
80105760:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105765:	e9 8d f5 ff ff       	jmp    80104cf7 <alltraps>

8010576a <vector166>:
.globl vector166
vector166:
  pushl $0
8010576a:	6a 00                	push   $0x0
  pushl $166
8010576c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105771:	e9 81 f5 ff ff       	jmp    80104cf7 <alltraps>

80105776 <vector167>:
.globl vector167
vector167:
  pushl $0
80105776:	6a 00                	push   $0x0
  pushl $167
80105778:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010577d:	e9 75 f5 ff ff       	jmp    80104cf7 <alltraps>

80105782 <vector168>:
.globl vector168
vector168:
  pushl $0
80105782:	6a 00                	push   $0x0
  pushl $168
80105784:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105789:	e9 69 f5 ff ff       	jmp    80104cf7 <alltraps>

8010578e <vector169>:
.globl vector169
vector169:
  pushl $0
8010578e:	6a 00                	push   $0x0
  pushl $169
80105790:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105795:	e9 5d f5 ff ff       	jmp    80104cf7 <alltraps>

8010579a <vector170>:
.globl vector170
vector170:
  pushl $0
8010579a:	6a 00                	push   $0x0
  pushl $170
8010579c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801057a1:	e9 51 f5 ff ff       	jmp    80104cf7 <alltraps>

801057a6 <vector171>:
.globl vector171
vector171:
  pushl $0
801057a6:	6a 00                	push   $0x0
  pushl $171
801057a8:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801057ad:	e9 45 f5 ff ff       	jmp    80104cf7 <alltraps>

801057b2 <vector172>:
.globl vector172
vector172:
  pushl $0
801057b2:	6a 00                	push   $0x0
  pushl $172
801057b4:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801057b9:	e9 39 f5 ff ff       	jmp    80104cf7 <alltraps>

801057be <vector173>:
.globl vector173
vector173:
  pushl $0
801057be:	6a 00                	push   $0x0
  pushl $173
801057c0:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801057c5:	e9 2d f5 ff ff       	jmp    80104cf7 <alltraps>

801057ca <vector174>:
.globl vector174
vector174:
  pushl $0
801057ca:	6a 00                	push   $0x0
  pushl $174
801057cc:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801057d1:	e9 21 f5 ff ff       	jmp    80104cf7 <alltraps>

801057d6 <vector175>:
.globl vector175
vector175:
  pushl $0
801057d6:	6a 00                	push   $0x0
  pushl $175
801057d8:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801057dd:	e9 15 f5 ff ff       	jmp    80104cf7 <alltraps>

801057e2 <vector176>:
.globl vector176
vector176:
  pushl $0
801057e2:	6a 00                	push   $0x0
  pushl $176
801057e4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801057e9:	e9 09 f5 ff ff       	jmp    80104cf7 <alltraps>

801057ee <vector177>:
.globl vector177
vector177:
  pushl $0
801057ee:	6a 00                	push   $0x0
  pushl $177
801057f0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801057f5:	e9 fd f4 ff ff       	jmp    80104cf7 <alltraps>

801057fa <vector178>:
.globl vector178
vector178:
  pushl $0
801057fa:	6a 00                	push   $0x0
  pushl $178
801057fc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105801:	e9 f1 f4 ff ff       	jmp    80104cf7 <alltraps>

80105806 <vector179>:
.globl vector179
vector179:
  pushl $0
80105806:	6a 00                	push   $0x0
  pushl $179
80105808:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010580d:	e9 e5 f4 ff ff       	jmp    80104cf7 <alltraps>

80105812 <vector180>:
.globl vector180
vector180:
  pushl $0
80105812:	6a 00                	push   $0x0
  pushl $180
80105814:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105819:	e9 d9 f4 ff ff       	jmp    80104cf7 <alltraps>

8010581e <vector181>:
.globl vector181
vector181:
  pushl $0
8010581e:	6a 00                	push   $0x0
  pushl $181
80105820:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105825:	e9 cd f4 ff ff       	jmp    80104cf7 <alltraps>

8010582a <vector182>:
.globl vector182
vector182:
  pushl $0
8010582a:	6a 00                	push   $0x0
  pushl $182
8010582c:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105831:	e9 c1 f4 ff ff       	jmp    80104cf7 <alltraps>

80105836 <vector183>:
.globl vector183
vector183:
  pushl $0
80105836:	6a 00                	push   $0x0
  pushl $183
80105838:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010583d:	e9 b5 f4 ff ff       	jmp    80104cf7 <alltraps>

80105842 <vector184>:
.globl vector184
vector184:
  pushl $0
80105842:	6a 00                	push   $0x0
  pushl $184
80105844:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105849:	e9 a9 f4 ff ff       	jmp    80104cf7 <alltraps>

8010584e <vector185>:
.globl vector185
vector185:
  pushl $0
8010584e:	6a 00                	push   $0x0
  pushl $185
80105850:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105855:	e9 9d f4 ff ff       	jmp    80104cf7 <alltraps>

8010585a <vector186>:
.globl vector186
vector186:
  pushl $0
8010585a:	6a 00                	push   $0x0
  pushl $186
8010585c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105861:	e9 91 f4 ff ff       	jmp    80104cf7 <alltraps>

80105866 <vector187>:
.globl vector187
vector187:
  pushl $0
80105866:	6a 00                	push   $0x0
  pushl $187
80105868:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010586d:	e9 85 f4 ff ff       	jmp    80104cf7 <alltraps>

80105872 <vector188>:
.globl vector188
vector188:
  pushl $0
80105872:	6a 00                	push   $0x0
  pushl $188
80105874:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105879:	e9 79 f4 ff ff       	jmp    80104cf7 <alltraps>

8010587e <vector189>:
.globl vector189
vector189:
  pushl $0
8010587e:	6a 00                	push   $0x0
  pushl $189
80105880:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105885:	e9 6d f4 ff ff       	jmp    80104cf7 <alltraps>

8010588a <vector190>:
.globl vector190
vector190:
  pushl $0
8010588a:	6a 00                	push   $0x0
  pushl $190
8010588c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105891:	e9 61 f4 ff ff       	jmp    80104cf7 <alltraps>

80105896 <vector191>:
.globl vector191
vector191:
  pushl $0
80105896:	6a 00                	push   $0x0
  pushl $191
80105898:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010589d:	e9 55 f4 ff ff       	jmp    80104cf7 <alltraps>

801058a2 <vector192>:
.globl vector192
vector192:
  pushl $0
801058a2:	6a 00                	push   $0x0
  pushl $192
801058a4:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801058a9:	e9 49 f4 ff ff       	jmp    80104cf7 <alltraps>

801058ae <vector193>:
.globl vector193
vector193:
  pushl $0
801058ae:	6a 00                	push   $0x0
  pushl $193
801058b0:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801058b5:	e9 3d f4 ff ff       	jmp    80104cf7 <alltraps>

801058ba <vector194>:
.globl vector194
vector194:
  pushl $0
801058ba:	6a 00                	push   $0x0
  pushl $194
801058bc:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801058c1:	e9 31 f4 ff ff       	jmp    80104cf7 <alltraps>

801058c6 <vector195>:
.globl vector195
vector195:
  pushl $0
801058c6:	6a 00                	push   $0x0
  pushl $195
801058c8:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801058cd:	e9 25 f4 ff ff       	jmp    80104cf7 <alltraps>

801058d2 <vector196>:
.globl vector196
vector196:
  pushl $0
801058d2:	6a 00                	push   $0x0
  pushl $196
801058d4:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801058d9:	e9 19 f4 ff ff       	jmp    80104cf7 <alltraps>

801058de <vector197>:
.globl vector197
vector197:
  pushl $0
801058de:	6a 00                	push   $0x0
  pushl $197
801058e0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801058e5:	e9 0d f4 ff ff       	jmp    80104cf7 <alltraps>

801058ea <vector198>:
.globl vector198
vector198:
  pushl $0
801058ea:	6a 00                	push   $0x0
  pushl $198
801058ec:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801058f1:	e9 01 f4 ff ff       	jmp    80104cf7 <alltraps>

801058f6 <vector199>:
.globl vector199
vector199:
  pushl $0
801058f6:	6a 00                	push   $0x0
  pushl $199
801058f8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801058fd:	e9 f5 f3 ff ff       	jmp    80104cf7 <alltraps>

80105902 <vector200>:
.globl vector200
vector200:
  pushl $0
80105902:	6a 00                	push   $0x0
  pushl $200
80105904:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105909:	e9 e9 f3 ff ff       	jmp    80104cf7 <alltraps>

8010590e <vector201>:
.globl vector201
vector201:
  pushl $0
8010590e:	6a 00                	push   $0x0
  pushl $201
80105910:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105915:	e9 dd f3 ff ff       	jmp    80104cf7 <alltraps>

8010591a <vector202>:
.globl vector202
vector202:
  pushl $0
8010591a:	6a 00                	push   $0x0
  pushl $202
8010591c:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105921:	e9 d1 f3 ff ff       	jmp    80104cf7 <alltraps>

80105926 <vector203>:
.globl vector203
vector203:
  pushl $0
80105926:	6a 00                	push   $0x0
  pushl $203
80105928:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010592d:	e9 c5 f3 ff ff       	jmp    80104cf7 <alltraps>

80105932 <vector204>:
.globl vector204
vector204:
  pushl $0
80105932:	6a 00                	push   $0x0
  pushl $204
80105934:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105939:	e9 b9 f3 ff ff       	jmp    80104cf7 <alltraps>

8010593e <vector205>:
.globl vector205
vector205:
  pushl $0
8010593e:	6a 00                	push   $0x0
  pushl $205
80105940:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105945:	e9 ad f3 ff ff       	jmp    80104cf7 <alltraps>

8010594a <vector206>:
.globl vector206
vector206:
  pushl $0
8010594a:	6a 00                	push   $0x0
  pushl $206
8010594c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105951:	e9 a1 f3 ff ff       	jmp    80104cf7 <alltraps>

80105956 <vector207>:
.globl vector207
vector207:
  pushl $0
80105956:	6a 00                	push   $0x0
  pushl $207
80105958:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010595d:	e9 95 f3 ff ff       	jmp    80104cf7 <alltraps>

80105962 <vector208>:
.globl vector208
vector208:
  pushl $0
80105962:	6a 00                	push   $0x0
  pushl $208
80105964:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105969:	e9 89 f3 ff ff       	jmp    80104cf7 <alltraps>

8010596e <vector209>:
.globl vector209
vector209:
  pushl $0
8010596e:	6a 00                	push   $0x0
  pushl $209
80105970:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105975:	e9 7d f3 ff ff       	jmp    80104cf7 <alltraps>

8010597a <vector210>:
.globl vector210
vector210:
  pushl $0
8010597a:	6a 00                	push   $0x0
  pushl $210
8010597c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105981:	e9 71 f3 ff ff       	jmp    80104cf7 <alltraps>

80105986 <vector211>:
.globl vector211
vector211:
  pushl $0
80105986:	6a 00                	push   $0x0
  pushl $211
80105988:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010598d:	e9 65 f3 ff ff       	jmp    80104cf7 <alltraps>

80105992 <vector212>:
.globl vector212
vector212:
  pushl $0
80105992:	6a 00                	push   $0x0
  pushl $212
80105994:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105999:	e9 59 f3 ff ff       	jmp    80104cf7 <alltraps>

8010599e <vector213>:
.globl vector213
vector213:
  pushl $0
8010599e:	6a 00                	push   $0x0
  pushl $213
801059a0:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801059a5:	e9 4d f3 ff ff       	jmp    80104cf7 <alltraps>

801059aa <vector214>:
.globl vector214
vector214:
  pushl $0
801059aa:	6a 00                	push   $0x0
  pushl $214
801059ac:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801059b1:	e9 41 f3 ff ff       	jmp    80104cf7 <alltraps>

801059b6 <vector215>:
.globl vector215
vector215:
  pushl $0
801059b6:	6a 00                	push   $0x0
  pushl $215
801059b8:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801059bd:	e9 35 f3 ff ff       	jmp    80104cf7 <alltraps>

801059c2 <vector216>:
.globl vector216
vector216:
  pushl $0
801059c2:	6a 00                	push   $0x0
  pushl $216
801059c4:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801059c9:	e9 29 f3 ff ff       	jmp    80104cf7 <alltraps>

801059ce <vector217>:
.globl vector217
vector217:
  pushl $0
801059ce:	6a 00                	push   $0x0
  pushl $217
801059d0:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801059d5:	e9 1d f3 ff ff       	jmp    80104cf7 <alltraps>

801059da <vector218>:
.globl vector218
vector218:
  pushl $0
801059da:	6a 00                	push   $0x0
  pushl $218
801059dc:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801059e1:	e9 11 f3 ff ff       	jmp    80104cf7 <alltraps>

801059e6 <vector219>:
.globl vector219
vector219:
  pushl $0
801059e6:	6a 00                	push   $0x0
  pushl $219
801059e8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801059ed:	e9 05 f3 ff ff       	jmp    80104cf7 <alltraps>

801059f2 <vector220>:
.globl vector220
vector220:
  pushl $0
801059f2:	6a 00                	push   $0x0
  pushl $220
801059f4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801059f9:	e9 f9 f2 ff ff       	jmp    80104cf7 <alltraps>

801059fe <vector221>:
.globl vector221
vector221:
  pushl $0
801059fe:	6a 00                	push   $0x0
  pushl $221
80105a00:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105a05:	e9 ed f2 ff ff       	jmp    80104cf7 <alltraps>

80105a0a <vector222>:
.globl vector222
vector222:
  pushl $0
80105a0a:	6a 00                	push   $0x0
  pushl $222
80105a0c:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105a11:	e9 e1 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a16 <vector223>:
.globl vector223
vector223:
  pushl $0
80105a16:	6a 00                	push   $0x0
  pushl $223
80105a18:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105a1d:	e9 d5 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a22 <vector224>:
.globl vector224
vector224:
  pushl $0
80105a22:	6a 00                	push   $0x0
  pushl $224
80105a24:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105a29:	e9 c9 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a2e <vector225>:
.globl vector225
vector225:
  pushl $0
80105a2e:	6a 00                	push   $0x0
  pushl $225
80105a30:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105a35:	e9 bd f2 ff ff       	jmp    80104cf7 <alltraps>

80105a3a <vector226>:
.globl vector226
vector226:
  pushl $0
80105a3a:	6a 00                	push   $0x0
  pushl $226
80105a3c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105a41:	e9 b1 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a46 <vector227>:
.globl vector227
vector227:
  pushl $0
80105a46:	6a 00                	push   $0x0
  pushl $227
80105a48:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105a4d:	e9 a5 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a52 <vector228>:
.globl vector228
vector228:
  pushl $0
80105a52:	6a 00                	push   $0x0
  pushl $228
80105a54:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105a59:	e9 99 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a5e <vector229>:
.globl vector229
vector229:
  pushl $0
80105a5e:	6a 00                	push   $0x0
  pushl $229
80105a60:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105a65:	e9 8d f2 ff ff       	jmp    80104cf7 <alltraps>

80105a6a <vector230>:
.globl vector230
vector230:
  pushl $0
80105a6a:	6a 00                	push   $0x0
  pushl $230
80105a6c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105a71:	e9 81 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a76 <vector231>:
.globl vector231
vector231:
  pushl $0
80105a76:	6a 00                	push   $0x0
  pushl $231
80105a78:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105a7d:	e9 75 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a82 <vector232>:
.globl vector232
vector232:
  pushl $0
80105a82:	6a 00                	push   $0x0
  pushl $232
80105a84:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105a89:	e9 69 f2 ff ff       	jmp    80104cf7 <alltraps>

80105a8e <vector233>:
.globl vector233
vector233:
  pushl $0
80105a8e:	6a 00                	push   $0x0
  pushl $233
80105a90:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105a95:	e9 5d f2 ff ff       	jmp    80104cf7 <alltraps>

80105a9a <vector234>:
.globl vector234
vector234:
  pushl $0
80105a9a:	6a 00                	push   $0x0
  pushl $234
80105a9c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105aa1:	e9 51 f2 ff ff       	jmp    80104cf7 <alltraps>

80105aa6 <vector235>:
.globl vector235
vector235:
  pushl $0
80105aa6:	6a 00                	push   $0x0
  pushl $235
80105aa8:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105aad:	e9 45 f2 ff ff       	jmp    80104cf7 <alltraps>

80105ab2 <vector236>:
.globl vector236
vector236:
  pushl $0
80105ab2:	6a 00                	push   $0x0
  pushl $236
80105ab4:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105ab9:	e9 39 f2 ff ff       	jmp    80104cf7 <alltraps>

80105abe <vector237>:
.globl vector237
vector237:
  pushl $0
80105abe:	6a 00                	push   $0x0
  pushl $237
80105ac0:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105ac5:	e9 2d f2 ff ff       	jmp    80104cf7 <alltraps>

80105aca <vector238>:
.globl vector238
vector238:
  pushl $0
80105aca:	6a 00                	push   $0x0
  pushl $238
80105acc:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105ad1:	e9 21 f2 ff ff       	jmp    80104cf7 <alltraps>

80105ad6 <vector239>:
.globl vector239
vector239:
  pushl $0
80105ad6:	6a 00                	push   $0x0
  pushl $239
80105ad8:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105add:	e9 15 f2 ff ff       	jmp    80104cf7 <alltraps>

80105ae2 <vector240>:
.globl vector240
vector240:
  pushl $0
80105ae2:	6a 00                	push   $0x0
  pushl $240
80105ae4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105ae9:	e9 09 f2 ff ff       	jmp    80104cf7 <alltraps>

80105aee <vector241>:
.globl vector241
vector241:
  pushl $0
80105aee:	6a 00                	push   $0x0
  pushl $241
80105af0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105af5:	e9 fd f1 ff ff       	jmp    80104cf7 <alltraps>

80105afa <vector242>:
.globl vector242
vector242:
  pushl $0
80105afa:	6a 00                	push   $0x0
  pushl $242
80105afc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105b01:	e9 f1 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b06 <vector243>:
.globl vector243
vector243:
  pushl $0
80105b06:	6a 00                	push   $0x0
  pushl $243
80105b08:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105b0d:	e9 e5 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b12 <vector244>:
.globl vector244
vector244:
  pushl $0
80105b12:	6a 00                	push   $0x0
  pushl $244
80105b14:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105b19:	e9 d9 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b1e <vector245>:
.globl vector245
vector245:
  pushl $0
80105b1e:	6a 00                	push   $0x0
  pushl $245
80105b20:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105b25:	e9 cd f1 ff ff       	jmp    80104cf7 <alltraps>

80105b2a <vector246>:
.globl vector246
vector246:
  pushl $0
80105b2a:	6a 00                	push   $0x0
  pushl $246
80105b2c:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105b31:	e9 c1 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b36 <vector247>:
.globl vector247
vector247:
  pushl $0
80105b36:	6a 00                	push   $0x0
  pushl $247
80105b38:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105b3d:	e9 b5 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b42 <vector248>:
.globl vector248
vector248:
  pushl $0
80105b42:	6a 00                	push   $0x0
  pushl $248
80105b44:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105b49:	e9 a9 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b4e <vector249>:
.globl vector249
vector249:
  pushl $0
80105b4e:	6a 00                	push   $0x0
  pushl $249
80105b50:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105b55:	e9 9d f1 ff ff       	jmp    80104cf7 <alltraps>

80105b5a <vector250>:
.globl vector250
vector250:
  pushl $0
80105b5a:	6a 00                	push   $0x0
  pushl $250
80105b5c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105b61:	e9 91 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b66 <vector251>:
.globl vector251
vector251:
  pushl $0
80105b66:	6a 00                	push   $0x0
  pushl $251
80105b68:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105b6d:	e9 85 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b72 <vector252>:
.globl vector252
vector252:
  pushl $0
80105b72:	6a 00                	push   $0x0
  pushl $252
80105b74:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105b79:	e9 79 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b7e <vector253>:
.globl vector253
vector253:
  pushl $0
80105b7e:	6a 00                	push   $0x0
  pushl $253
80105b80:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105b85:	e9 6d f1 ff ff       	jmp    80104cf7 <alltraps>

80105b8a <vector254>:
.globl vector254
vector254:
  pushl $0
80105b8a:	6a 00                	push   $0x0
  pushl $254
80105b8c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105b91:	e9 61 f1 ff ff       	jmp    80104cf7 <alltraps>

80105b96 <vector255>:
.globl vector255
vector255:
  pushl $0
80105b96:	6a 00                	push   $0x0
  pushl $255
80105b98:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105b9d:	e9 55 f1 ff ff       	jmp    80104cf7 <alltraps>

80105ba2 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105ba2:	55                   	push   %ebp
80105ba3:	89 e5                	mov    %esp,%ebp
80105ba5:	57                   	push   %edi
80105ba6:	56                   	push   %esi
80105ba7:	53                   	push   %ebx
80105ba8:	83 ec 0c             	sub    $0xc,%esp
80105bab:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105bad:	c1 ea 16             	shr    $0x16,%edx
80105bb0:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105bb3:	8b 1f                	mov    (%edi),%ebx
80105bb5:	f6 c3 01             	test   $0x1,%bl
80105bb8:	74 22                	je     80105bdc <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105bba:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105bc0:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105bc6:	c1 ee 0c             	shr    $0xc,%esi
80105bc9:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105bcf:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105bd2:	89 d8                	mov    %ebx,%eax
80105bd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105bd7:	5b                   	pop    %ebx
80105bd8:	5e                   	pop    %esi
80105bd9:	5f                   	pop    %edi
80105bda:	5d                   	pop    %ebp
80105bdb:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105bdc:	85 c9                	test   %ecx,%ecx
80105bde:	74 2b                	je     80105c0b <walkpgdir+0x69>
80105be0:	e8 f5 c4 ff ff       	call   801020da <kalloc>
80105be5:	89 c3                	mov    %eax,%ebx
80105be7:	85 c0                	test   %eax,%eax
80105be9:	74 e7                	je     80105bd2 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105beb:	83 ec 04             	sub    $0x4,%esp
80105bee:	68 00 10 00 00       	push   $0x1000
80105bf3:	6a 00                	push   $0x0
80105bf5:	50                   	push   %eax
80105bf6:	e8 65 e0 ff ff       	call   80103c60 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105bfb:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105c01:	83 c8 07             	or     $0x7,%eax
80105c04:	89 07                	mov    %eax,(%edi)
80105c06:	83 c4 10             	add    $0x10,%esp
80105c09:	eb bb                	jmp    80105bc6 <walkpgdir+0x24>
      return 0;
80105c0b:	bb 00 00 00 00       	mov    $0x0,%ebx
80105c10:	eb c0                	jmp    80105bd2 <walkpgdir+0x30>

80105c12 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105c12:	55                   	push   %ebp
80105c13:	89 e5                	mov    %esp,%ebp
80105c15:	57                   	push   %edi
80105c16:	56                   	push   %esi
80105c17:	53                   	push   %ebx
80105c18:	83 ec 1c             	sub    $0x1c,%esp
80105c1b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105c1e:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105c21:	89 d3                	mov    %edx,%ebx
80105c23:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105c29:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105c2d:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105c33:	b9 01 00 00 00       	mov    $0x1,%ecx
80105c38:	89 da                	mov    %ebx,%edx
80105c3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c3d:	e8 60 ff ff ff       	call   80105ba2 <walkpgdir>
80105c42:	85 c0                	test   %eax,%eax
80105c44:	74 2e                	je     80105c74 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105c46:	f6 00 01             	testb  $0x1,(%eax)
80105c49:	75 1c                	jne    80105c67 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105c4b:	89 f2                	mov    %esi,%edx
80105c4d:	0b 55 0c             	or     0xc(%ebp),%edx
80105c50:	83 ca 01             	or     $0x1,%edx
80105c53:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105c55:	39 fb                	cmp    %edi,%ebx
80105c57:	74 28                	je     80105c81 <mappages+0x6f>
      break;
    a += PGSIZE;
80105c59:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105c5f:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105c65:	eb cc                	jmp    80105c33 <mappages+0x21>
      panic("remap");
80105c67:	83 ec 0c             	sub    $0xc,%esp
80105c6a:	68 0c 6d 10 80       	push   $0x80106d0c
80105c6f:	e8 d4 a6 ff ff       	call   80100348 <panic>
      return -1;
80105c74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105c79:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105c7c:	5b                   	pop    %ebx
80105c7d:	5e                   	pop    %esi
80105c7e:	5f                   	pop    %edi
80105c7f:	5d                   	pop    %ebp
80105c80:	c3                   	ret    
  return 0;
80105c81:	b8 00 00 00 00       	mov    $0x0,%eax
80105c86:	eb f1                	jmp    80105c79 <mappages+0x67>

80105c88 <seginit>:
{
80105c88:	55                   	push   %ebp
80105c89:	89 e5                	mov    %esp,%ebp
80105c8b:	53                   	push   %ebx
80105c8c:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105c8f:	e8 66 d5 ff ff       	call   801031fa <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105c94:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105c9a:	66 c7 80 18 18 11 80 	movw   $0xffff,-0x7feee7e8(%eax)
80105ca1:	ff ff 
80105ca3:	66 c7 80 1a 18 11 80 	movw   $0x0,-0x7feee7e6(%eax)
80105caa:	00 00 
80105cac:	c6 80 1c 18 11 80 00 	movb   $0x0,-0x7feee7e4(%eax)
80105cb3:	0f b6 88 1d 18 11 80 	movzbl -0x7feee7e3(%eax),%ecx
80105cba:	83 e1 f0             	and    $0xfffffff0,%ecx
80105cbd:	83 c9 1a             	or     $0x1a,%ecx
80105cc0:	83 e1 9f             	and    $0xffffff9f,%ecx
80105cc3:	83 c9 80             	or     $0xffffff80,%ecx
80105cc6:	88 88 1d 18 11 80    	mov    %cl,-0x7feee7e3(%eax)
80105ccc:	0f b6 88 1e 18 11 80 	movzbl -0x7feee7e2(%eax),%ecx
80105cd3:	83 c9 0f             	or     $0xf,%ecx
80105cd6:	83 e1 cf             	and    $0xffffffcf,%ecx
80105cd9:	83 c9 c0             	or     $0xffffffc0,%ecx
80105cdc:	88 88 1e 18 11 80    	mov    %cl,-0x7feee7e2(%eax)
80105ce2:	c6 80 1f 18 11 80 00 	movb   $0x0,-0x7feee7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105ce9:	66 c7 80 20 18 11 80 	movw   $0xffff,-0x7feee7e0(%eax)
80105cf0:	ff ff 
80105cf2:	66 c7 80 22 18 11 80 	movw   $0x0,-0x7feee7de(%eax)
80105cf9:	00 00 
80105cfb:	c6 80 24 18 11 80 00 	movb   $0x0,-0x7feee7dc(%eax)
80105d02:	0f b6 88 25 18 11 80 	movzbl -0x7feee7db(%eax),%ecx
80105d09:	83 e1 f0             	and    $0xfffffff0,%ecx
80105d0c:	83 c9 12             	or     $0x12,%ecx
80105d0f:	83 e1 9f             	and    $0xffffff9f,%ecx
80105d12:	83 c9 80             	or     $0xffffff80,%ecx
80105d15:	88 88 25 18 11 80    	mov    %cl,-0x7feee7db(%eax)
80105d1b:	0f b6 88 26 18 11 80 	movzbl -0x7feee7da(%eax),%ecx
80105d22:	83 c9 0f             	or     $0xf,%ecx
80105d25:	83 e1 cf             	and    $0xffffffcf,%ecx
80105d28:	83 c9 c0             	or     $0xffffffc0,%ecx
80105d2b:	88 88 26 18 11 80    	mov    %cl,-0x7feee7da(%eax)
80105d31:	c6 80 27 18 11 80 00 	movb   $0x0,-0x7feee7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105d38:	66 c7 80 28 18 11 80 	movw   $0xffff,-0x7feee7d8(%eax)
80105d3f:	ff ff 
80105d41:	66 c7 80 2a 18 11 80 	movw   $0x0,-0x7feee7d6(%eax)
80105d48:	00 00 
80105d4a:	c6 80 2c 18 11 80 00 	movb   $0x0,-0x7feee7d4(%eax)
80105d51:	c6 80 2d 18 11 80 fa 	movb   $0xfa,-0x7feee7d3(%eax)
80105d58:	0f b6 88 2e 18 11 80 	movzbl -0x7feee7d2(%eax),%ecx
80105d5f:	83 c9 0f             	or     $0xf,%ecx
80105d62:	83 e1 cf             	and    $0xffffffcf,%ecx
80105d65:	83 c9 c0             	or     $0xffffffc0,%ecx
80105d68:	88 88 2e 18 11 80    	mov    %cl,-0x7feee7d2(%eax)
80105d6e:	c6 80 2f 18 11 80 00 	movb   $0x0,-0x7feee7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105d75:	66 c7 80 30 18 11 80 	movw   $0xffff,-0x7feee7d0(%eax)
80105d7c:	ff ff 
80105d7e:	66 c7 80 32 18 11 80 	movw   $0x0,-0x7feee7ce(%eax)
80105d85:	00 00 
80105d87:	c6 80 34 18 11 80 00 	movb   $0x0,-0x7feee7cc(%eax)
80105d8e:	c6 80 35 18 11 80 f2 	movb   $0xf2,-0x7feee7cb(%eax)
80105d95:	0f b6 88 36 18 11 80 	movzbl -0x7feee7ca(%eax),%ecx
80105d9c:	83 c9 0f             	or     $0xf,%ecx
80105d9f:	83 e1 cf             	and    $0xffffffcf,%ecx
80105da2:	83 c9 c0             	or     $0xffffffc0,%ecx
80105da5:	88 88 36 18 11 80    	mov    %cl,-0x7feee7ca(%eax)
80105dab:	c6 80 37 18 11 80 00 	movb   $0x0,-0x7feee7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105db2:	05 10 18 11 80       	add    $0x80111810,%eax
  pd[0] = size-1;
80105db7:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105dbd:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105dc1:	c1 e8 10             	shr    $0x10,%eax
80105dc4:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105dc8:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105dcb:	0f 01 10             	lgdtl  (%eax)
}
80105dce:	83 c4 14             	add    $0x14,%esp
80105dd1:	5b                   	pop    %ebx
80105dd2:	5d                   	pop    %ebp
80105dd3:	c3                   	ret    

80105dd4 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105dd4:	55                   	push   %ebp
80105dd5:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105dd7:	a1 c4 44 11 80       	mov    0x801144c4,%eax
80105ddc:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105de1:	0f 22 d8             	mov    %eax,%cr3
}
80105de4:	5d                   	pop    %ebp
80105de5:	c3                   	ret    

80105de6 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105de6:	55                   	push   %ebp
80105de7:	89 e5                	mov    %esp,%ebp
80105de9:	57                   	push   %edi
80105dea:	56                   	push   %esi
80105deb:	53                   	push   %ebx
80105dec:	83 ec 1c             	sub    $0x1c,%esp
80105def:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105df2:	85 f6                	test   %esi,%esi
80105df4:	0f 84 dd 00 00 00    	je     80105ed7 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105dfa:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105dfe:	0f 84 e0 00 00 00    	je     80105ee4 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105e04:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105e08:	0f 84 e3 00 00 00    	je     80105ef1 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105e0e:	e8 c4 dc ff ff       	call   80103ad7 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105e13:	e8 86 d3 ff ff       	call   8010319e <mycpu>
80105e18:	89 c3                	mov    %eax,%ebx
80105e1a:	e8 7f d3 ff ff       	call   8010319e <mycpu>
80105e1f:	8d 78 08             	lea    0x8(%eax),%edi
80105e22:	e8 77 d3 ff ff       	call   8010319e <mycpu>
80105e27:	83 c0 08             	add    $0x8,%eax
80105e2a:	c1 e8 10             	shr    $0x10,%eax
80105e2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e30:	e8 69 d3 ff ff       	call   8010319e <mycpu>
80105e35:	83 c0 08             	add    $0x8,%eax
80105e38:	c1 e8 18             	shr    $0x18,%eax
80105e3b:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105e42:	67 00 
80105e44:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105e4b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105e4f:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105e55:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105e5c:	83 e2 f0             	and    $0xfffffff0,%edx
80105e5f:	83 ca 19             	or     $0x19,%edx
80105e62:	83 e2 9f             	and    $0xffffff9f,%edx
80105e65:	83 ca 80             	or     $0xffffff80,%edx
80105e68:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105e6e:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105e75:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105e7b:	e8 1e d3 ff ff       	call   8010319e <mycpu>
80105e80:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105e87:	83 e2 ef             	and    $0xffffffef,%edx
80105e8a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105e90:	e8 09 d3 ff ff       	call   8010319e <mycpu>
80105e95:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105e9b:	8b 5e 08             	mov    0x8(%esi),%ebx
80105e9e:	e8 fb d2 ff ff       	call   8010319e <mycpu>
80105ea3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105ea9:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105eac:	e8 ed d2 ff ff       	call   8010319e <mycpu>
80105eb1:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105eb7:	b8 28 00 00 00       	mov    $0x28,%eax
80105ebc:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105ebf:	8b 46 04             	mov    0x4(%esi),%eax
80105ec2:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105ec7:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80105eca:	e8 45 dc ff ff       	call   80103b14 <popcli>
}
80105ecf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ed2:	5b                   	pop    %ebx
80105ed3:	5e                   	pop    %esi
80105ed4:	5f                   	pop    %edi
80105ed5:	5d                   	pop    %ebp
80105ed6:	c3                   	ret    
    panic("switchuvm: no process");
80105ed7:	83 ec 0c             	sub    $0xc,%esp
80105eda:	68 12 6d 10 80       	push   $0x80106d12
80105edf:	e8 64 a4 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80105ee4:	83 ec 0c             	sub    $0xc,%esp
80105ee7:	68 28 6d 10 80       	push   $0x80106d28
80105eec:	e8 57 a4 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80105ef1:	83 ec 0c             	sub    $0xc,%esp
80105ef4:	68 3d 6d 10 80       	push   $0x80106d3d
80105ef9:	e8 4a a4 ff ff       	call   80100348 <panic>

80105efe <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80105efe:	55                   	push   %ebp
80105eff:	89 e5                	mov    %esp,%ebp
80105f01:	56                   	push   %esi
80105f02:	53                   	push   %ebx
80105f03:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80105f06:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80105f0c:	77 4c                	ja     80105f5a <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80105f0e:	e8 c7 c1 ff ff       	call   801020da <kalloc>
80105f13:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80105f15:	83 ec 04             	sub    $0x4,%esp
80105f18:	68 00 10 00 00       	push   $0x1000
80105f1d:	6a 00                	push   $0x0
80105f1f:	50                   	push   %eax
80105f20:	e8 3b dd ff ff       	call   80103c60 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80105f25:	83 c4 08             	add    $0x8,%esp
80105f28:	6a 06                	push   $0x6
80105f2a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105f30:	50                   	push   %eax
80105f31:	b9 00 10 00 00       	mov    $0x1000,%ecx
80105f36:	ba 00 00 00 00       	mov    $0x0,%edx
80105f3b:	8b 45 08             	mov    0x8(%ebp),%eax
80105f3e:	e8 cf fc ff ff       	call   80105c12 <mappages>
  memmove(mem, init, sz);
80105f43:	83 c4 0c             	add    $0xc,%esp
80105f46:	56                   	push   %esi
80105f47:	ff 75 0c             	pushl  0xc(%ebp)
80105f4a:	53                   	push   %ebx
80105f4b:	e8 8b dd ff ff       	call   80103cdb <memmove>
}
80105f50:	83 c4 10             	add    $0x10,%esp
80105f53:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105f56:	5b                   	pop    %ebx
80105f57:	5e                   	pop    %esi
80105f58:	5d                   	pop    %ebp
80105f59:	c3                   	ret    
    panic("inituvm: more than a page");
80105f5a:	83 ec 0c             	sub    $0xc,%esp
80105f5d:	68 51 6d 10 80       	push   $0x80106d51
80105f62:	e8 e1 a3 ff ff       	call   80100348 <panic>

80105f67 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80105f67:	55                   	push   %ebp
80105f68:	89 e5                	mov    %esp,%ebp
80105f6a:	57                   	push   %edi
80105f6b:	56                   	push   %esi
80105f6c:	53                   	push   %ebx
80105f6d:	83 ec 0c             	sub    $0xc,%esp
80105f70:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80105f73:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80105f7a:	75 07                	jne    80105f83 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80105f7c:	bb 00 00 00 00       	mov    $0x0,%ebx
80105f81:	eb 3c                	jmp    80105fbf <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80105f83:	83 ec 0c             	sub    $0xc,%esp
80105f86:	68 0c 6e 10 80       	push   $0x80106e0c
80105f8b:	e8 b8 a3 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80105f90:	83 ec 0c             	sub    $0xc,%esp
80105f93:	68 6b 6d 10 80       	push   $0x80106d6b
80105f98:	e8 ab a3 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80105f9d:	05 00 00 00 80       	add    $0x80000000,%eax
80105fa2:	56                   	push   %esi
80105fa3:	89 da                	mov    %ebx,%edx
80105fa5:	03 55 14             	add    0x14(%ebp),%edx
80105fa8:	52                   	push   %edx
80105fa9:	50                   	push   %eax
80105faa:	ff 75 10             	pushl  0x10(%ebp)
80105fad:	e8 c1 b7 ff ff       	call   80101773 <readi>
80105fb2:	83 c4 10             	add    $0x10,%esp
80105fb5:	39 f0                	cmp    %esi,%eax
80105fb7:	75 47                	jne    80106000 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80105fb9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105fbf:	39 fb                	cmp    %edi,%ebx
80105fc1:	73 30                	jae    80105ff3 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80105fc3:	89 da                	mov    %ebx,%edx
80105fc5:	03 55 0c             	add    0xc(%ebp),%edx
80105fc8:	b9 00 00 00 00       	mov    $0x0,%ecx
80105fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80105fd0:	e8 cd fb ff ff       	call   80105ba2 <walkpgdir>
80105fd5:	85 c0                	test   %eax,%eax
80105fd7:	74 b7                	je     80105f90 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80105fd9:	8b 00                	mov    (%eax),%eax
80105fdb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80105fe0:	89 fe                	mov    %edi,%esi
80105fe2:	29 de                	sub    %ebx,%esi
80105fe4:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80105fea:	76 b1                	jbe    80105f9d <loaduvm+0x36>
      n = PGSIZE;
80105fec:	be 00 10 00 00       	mov    $0x1000,%esi
80105ff1:	eb aa                	jmp    80105f9d <loaduvm+0x36>
      return -1;
  }
  return 0;
80105ff3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ff8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ffb:	5b                   	pop    %ebx
80105ffc:	5e                   	pop    %esi
80105ffd:	5f                   	pop    %edi
80105ffe:	5d                   	pop    %ebp
80105fff:	c3                   	ret    
      return -1;
80106000:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106005:	eb f1                	jmp    80105ff8 <loaduvm+0x91>

80106007 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106007:	55                   	push   %ebp
80106008:	89 e5                	mov    %esp,%ebp
8010600a:	57                   	push   %edi
8010600b:	56                   	push   %esi
8010600c:	53                   	push   %ebx
8010600d:	83 ec 0c             	sub    $0xc,%esp
80106010:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106013:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106016:	73 11                	jae    80106029 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106018:	8b 45 10             	mov    0x10(%ebp),%eax
8010601b:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106021:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106027:	eb 19                	jmp    80106042 <deallocuvm+0x3b>
    return oldsz;
80106029:	89 f8                	mov    %edi,%eax
8010602b:	eb 64                	jmp    80106091 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
8010602d:	c1 eb 16             	shr    $0x16,%ebx
80106030:	83 c3 01             	add    $0x1,%ebx
80106033:	c1 e3 16             	shl    $0x16,%ebx
80106036:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010603c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106042:	39 fb                	cmp    %edi,%ebx
80106044:	73 48                	jae    8010608e <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106046:	b9 00 00 00 00       	mov    $0x0,%ecx
8010604b:	89 da                	mov    %ebx,%edx
8010604d:	8b 45 08             	mov    0x8(%ebp),%eax
80106050:	e8 4d fb ff ff       	call   80105ba2 <walkpgdir>
80106055:	89 c6                	mov    %eax,%esi
    if(!pte)
80106057:	85 c0                	test   %eax,%eax
80106059:	74 d2                	je     8010602d <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010605b:	8b 00                	mov    (%eax),%eax
8010605d:	a8 01                	test   $0x1,%al
8010605f:	74 db                	je     8010603c <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106061:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106066:	74 19                	je     80106081 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106068:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010606d:	83 ec 0c             	sub    $0xc,%esp
80106070:	50                   	push   %eax
80106071:	e8 2e bf ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106076:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010607c:	83 c4 10             	add    $0x10,%esp
8010607f:	eb bb                	jmp    8010603c <deallocuvm+0x35>
        panic("kfree");
80106081:	83 ec 0c             	sub    $0xc,%esp
80106084:	68 a6 66 10 80       	push   $0x801066a6
80106089:	e8 ba a2 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010608e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106091:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106094:	5b                   	pop    %ebx
80106095:	5e                   	pop    %esi
80106096:	5f                   	pop    %edi
80106097:	5d                   	pop    %ebp
80106098:	c3                   	ret    

80106099 <allocuvm>:
{
80106099:	55                   	push   %ebp
8010609a:	89 e5                	mov    %esp,%ebp
8010609c:	57                   	push   %edi
8010609d:	56                   	push   %esi
8010609e:	53                   	push   %ebx
8010609f:	83 ec 1c             	sub    $0x1c,%esp
801060a2:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801060a5:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801060a8:	85 ff                	test   %edi,%edi
801060aa:	0f 88 c1 00 00 00    	js     80106171 <allocuvm+0xd8>
  if(newsz < oldsz)
801060b0:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801060b3:	72 5c                	jb     80106111 <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801060b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801060b8:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801060be:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801060c4:	39 fb                	cmp    %edi,%ebx
801060c6:	0f 83 ac 00 00 00    	jae    80106178 <allocuvm+0xdf>
    mem = kalloc();
801060cc:	e8 09 c0 ff ff       	call   801020da <kalloc>
801060d1:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801060d3:	85 c0                	test   %eax,%eax
801060d5:	74 42                	je     80106119 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801060d7:	83 ec 04             	sub    $0x4,%esp
801060da:	68 00 10 00 00       	push   $0x1000
801060df:	6a 00                	push   $0x0
801060e1:	50                   	push   %eax
801060e2:	e8 79 db ff ff       	call   80103c60 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801060e7:	83 c4 08             	add    $0x8,%esp
801060ea:	6a 06                	push   $0x6
801060ec:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801060f2:	50                   	push   %eax
801060f3:	b9 00 10 00 00       	mov    $0x1000,%ecx
801060f8:	89 da                	mov    %ebx,%edx
801060fa:	8b 45 08             	mov    0x8(%ebp),%eax
801060fd:	e8 10 fb ff ff       	call   80105c12 <mappages>
80106102:	83 c4 10             	add    $0x10,%esp
80106105:	85 c0                	test   %eax,%eax
80106107:	78 38                	js     80106141 <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106109:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010610f:	eb b3                	jmp    801060c4 <allocuvm+0x2b>
    return oldsz;
80106111:	8b 45 0c             	mov    0xc(%ebp),%eax
80106114:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106117:	eb 5f                	jmp    80106178 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106119:	83 ec 0c             	sub    $0xc,%esp
8010611c:	68 89 6d 10 80       	push   $0x80106d89
80106121:	e8 e5 a4 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106126:	83 c4 0c             	add    $0xc,%esp
80106129:	ff 75 0c             	pushl  0xc(%ebp)
8010612c:	57                   	push   %edi
8010612d:	ff 75 08             	pushl  0x8(%ebp)
80106130:	e8 d2 fe ff ff       	call   80106007 <deallocuvm>
      return 0;
80106135:	83 c4 10             	add    $0x10,%esp
80106138:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010613f:	eb 37                	jmp    80106178 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
80106141:	83 ec 0c             	sub    $0xc,%esp
80106144:	68 a1 6d 10 80       	push   $0x80106da1
80106149:	e8 bd a4 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010614e:	83 c4 0c             	add    $0xc,%esp
80106151:	ff 75 0c             	pushl  0xc(%ebp)
80106154:	57                   	push   %edi
80106155:	ff 75 08             	pushl  0x8(%ebp)
80106158:	e8 aa fe ff ff       	call   80106007 <deallocuvm>
      kfree(mem);
8010615d:	89 34 24             	mov    %esi,(%esp)
80106160:	e8 3f be ff ff       	call   80101fa4 <kfree>
      return 0;
80106165:	83 c4 10             	add    $0x10,%esp
80106168:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010616f:	eb 07                	jmp    80106178 <allocuvm+0xdf>
    return 0;
80106171:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106178:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010617b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010617e:	5b                   	pop    %ebx
8010617f:	5e                   	pop    %esi
80106180:	5f                   	pop    %edi
80106181:	5d                   	pop    %ebp
80106182:	c3                   	ret    

80106183 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106183:	55                   	push   %ebp
80106184:	89 e5                	mov    %esp,%ebp
80106186:	56                   	push   %esi
80106187:	53                   	push   %ebx
80106188:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010618b:	85 f6                	test   %esi,%esi
8010618d:	74 1a                	je     801061a9 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010618f:	83 ec 04             	sub    $0x4,%esp
80106192:	6a 00                	push   $0x0
80106194:	68 00 00 00 80       	push   $0x80000000
80106199:	56                   	push   %esi
8010619a:	e8 68 fe ff ff       	call   80106007 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010619f:	83 c4 10             	add    $0x10,%esp
801061a2:	bb 00 00 00 00       	mov    $0x0,%ebx
801061a7:	eb 10                	jmp    801061b9 <freevm+0x36>
    panic("freevm: no pgdir");
801061a9:	83 ec 0c             	sub    $0xc,%esp
801061ac:	68 bd 6d 10 80       	push   $0x80106dbd
801061b1:	e8 92 a1 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801061b6:	83 c3 01             	add    $0x1,%ebx
801061b9:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801061bf:	77 1f                	ja     801061e0 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801061c1:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801061c4:	a8 01                	test   $0x1,%al
801061c6:	74 ee                	je     801061b6 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801061c8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801061cd:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801061d2:	83 ec 0c             	sub    $0xc,%esp
801061d5:	50                   	push   %eax
801061d6:	e8 c9 bd ff ff       	call   80101fa4 <kfree>
801061db:	83 c4 10             	add    $0x10,%esp
801061de:	eb d6                	jmp    801061b6 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801061e0:	83 ec 0c             	sub    $0xc,%esp
801061e3:	56                   	push   %esi
801061e4:	e8 bb bd ff ff       	call   80101fa4 <kfree>
}
801061e9:	83 c4 10             	add    $0x10,%esp
801061ec:	8d 65 f8             	lea    -0x8(%ebp),%esp
801061ef:	5b                   	pop    %ebx
801061f0:	5e                   	pop    %esi
801061f1:	5d                   	pop    %ebp
801061f2:	c3                   	ret    

801061f3 <setupkvm>:
{
801061f3:	55                   	push   %ebp
801061f4:	89 e5                	mov    %esp,%ebp
801061f6:	56                   	push   %esi
801061f7:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801061f8:	e8 dd be ff ff       	call   801020da <kalloc>
801061fd:	89 c6                	mov    %eax,%esi
801061ff:	85 c0                	test   %eax,%eax
80106201:	74 55                	je     80106258 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106203:	83 ec 04             	sub    $0x4,%esp
80106206:	68 00 10 00 00       	push   $0x1000
8010620b:	6a 00                	push   $0x0
8010620d:	50                   	push   %eax
8010620e:	e8 4d da ff ff       	call   80103c60 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106213:	83 c4 10             	add    $0x10,%esp
80106216:	bb 20 94 10 80       	mov    $0x80109420,%ebx
8010621b:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
80106221:	73 35                	jae    80106258 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106223:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106226:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106229:	29 c1                	sub    %eax,%ecx
8010622b:	83 ec 08             	sub    $0x8,%esp
8010622e:	ff 73 0c             	pushl  0xc(%ebx)
80106231:	50                   	push   %eax
80106232:	8b 13                	mov    (%ebx),%edx
80106234:	89 f0                	mov    %esi,%eax
80106236:	e8 d7 f9 ff ff       	call   80105c12 <mappages>
8010623b:	83 c4 10             	add    $0x10,%esp
8010623e:	85 c0                	test   %eax,%eax
80106240:	78 05                	js     80106247 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106242:	83 c3 10             	add    $0x10,%ebx
80106245:	eb d4                	jmp    8010621b <setupkvm+0x28>
      freevm(pgdir);
80106247:	83 ec 0c             	sub    $0xc,%esp
8010624a:	56                   	push   %esi
8010624b:	e8 33 ff ff ff       	call   80106183 <freevm>
      return 0;
80106250:	83 c4 10             	add    $0x10,%esp
80106253:	be 00 00 00 00       	mov    $0x0,%esi
}
80106258:	89 f0                	mov    %esi,%eax
8010625a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010625d:	5b                   	pop    %ebx
8010625e:	5e                   	pop    %esi
8010625f:	5d                   	pop    %ebp
80106260:	c3                   	ret    

80106261 <kvmalloc>:
{
80106261:	55                   	push   %ebp
80106262:	89 e5                	mov    %esp,%ebp
80106264:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106267:	e8 87 ff ff ff       	call   801061f3 <setupkvm>
8010626c:	a3 c4 44 11 80       	mov    %eax,0x801144c4
  switchkvm();
80106271:	e8 5e fb ff ff       	call   80105dd4 <switchkvm>
}
80106276:	c9                   	leave  
80106277:	c3                   	ret    

80106278 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106278:	55                   	push   %ebp
80106279:	89 e5                	mov    %esp,%ebp
8010627b:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010627e:	b9 00 00 00 00       	mov    $0x0,%ecx
80106283:	8b 55 0c             	mov    0xc(%ebp),%edx
80106286:	8b 45 08             	mov    0x8(%ebp),%eax
80106289:	e8 14 f9 ff ff       	call   80105ba2 <walkpgdir>
  if(pte == 0)
8010628e:	85 c0                	test   %eax,%eax
80106290:	74 05                	je     80106297 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106292:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106295:	c9                   	leave  
80106296:	c3                   	ret    
    panic("clearpteu");
80106297:	83 ec 0c             	sub    $0xc,%esp
8010629a:	68 ce 6d 10 80       	push   $0x80106dce
8010629f:	e8 a4 a0 ff ff       	call   80100348 <panic>

801062a4 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801062a4:	55                   	push   %ebp
801062a5:	89 e5                	mov    %esp,%ebp
801062a7:	57                   	push   %edi
801062a8:	56                   	push   %esi
801062a9:	53                   	push   %ebx
801062aa:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801062ad:	e8 41 ff ff ff       	call   801061f3 <setupkvm>
801062b2:	89 45 dc             	mov    %eax,-0x24(%ebp)
801062b5:	85 c0                	test   %eax,%eax
801062b7:	0f 84 c4 00 00 00    	je     80106381 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801062bd:	bf 00 00 00 00       	mov    $0x0,%edi
801062c2:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801062c5:	0f 83 b6 00 00 00    	jae    80106381 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801062cb:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801062ce:	b9 00 00 00 00       	mov    $0x0,%ecx
801062d3:	89 fa                	mov    %edi,%edx
801062d5:	8b 45 08             	mov    0x8(%ebp),%eax
801062d8:	e8 c5 f8 ff ff       	call   80105ba2 <walkpgdir>
801062dd:	85 c0                	test   %eax,%eax
801062df:	74 65                	je     80106346 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801062e1:	8b 00                	mov    (%eax),%eax
801062e3:	a8 01                	test   $0x1,%al
801062e5:	74 6c                	je     80106353 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801062e7:	89 c6                	mov    %eax,%esi
801062e9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801062ef:	25 ff 0f 00 00       	and    $0xfff,%eax
801062f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801062f7:	e8 de bd ff ff       	call   801020da <kalloc>
801062fc:	89 c3                	mov    %eax,%ebx
801062fe:	85 c0                	test   %eax,%eax
80106300:	74 6a                	je     8010636c <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106302:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106308:	83 ec 04             	sub    $0x4,%esp
8010630b:	68 00 10 00 00       	push   $0x1000
80106310:	56                   	push   %esi
80106311:	50                   	push   %eax
80106312:	e8 c4 d9 ff ff       	call   80103cdb <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106317:	83 c4 08             	add    $0x8,%esp
8010631a:	ff 75 e0             	pushl  -0x20(%ebp)
8010631d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106323:	50                   	push   %eax
80106324:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106329:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010632c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010632f:	e8 de f8 ff ff       	call   80105c12 <mappages>
80106334:	83 c4 10             	add    $0x10,%esp
80106337:	85 c0                	test   %eax,%eax
80106339:	78 25                	js     80106360 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
8010633b:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106341:	e9 7c ff ff ff       	jmp    801062c2 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106346:	83 ec 0c             	sub    $0xc,%esp
80106349:	68 d8 6d 10 80       	push   $0x80106dd8
8010634e:	e8 f5 9f ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106353:	83 ec 0c             	sub    $0xc,%esp
80106356:	68 f2 6d 10 80       	push   $0x80106df2
8010635b:	e8 e8 9f ff ff       	call   80100348 <panic>
      kfree(mem);
80106360:	83 ec 0c             	sub    $0xc,%esp
80106363:	53                   	push   %ebx
80106364:	e8 3b bc ff ff       	call   80101fa4 <kfree>
      goto bad;
80106369:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010636c:	83 ec 0c             	sub    $0xc,%esp
8010636f:	ff 75 dc             	pushl  -0x24(%ebp)
80106372:	e8 0c fe ff ff       	call   80106183 <freevm>
  return 0;
80106377:	83 c4 10             	add    $0x10,%esp
8010637a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106381:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106384:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106387:	5b                   	pop    %ebx
80106388:	5e                   	pop    %esi
80106389:	5f                   	pop    %edi
8010638a:	5d                   	pop    %ebp
8010638b:	c3                   	ret    

8010638c <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010638c:	55                   	push   %ebp
8010638d:	89 e5                	mov    %esp,%ebp
8010638f:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106392:	b9 00 00 00 00       	mov    $0x0,%ecx
80106397:	8b 55 0c             	mov    0xc(%ebp),%edx
8010639a:	8b 45 08             	mov    0x8(%ebp),%eax
8010639d:	e8 00 f8 ff ff       	call   80105ba2 <walkpgdir>
  if((*pte & PTE_P) == 0)
801063a2:	8b 00                	mov    (%eax),%eax
801063a4:	a8 01                	test   $0x1,%al
801063a6:	74 10                	je     801063b8 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801063a8:	a8 04                	test   $0x4,%al
801063aa:	74 13                	je     801063bf <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801063ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063b1:	05 00 00 00 80       	add    $0x80000000,%eax
}
801063b6:	c9                   	leave  
801063b7:	c3                   	ret    
    return 0;
801063b8:	b8 00 00 00 00       	mov    $0x0,%eax
801063bd:	eb f7                	jmp    801063b6 <uva2ka+0x2a>
    return 0;
801063bf:	b8 00 00 00 00       	mov    $0x0,%eax
801063c4:	eb f0                	jmp    801063b6 <uva2ka+0x2a>

801063c6 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801063c6:	55                   	push   %ebp
801063c7:	89 e5                	mov    %esp,%ebp
801063c9:	57                   	push   %edi
801063ca:	56                   	push   %esi
801063cb:	53                   	push   %ebx
801063cc:	83 ec 0c             	sub    $0xc,%esp
801063cf:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801063d2:	eb 25                	jmp    801063f9 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801063d4:	8b 55 0c             	mov    0xc(%ebp),%edx
801063d7:	29 f2                	sub    %esi,%edx
801063d9:	01 d0                	add    %edx,%eax
801063db:	83 ec 04             	sub    $0x4,%esp
801063de:	53                   	push   %ebx
801063df:	ff 75 10             	pushl  0x10(%ebp)
801063e2:	50                   	push   %eax
801063e3:	e8 f3 d8 ff ff       	call   80103cdb <memmove>
    len -= n;
801063e8:	29 df                	sub    %ebx,%edi
    buf += n;
801063ea:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801063ed:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801063f3:	89 45 0c             	mov    %eax,0xc(%ebp)
801063f6:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801063f9:	85 ff                	test   %edi,%edi
801063fb:	74 2f                	je     8010642c <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801063fd:	8b 75 0c             	mov    0xc(%ebp),%esi
80106400:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106406:	83 ec 08             	sub    $0x8,%esp
80106409:	56                   	push   %esi
8010640a:	ff 75 08             	pushl  0x8(%ebp)
8010640d:	e8 7a ff ff ff       	call   8010638c <uva2ka>
    if(pa0 == 0)
80106412:	83 c4 10             	add    $0x10,%esp
80106415:	85 c0                	test   %eax,%eax
80106417:	74 20                	je     80106439 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106419:	89 f3                	mov    %esi,%ebx
8010641b:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010641e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106424:	39 df                	cmp    %ebx,%edi
80106426:	73 ac                	jae    801063d4 <copyout+0xe>
      n = len;
80106428:	89 fb                	mov    %edi,%ebx
8010642a:	eb a8                	jmp    801063d4 <copyout+0xe>
  }
  return 0;
8010642c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106431:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106434:	5b                   	pop    %ebx
80106435:	5e                   	pop    %esi
80106436:	5f                   	pop    %edi
80106437:	5d                   	pop    %ebp
80106438:	c3                   	ret    
      return -1;
80106439:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010643e:	eb f1                	jmp    80106431 <copyout+0x6b>
