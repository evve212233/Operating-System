
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

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
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
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
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 1b 38 10 80       	mov    $0x8010381b,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 bc 85 10 	movl   $0x801085bc,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 e8 4e 00 00       	call   80104f36 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 95 4e 00 00       	call   80104f57 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->blockno == blockno){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 b0 4e 00 00       	call   80104fb9 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 55 4b 00 00       	call   80104c79 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 38 4e 00 00       	call   80104fb9 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 c3 85 10 80 	movl   $0x801085c3,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID)) {
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 a3 26 00 00       	call   8010287b <iderw>
  }
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 d4 85 10 80 	movl   $0x801085d4,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 66 26 00 00       	call   8010287b <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 db 85 10 80 	movl   $0x801085db,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 16 4d 00 00       	call   80104f57 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 b0 4a 00 00       	call   80104d52 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 0b 4d 00 00       	call   80104fb9 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 d6 03 00 00       	call   8010076b <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 96 4b 00 00       	call   80104f57 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 e2 85 10 80 	movl   $0x801085e2,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 74 03 00 00       	call   8010076b <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec eb 85 10 80 	movl   $0x801085eb,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 a2 02 00 00       	call   8010076b <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 83 02 00 00       	call   8010076b <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 75 02 00 00       	call   8010076b <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 6a 02 00 00       	call   8010076b <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 7e 4a 00 00       	call   80104fb9 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 f2 85 10 80 	movl   $0x801085f2,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 01 86 10 80 	movl   $0x80108601,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 71 4a 00 00       	call   80105008 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 03 86 10 80 	movl   $0x80108603,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  if(pos < 0 || pos > 25*80)
8010068a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010068e:	78 09                	js     80100699 <cgaputc+0xcc>
80100690:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
80100697:	7e 0c                	jle    801006a5 <cgaputc+0xd8>
    panic("pos under/overflow");
80100699:	c7 04 24 07 86 10 80 	movl   $0x80108607,(%esp)
801006a0:	e8 98 fe ff ff       	call   8010053d <panic>
  
  if((pos/80) >= 24){  // Scroll up.
801006a5:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801006ac:	7e 53                	jle    80100701 <cgaputc+0x134>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801006ae:	a1 00 90 10 80       	mov    0x80109000,%eax
801006b3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006b9:	a1 00 90 10 80       	mov    0x80109000,%eax
801006be:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006c5:	00 
801006c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801006ca:	89 04 24             	mov    %eax,(%esp)
801006cd:	e8 a7 4b 00 00       	call   80105279 <memmove>
    pos -= 80;
801006d2:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006d6:	b8 80 07 00 00       	mov    $0x780,%eax
801006db:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006de:	01 c0                	add    %eax,%eax
801006e0:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006e6:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006e9:	01 c9                	add    %ecx,%ecx
801006eb:	01 ca                	add    %ecx,%edx
801006ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801006f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006f8:	00 
801006f9:	89 14 24             	mov    %edx,(%esp)
801006fc:	e8 a5 4a 00 00       	call   801051a6 <memset>
  }
  
  outb(CRTPORT, 14);
80100701:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
80100708:	00 
80100709:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100710:	e8 c5 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
80100715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100718:	c1 f8 08             	sar    $0x8,%eax
8010071b:	0f b6 c0             	movzbl %al,%eax
8010071e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100722:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100729:	e8 ac fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
8010072e:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100735:	00 
80100736:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010073d:	e8 98 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100742:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100745:	0f b6 c0             	movzbl %al,%eax
80100748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010074c:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100753:	e8 82 fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
80100758:	a1 00 90 10 80       	mov    0x80109000,%eax
8010075d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100760:	01 d2                	add    %edx,%edx
80100762:	01 d0                	add    %edx,%eax
80100764:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
80100769:	c9                   	leave  
8010076a:	c3                   	ret    

8010076b <consputc>:

void
consputc(int c)
{
8010076b:	55                   	push   %ebp
8010076c:	89 e5                	mov    %esp,%ebp
8010076e:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100771:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
80100776:	85 c0                	test   %eax,%eax
80100778:	74 07                	je     80100781 <consputc+0x16>
    cli();
8010077a:	e8 79 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
8010077f:	eb fe                	jmp    8010077f <consputc+0x14>
  }

  if(c == BACKSPACE){
80100781:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100788:	75 26                	jne    801007b0 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010078a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100791:	e8 7f 64 00 00       	call   80106c15 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 73 64 00 00       	call   80106c15 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 67 64 00 00       	call   80106c15 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 5a 64 00 00       	call   80106c15 <uartputc>
  cgaputc(c);
801007bb:	8b 45 08             	mov    0x8(%ebp),%eax
801007be:	89 04 24             	mov    %eax,(%esp)
801007c1:	e8 07 fe ff ff       	call   801005cd <cgaputc>
}
801007c6:	c9                   	leave  
801007c7:	c3                   	ret    

801007c8 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007c8:	55                   	push   %ebp
801007c9:	89 e5                	mov    %esp,%ebp
801007cb:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
801007ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
801007d5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801007dc:	e8 76 47 00 00       	call   80104f57 <acquire>
  while((c = getc()) >= 0){
801007e1:	e9 43 01 00 00       	jmp    80100929 <consoleintr+0x161>
    switch(c){
801007e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801007e9:	83 f8 10             	cmp    $0x10,%eax
801007ec:	74 1e                	je     8010080c <consoleintr+0x44>
801007ee:	83 f8 10             	cmp    $0x10,%eax
801007f1:	7f 0a                	jg     801007fd <consoleintr+0x35>
801007f3:	83 f8 08             	cmp    $0x8,%eax
801007f6:	74 6a                	je     80100862 <consoleintr+0x9a>
801007f8:	e9 96 00 00 00       	jmp    80100893 <consoleintr+0xcb>
801007fd:	83 f8 15             	cmp    $0x15,%eax
80100800:	74 31                	je     80100833 <consoleintr+0x6b>
80100802:	83 f8 7f             	cmp    $0x7f,%eax
80100805:	74 5b                	je     80100862 <consoleintr+0x9a>
80100807:	e9 87 00 00 00       	jmp    80100893 <consoleintr+0xcb>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
8010080c:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100813:	e9 11 01 00 00       	jmp    80100929 <consoleintr+0x161>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100818:	a1 08 08 11 80       	mov    0x80110808,%eax
8010081d:	83 e8 01             	sub    $0x1,%eax
80100820:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(BACKSPACE);
80100825:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010082c:	e8 3a ff ff ff       	call   8010076b <consputc>
80100831:	eb 01                	jmp    80100834 <consoleintr+0x6c>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100833:	90                   	nop
80100834:	8b 15 08 08 11 80    	mov    0x80110808,%edx
8010083a:	a1 04 08 11 80       	mov    0x80110804,%eax
8010083f:	39 c2                	cmp    %eax,%edx
80100841:	0f 84 db 00 00 00    	je     80100922 <consoleintr+0x15a>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100847:	a1 08 08 11 80       	mov    0x80110808,%eax
8010084c:	83 e8 01             	sub    $0x1,%eax
8010084f:	83 e0 7f             	and    $0x7f,%eax
80100852:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100859:	3c 0a                	cmp    $0xa,%al
8010085b:	75 bb                	jne    80100818 <consoleintr+0x50>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
8010085d:	e9 c0 00 00 00       	jmp    80100922 <consoleintr+0x15a>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
80100862:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100868:	a1 04 08 11 80       	mov    0x80110804,%eax
8010086d:	39 c2                	cmp    %eax,%edx
8010086f:	0f 84 b0 00 00 00    	je     80100925 <consoleintr+0x15d>
        input.e--;
80100875:	a1 08 08 11 80       	mov    0x80110808,%eax
8010087a:	83 e8 01             	sub    $0x1,%eax
8010087d:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(BACKSPACE);
80100882:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100889:	e8 dd fe ff ff       	call   8010076b <consputc>
      }
      break;
8010088e:	e9 92 00 00 00       	jmp    80100925 <consoleintr+0x15d>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100893:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100897:	0f 84 8b 00 00 00    	je     80100928 <consoleintr+0x160>
8010089d:	8b 15 08 08 11 80    	mov    0x80110808,%edx
801008a3:	a1 00 08 11 80       	mov    0x80110800,%eax
801008a8:	89 d1                	mov    %edx,%ecx
801008aa:	29 c1                	sub    %eax,%ecx
801008ac:	89 c8                	mov    %ecx,%eax
801008ae:	83 f8 7f             	cmp    $0x7f,%eax
801008b1:	77 75                	ja     80100928 <consoleintr+0x160>
        c = (c == '\r') ? '\n' : c;
801008b3:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801008b7:	74 05                	je     801008be <consoleintr+0xf6>
801008b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008bc:	eb 05                	jmp    801008c3 <consoleintr+0xfb>
801008be:	b8 0a 00 00 00       	mov    $0xa,%eax
801008c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008c6:	a1 08 08 11 80       	mov    0x80110808,%eax
801008cb:	89 c1                	mov    %eax,%ecx
801008cd:	83 e1 7f             	and    $0x7f,%ecx
801008d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801008d3:	88 91 80 07 11 80    	mov    %dl,-0x7feef880(%ecx)
801008d9:	83 c0 01             	add    $0x1,%eax
801008dc:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(c);
801008e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008e4:	89 04 24             	mov    %eax,(%esp)
801008e7:	e8 7f fe ff ff       	call   8010076b <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008ec:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801008f0:	74 18                	je     8010090a <consoleintr+0x142>
801008f2:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801008f6:	74 12                	je     8010090a <consoleintr+0x142>
801008f8:	a1 08 08 11 80       	mov    0x80110808,%eax
801008fd:	8b 15 00 08 11 80    	mov    0x80110800,%edx
80100903:	83 ea 80             	sub    $0xffffff80,%edx
80100906:	39 d0                	cmp    %edx,%eax
80100908:	75 1e                	jne    80100928 <consoleintr+0x160>
          input.w = input.e;
8010090a:	a1 08 08 11 80       	mov    0x80110808,%eax
8010090f:	a3 04 08 11 80       	mov    %eax,0x80110804
          wakeup(&input.r);
80100914:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
8010091b:	e8 32 44 00 00       	call   80104d52 <wakeup>
        }
      }
      break;
80100920:	eb 06                	jmp    80100928 <consoleintr+0x160>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100922:	90                   	nop
80100923:	eb 04                	jmp    80100929 <consoleintr+0x161>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100925:	90                   	nop
80100926:	eb 01                	jmp    80100929 <consoleintr+0x161>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100928:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100929:	8b 45 08             	mov    0x8(%ebp),%eax
8010092c:	ff d0                	call   *%eax
8010092e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100931:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100935:	0f 89 ab fe ff ff    	jns    801007e6 <consoleintr+0x1e>
        }
      }
      break;
    }
  }
  release(&cons.lock);
8010093b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100942:	e8 72 46 00 00       	call   80104fb9 <release>
  if(doprocdump) {
80100947:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010094b:	74 05                	je     80100952 <consoleintr+0x18a>
    procdump();  // now call procdump() wo. cons.lock held
8010094d:	e8 a3 44 00 00       	call   80104df5 <procdump>
  }
}
80100952:	c9                   	leave  
80100953:	c3                   	ret    

80100954 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100954:	55                   	push   %ebp
80100955:	89 e5                	mov    %esp,%ebp
80100957:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010095a:	8b 45 08             	mov    0x8(%ebp),%eax
8010095d:	89 04 24             	mov    %eax,(%esp)
80100960:	e8 e0 10 00 00       	call   80101a45 <iunlock>
  target = n;
80100965:	8b 45 10             	mov    0x10(%ebp),%eax
80100968:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
8010096b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100972:	e8 e0 45 00 00       	call   80104f57 <acquire>
  while(n > 0){
80100977:	e9 a8 00 00 00       	jmp    80100a24 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010097c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100982:	8b 40 24             	mov    0x24(%eax),%eax
80100985:	85 c0                	test   %eax,%eax
80100987:	74 21                	je     801009aa <consoleread+0x56>
        release(&cons.lock);
80100989:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100990:	e8 24 46 00 00       	call   80104fb9 <release>
        ilock(ip);
80100995:	8b 45 08             	mov    0x8(%ebp),%eax
80100998:	89 04 24             	mov    %eax,(%esp)
8010099b:	e8 51 0f 00 00       	call   801018f1 <ilock>
        return -1;
801009a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801009a5:	e9 a9 00 00 00       	jmp    80100a53 <consoleread+0xff>
      }
      sleep(&input.r, &cons.lock);
801009aa:	c7 44 24 04 c0 b5 10 	movl   $0x8010b5c0,0x4(%esp)
801009b1:	80 
801009b2:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
801009b9:	e8 bb 42 00 00       	call   80104c79 <sleep>
801009be:	eb 01                	jmp    801009c1 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
801009c0:	90                   	nop
801009c1:	8b 15 00 08 11 80    	mov    0x80110800,%edx
801009c7:	a1 04 08 11 80       	mov    0x80110804,%eax
801009cc:	39 c2                	cmp    %eax,%edx
801009ce:	74 ac                	je     8010097c <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009d0:	a1 00 08 11 80       	mov    0x80110800,%eax
801009d5:	89 c2                	mov    %eax,%edx
801009d7:	83 e2 7f             	and    $0x7f,%edx
801009da:	0f b6 92 80 07 11 80 	movzbl -0x7feef880(%edx),%edx
801009e1:	0f be d2             	movsbl %dl,%edx
801009e4:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009e7:	83 c0 01             	add    $0x1,%eax
801009ea:	a3 00 08 11 80       	mov    %eax,0x80110800
    if(c == C('D')){  // EOF
801009ef:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009f3:	75 17                	jne    80100a0c <consoleread+0xb8>
      if(n < target){
801009f5:	8b 45 10             	mov    0x10(%ebp),%eax
801009f8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009fb:	73 2f                	jae    80100a2c <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009fd:	a1 00 08 11 80       	mov    0x80110800,%eax
80100a02:	83 e8 01             	sub    $0x1,%eax
80100a05:	a3 00 08 11 80       	mov    %eax,0x80110800
      }
      break;
80100a0a:	eb 20                	jmp    80100a2c <consoleread+0xd8>
    }
    *dst++ = c;
80100a0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100a0f:	89 c2                	mov    %eax,%edx
80100a11:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a14:	88 10                	mov    %dl,(%eax)
80100a16:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
80100a1a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a1e:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a22:	74 0b                	je     80100a2f <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100a24:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100a28:	7f 96                	jg     801009c0 <consoleread+0x6c>
80100a2a:	eb 04                	jmp    80100a30 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100a2c:	90                   	nop
80100a2d:	eb 01                	jmp    80100a30 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a2f:	90                   	nop
  }
  release(&cons.lock);
80100a30:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a37:	e8 7d 45 00 00       	call   80104fb9 <release>
  ilock(ip);
80100a3c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a3f:	89 04 24             	mov    %eax,(%esp)
80100a42:	e8 aa 0e 00 00       	call   801018f1 <ilock>

  return target - n;
80100a47:	8b 45 10             	mov    0x10(%ebp),%eax
80100a4a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a4d:	89 d1                	mov    %edx,%ecx
80100a4f:	29 c1                	sub    %eax,%ecx
80100a51:	89 c8                	mov    %ecx,%eax
}
80100a53:	c9                   	leave  
80100a54:	c3                   	ret    

80100a55 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a55:	55                   	push   %ebp
80100a56:	89 e5                	mov    %esp,%ebp
80100a58:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a5b:	8b 45 08             	mov    0x8(%ebp),%eax
80100a5e:	89 04 24             	mov    %eax,(%esp)
80100a61:	e8 df 0f 00 00       	call   80101a45 <iunlock>
  acquire(&cons.lock);
80100a66:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a6d:	e8 e5 44 00 00       	call   80104f57 <acquire>
  for(i = 0; i < n; i++)
80100a72:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a79:	eb 1d                	jmp    80100a98 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a7e:	03 45 0c             	add    0xc(%ebp),%eax
80100a81:	0f b6 00             	movzbl (%eax),%eax
80100a84:	0f be c0             	movsbl %al,%eax
80100a87:	25 ff 00 00 00       	and    $0xff,%eax
80100a8c:	89 04 24             	mov    %eax,(%esp)
80100a8f:	e8 d7 fc ff ff       	call   8010076b <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a94:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a9b:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a9e:	7c db                	jl     80100a7b <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100aa0:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa7:	e8 0d 45 00 00       	call   80104fb9 <release>
  ilock(ip);
80100aac:	8b 45 08             	mov    0x8(%ebp),%eax
80100aaf:	89 04 24             	mov    %eax,(%esp)
80100ab2:	e8 3a 0e 00 00       	call   801018f1 <ilock>

  return n;
80100ab7:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100aba:	c9                   	leave  
80100abb:	c3                   	ret    

80100abc <consoleinit>:

void
consoleinit(void)
{
80100abc:	55                   	push   %ebp
80100abd:	89 e5                	mov    %esp,%ebp
80100abf:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100ac2:	c7 44 24 04 1a 86 10 	movl   $0x8010861a,0x4(%esp)
80100ac9:	80 
80100aca:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100ad1:	e8 60 44 00 00       	call   80104f36 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100ad6:	c7 05 cc 11 11 80 55 	movl   $0x80100a55,0x801111cc
80100add:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ae0:	c7 05 c8 11 11 80 54 	movl   $0x80100954,0x801111c8
80100ae7:	09 10 80 
  cons.locking = 1;
80100aea:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100af1:	00 00 00 

  picenable(IRQ_KBD);
80100af4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100afb:	e8 c1 33 00 00       	call   80103ec1 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100b00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100b07:	00 
80100b08:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b0f:	e8 26 1f 00 00       	call   80102a3a <ioapicenable>
}
80100b14:	c9                   	leave  
80100b15:	c3                   	ret    
	...

80100b18 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b18:	55                   	push   %ebp
80100b19:	89 e5                	mov    %esp,%ebp
80100b1b:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100b21:	e8 e7 29 00 00       	call   8010350d <begin_op>
  if((ip = namei(path)) == 0){
80100b26:	8b 45 08             	mov    0x8(%ebp),%eax
80100b29:	89 04 24             	mov    %eax,(%esp)
80100b2c:	e8 68 19 00 00       	call   80102499 <namei>
80100b31:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b34:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b38:	75 0f                	jne    80100b49 <exec+0x31>
    end_op();
80100b3a:	e8 4f 2a 00 00       	call   8010358e <end_op>
    return -1;
80100b3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b44:	e9 dd 03 00 00       	jmp    80100f26 <exec+0x40e>
  }
  ilock(ip);
80100b49:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b4c:	89 04 24             	mov    %eax,(%esp)
80100b4f:	e8 9d 0d 00 00       	call   801018f1 <ilock>
  pgdir = 0;
80100b54:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b5b:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b62:	00 
80100b63:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b6a:	00 
80100b6b:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b71:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b75:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b78:	89 04 24             	mov    %eax,(%esp)
80100b7b:	e8 6d 12 00 00       	call   80101ded <readi>
80100b80:	83 f8 33             	cmp    $0x33,%eax
80100b83:	0f 86 52 03 00 00    	jbe    80100edb <exec+0x3c3>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b89:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b8f:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b94:	0f 85 44 03 00 00    	jne    80100ede <exec+0x3c6>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100b9a:	e8 ba 71 00 00       	call   80107d59 <setupkvm>
80100b9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100ba2:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ba6:	0f 84 35 03 00 00    	je     80100ee1 <exec+0x3c9>
    goto bad;

  // Load program into memory.
  sz = 0;
80100bac:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100bb3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100bba:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100bc0:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bc3:	e9 c5 00 00 00       	jmp    80100c8d <exec+0x175>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bc8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bcb:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bd2:	00 
80100bd3:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bd7:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bdd:	89 44 24 04          	mov    %eax,0x4(%esp)
80100be1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100be4:	89 04 24             	mov    %eax,(%esp)
80100be7:	e8 01 12 00 00       	call   80101ded <readi>
80100bec:	83 f8 20             	cmp    $0x20,%eax
80100bef:	0f 85 ef 02 00 00    	jne    80100ee4 <exec+0x3cc>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100bf5:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bfb:	83 f8 01             	cmp    $0x1,%eax
80100bfe:	75 7f                	jne    80100c7f <exec+0x167>
      continue;
    if(ph.memsz < ph.filesz)
80100c00:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100c06:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c0c:	39 c2                	cmp    %eax,%edx
80100c0e:	0f 82 d3 02 00 00    	jb     80100ee7 <exec+0x3cf>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c14:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100c1a:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c20:	01 d0                	add    %edx,%eax
80100c22:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c26:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c29:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c30:	89 04 24             	mov    %eax,(%esp)
80100c33:	e8 f3 74 00 00       	call   8010812b <allocuvm>
80100c38:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c3b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c3f:	0f 84 a5 02 00 00    	je     80100eea <exec+0x3d2>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c45:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c4b:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c51:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c57:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c5b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c5f:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c62:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c66:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c6d:	89 04 24             	mov    %eax,(%esp)
80100c70:	e8 c7 73 00 00       	call   8010803c <loaduvm>
80100c75:	85 c0                	test   %eax,%eax
80100c77:	0f 88 70 02 00 00    	js     80100eed <exec+0x3d5>
80100c7d:	eb 01                	jmp    80100c80 <exec+0x168>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c7f:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c80:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c84:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c87:	83 c0 20             	add    $0x20,%eax
80100c8a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c8d:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c94:	0f b7 c0             	movzwl %ax,%eax
80100c97:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c9a:	0f 8f 28 ff ff ff    	jg     80100bc8 <exec+0xb0>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100ca0:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ca3:	89 04 24             	mov    %eax,(%esp)
80100ca6:	e8 d0 0e 00 00       	call   80101b7b <iunlockput>
  end_op();
80100cab:	e8 de 28 00 00       	call   8010358e <end_op>
  ip = 0;
80100cb0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cb7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cba:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cbf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cc4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cc7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cca:	05 00 20 00 00       	add    $0x2000,%eax
80100ccf:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cd3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cdd:	89 04 24             	mov    %eax,(%esp)
80100ce0:	e8 46 74 00 00       	call   8010812b <allocuvm>
80100ce5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100ce8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cec:	0f 84 fe 01 00 00    	je     80100ef0 <exec+0x3d8>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cf2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cf5:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cfe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d01:	89 04 24             	mov    %eax,(%esp)
80100d04:	e8 46 76 00 00       	call   8010834f <clearpteu>
  sp = sz;
80100d09:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d0c:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d0f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d16:	e9 81 00 00 00       	jmp    80100d9c <exec+0x284>
    if(argc >= MAXARG)
80100d1b:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d1f:	0f 87 ce 01 00 00    	ja     80100ef3 <exec+0x3db>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d28:	c1 e0 02             	shl    $0x2,%eax
80100d2b:	03 45 0c             	add    0xc(%ebp),%eax
80100d2e:	8b 00                	mov    (%eax),%eax
80100d30:	89 04 24             	mov    %eax,(%esp)
80100d33:	e8 ec 46 00 00       	call   80105424 <strlen>
80100d38:	f7 d0                	not    %eax
80100d3a:	03 45 dc             	add    -0x24(%ebp),%eax
80100d3d:	83 e0 fc             	and    $0xfffffffc,%eax
80100d40:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d46:	c1 e0 02             	shl    $0x2,%eax
80100d49:	03 45 0c             	add    0xc(%ebp),%eax
80100d4c:	8b 00                	mov    (%eax),%eax
80100d4e:	89 04 24             	mov    %eax,(%esp)
80100d51:	e8 ce 46 00 00       	call   80105424 <strlen>
80100d56:	83 c0 01             	add    $0x1,%eax
80100d59:	89 c2                	mov    %eax,%edx
80100d5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d5e:	c1 e0 02             	shl    $0x2,%eax
80100d61:	03 45 0c             	add    0xc(%ebp),%eax
80100d64:	8b 00                	mov    (%eax),%eax
80100d66:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d6a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d6e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d71:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d78:	89 04 24             	mov    %eax,(%esp)
80100d7b:	e8 8f 77 00 00       	call   8010850f <copyout>
80100d80:	85 c0                	test   %eax,%eax
80100d82:	0f 88 6e 01 00 00    	js     80100ef6 <exec+0x3de>
      goto bad;
    ustack[3+argc] = sp;
80100d88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d8b:	8d 50 03             	lea    0x3(%eax),%edx
80100d8e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d91:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d98:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d9f:	c1 e0 02             	shl    $0x2,%eax
80100da2:	03 45 0c             	add    0xc(%ebp),%eax
80100da5:	8b 00                	mov    (%eax),%eax
80100da7:	85 c0                	test   %eax,%eax
80100da9:	0f 85 6c ff ff ff    	jne    80100d1b <exec+0x203>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 03             	add    $0x3,%eax
80100db5:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dbc:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dc0:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dc7:	ff ff ff 
  ustack[1] = argc;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 01             	add    $0x1,%eax
80100dd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100de0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de3:	29 d0                	sub    %edx,%eax
80100de5:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dee:	83 c0 04             	add    $0x4,%eax
80100df1:	c1 e0 02             	shl    $0x2,%eax
80100df4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	83 c0 04             	add    $0x4,%eax
80100dfd:	c1 e0 02             	shl    $0x2,%eax
80100e00:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e04:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e0e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e18:	89 04 24             	mov    %eax,(%esp)
80100e1b:	e8 ef 76 00 00       	call   8010850f <copyout>
80100e20:	85 c0                	test   %eax,%eax
80100e22:	0f 88 d1 00 00 00    	js     80100ef9 <exec+0x3e1>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e28:	8b 45 08             	mov    0x8(%ebp),%eax
80100e2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e31:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e34:	eb 17                	jmp    80100e4d <exec+0x335>
    if(*s == '/')
80100e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e39:	0f b6 00             	movzbl (%eax),%eax
80100e3c:	3c 2f                	cmp    $0x2f,%al
80100e3e:	75 09                	jne    80100e49 <exec+0x331>
      last = s+1;
80100e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e43:	83 c0 01             	add    $0x1,%eax
80100e46:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e49:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e50:	0f b6 00             	movzbl (%eax),%eax
80100e53:	84 c0                	test   %al,%al
80100e55:	75 df                	jne    80100e36 <exec+0x31e>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e57:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e5d:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e60:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e67:	00 
80100e68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e6f:	89 14 24             	mov    %edx,(%esp)
80100e72:	e8 5f 45 00 00       	call   801053d6 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7d:	8b 40 04             	mov    0x4(%eax),%eax
80100e80:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e89:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e8c:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e95:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e98:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e9a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea0:	8b 40 18             	mov    0x18(%eax),%eax
80100ea3:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100ea9:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100eac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb2:	8b 40 18             	mov    0x18(%eax),%eax
80100eb5:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eb8:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ebb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec1:	89 04 24             	mov    %eax,(%esp)
80100ec4:	e8 81 6f 00 00       	call   80107e4a <switchuvm>
  freevm(oldpgdir);
80100ec9:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecc:	89 04 24             	mov    %eax,(%esp)
80100ecf:	e8 ed 73 00 00       	call   801082c1 <freevm>
  return 0;
80100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
80100ed9:	eb 4b                	jmp    80100f26 <exec+0x40e>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100edb:	90                   	nop
80100edc:	eb 1c                	jmp    80100efa <exec+0x3e2>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100ede:	90                   	nop
80100edf:	eb 19                	jmp    80100efa <exec+0x3e2>

  if((pgdir = setupkvm()) == 0)
    goto bad;
80100ee1:	90                   	nop
80100ee2:	eb 16                	jmp    80100efa <exec+0x3e2>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100ee4:	90                   	nop
80100ee5:	eb 13                	jmp    80100efa <exec+0x3e2>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100ee7:	90                   	nop
80100ee8:	eb 10                	jmp    80100efa <exec+0x3e2>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100eea:	90                   	nop
80100eeb:	eb 0d                	jmp    80100efa <exec+0x3e2>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100eed:	90                   	nop
80100eee:	eb 0a                	jmp    80100efa <exec+0x3e2>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100ef0:	90                   	nop
80100ef1:	eb 07                	jmp    80100efa <exec+0x3e2>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100ef3:	90                   	nop
80100ef4:	eb 04                	jmp    80100efa <exec+0x3e2>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100ef6:	90                   	nop
80100ef7:	eb 01                	jmp    80100efa <exec+0x3e2>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100ef9:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100efa:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100efe:	74 0b                	je     80100f0b <exec+0x3f3>
    freevm(pgdir);
80100f00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f03:	89 04 24             	mov    %eax,(%esp)
80100f06:	e8 b6 73 00 00       	call   801082c1 <freevm>
  if(ip){
80100f0b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f0f:	74 10                	je     80100f21 <exec+0x409>
    iunlockput(ip);
80100f11:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f14:	89 04 24             	mov    %eax,(%esp)
80100f17:	e8 5f 0c 00 00       	call   80101b7b <iunlockput>
    end_op();
80100f1c:	e8 6d 26 00 00       	call   8010358e <end_op>
  }
  return -1;
80100f21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f26:	c9                   	leave  
80100f27:	c3                   	ret    

80100f28 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f28:	55                   	push   %ebp
80100f29:	89 e5                	mov    %esp,%ebp
80100f2b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f2e:	c7 44 24 04 22 86 10 	movl   $0x80108622,0x4(%esp)
80100f35:	80 
80100f36:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f3d:	e8 f4 3f 00 00       	call   80104f36 <initlock>
}
80100f42:	c9                   	leave  
80100f43:	c3                   	ret    

80100f44 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f44:	55                   	push   %ebp
80100f45:	89 e5                	mov    %esp,%ebp
80100f47:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f4a:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f51:	e8 01 40 00 00       	call   80104f57 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f56:	c7 45 f4 54 08 11 80 	movl   $0x80110854,-0xc(%ebp)
80100f5d:	eb 29                	jmp    80100f88 <filealloc+0x44>
    if(f->ref == 0){
80100f5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f62:	8b 40 04             	mov    0x4(%eax),%eax
80100f65:	85 c0                	test   %eax,%eax
80100f67:	75 1b                	jne    80100f84 <filealloc+0x40>
      f->ref = 1;
80100f69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f6c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f73:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f7a:	e8 3a 40 00 00       	call   80104fb9 <release>
      return f;
80100f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f82:	eb 1e                	jmp    80100fa2 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f84:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f88:	81 7d f4 b4 11 11 80 	cmpl   $0x801111b4,-0xc(%ebp)
80100f8f:	72 ce                	jb     80100f5f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f91:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f98:	e8 1c 40 00 00       	call   80104fb9 <release>
  return 0;
80100f9d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fa2:	c9                   	leave  
80100fa3:	c3                   	ret    

80100fa4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fa4:	55                   	push   %ebp
80100fa5:	89 e5                	mov    %esp,%ebp
80100fa7:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100faa:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100fb1:	e8 a1 3f 00 00       	call   80104f57 <acquire>
  if(f->ref < 1)
80100fb6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb9:	8b 40 04             	mov    0x4(%eax),%eax
80100fbc:	85 c0                	test   %eax,%eax
80100fbe:	7f 0c                	jg     80100fcc <filedup+0x28>
    panic("filedup");
80100fc0:	c7 04 24 29 86 10 80 	movl   $0x80108629,(%esp)
80100fc7:	e8 71 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80100fcf:	8b 40 04             	mov    0x4(%eax),%eax
80100fd2:	8d 50 01             	lea    0x1(%eax),%edx
80100fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fdb:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100fe2:	e8 d2 3f 00 00       	call   80104fb9 <release>
  return f;
80100fe7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fea:	c9                   	leave  
80100feb:	c3                   	ret    

80100fec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fec:	55                   	push   %ebp
80100fed:	89 e5                	mov    %esp,%ebp
80100fef:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100ff2:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100ff9:	e8 59 3f 00 00       	call   80104f57 <acquire>
  if(f->ref < 1)
80100ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80101001:	8b 40 04             	mov    0x4(%eax),%eax
80101004:	85 c0                	test   %eax,%eax
80101006:	7f 0c                	jg     80101014 <fileclose+0x28>
    panic("fileclose");
80101008:	c7 04 24 31 86 10 80 	movl   $0x80108631,(%esp)
8010100f:	e8 29 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80101014:	8b 45 08             	mov    0x8(%ebp),%eax
80101017:	8b 40 04             	mov    0x4(%eax),%eax
8010101a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010101d:	8b 45 08             	mov    0x8(%ebp),%eax
80101020:	89 50 04             	mov    %edx,0x4(%eax)
80101023:	8b 45 08             	mov    0x8(%ebp),%eax
80101026:	8b 40 04             	mov    0x4(%eax),%eax
80101029:	85 c0                	test   %eax,%eax
8010102b:	7e 11                	jle    8010103e <fileclose+0x52>
    release(&ftable.lock);
8010102d:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80101034:	e8 80 3f 00 00       	call   80104fb9 <release>
    return;
80101039:	e9 82 00 00 00       	jmp    801010c0 <fileclose+0xd4>
  }
  ff = *f;
8010103e:	8b 45 08             	mov    0x8(%ebp),%eax
80101041:	8b 10                	mov    (%eax),%edx
80101043:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101046:	8b 50 04             	mov    0x4(%eax),%edx
80101049:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010104c:	8b 50 08             	mov    0x8(%eax),%edx
8010104f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101052:	8b 50 0c             	mov    0xc(%eax),%edx
80101055:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101058:	8b 50 10             	mov    0x10(%eax),%edx
8010105b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010105e:	8b 40 14             	mov    0x14(%eax),%eax
80101061:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101064:	8b 45 08             	mov    0x8(%ebp),%eax
80101067:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010106e:	8b 45 08             	mov    0x8(%ebp),%eax
80101071:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101077:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
8010107e:	e8 36 3f 00 00       	call   80104fb9 <release>
  
  if(ff.type == FD_PIPE)
80101083:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101086:	83 f8 01             	cmp    $0x1,%eax
80101089:	75 18                	jne    801010a3 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010108b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010108f:	0f be d0             	movsbl %al,%edx
80101092:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101095:	89 54 24 04          	mov    %edx,0x4(%esp)
80101099:	89 04 24             	mov    %eax,(%esp)
8010109c:	e8 da 30 00 00       	call   8010417b <pipeclose>
801010a1:	eb 1d                	jmp    801010c0 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010a6:	83 f8 02             	cmp    $0x2,%eax
801010a9:	75 15                	jne    801010c0 <fileclose+0xd4>
    begin_op();
801010ab:	e8 5d 24 00 00       	call   8010350d <begin_op>
    iput(ff.ip);
801010b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010b3:	89 04 24             	mov    %eax,(%esp)
801010b6:	e8 ef 09 00 00       	call   80101aaa <iput>
    end_op();
801010bb:	e8 ce 24 00 00       	call   8010358e <end_op>
  }
}
801010c0:	c9                   	leave  
801010c1:	c3                   	ret    

801010c2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010c2:	55                   	push   %ebp
801010c3:	89 e5                	mov    %esp,%ebp
801010c5:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010c8:	8b 45 08             	mov    0x8(%ebp),%eax
801010cb:	8b 00                	mov    (%eax),%eax
801010cd:	83 f8 02             	cmp    $0x2,%eax
801010d0:	75 38                	jne    8010110a <filestat+0x48>
    ilock(f->ip);
801010d2:	8b 45 08             	mov    0x8(%ebp),%eax
801010d5:	8b 40 10             	mov    0x10(%eax),%eax
801010d8:	89 04 24             	mov    %eax,(%esp)
801010db:	e8 11 08 00 00       	call   801018f1 <ilock>
    stati(f->ip, st);
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 10             	mov    0x10(%eax),%eax
801010e6:	8b 55 0c             	mov    0xc(%ebp),%edx
801010e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801010ed:	89 04 24             	mov    %eax,(%esp)
801010f0:	e8 b3 0c 00 00       	call   80101da8 <stati>
    iunlock(f->ip);
801010f5:	8b 45 08             	mov    0x8(%ebp),%eax
801010f8:	8b 40 10             	mov    0x10(%eax),%eax
801010fb:	89 04 24             	mov    %eax,(%esp)
801010fe:	e8 42 09 00 00       	call   80101a45 <iunlock>
    return 0;
80101103:	b8 00 00 00 00       	mov    $0x0,%eax
80101108:	eb 05                	jmp    8010110f <filestat+0x4d>
  }
  return -1;
8010110a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010110f:	c9                   	leave  
80101110:	c3                   	ret    

80101111 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101111:	55                   	push   %ebp
80101112:	89 e5                	mov    %esp,%ebp
80101114:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101117:	8b 45 08             	mov    0x8(%ebp),%eax
8010111a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010111e:	84 c0                	test   %al,%al
80101120:	75 0a                	jne    8010112c <fileread+0x1b>
    return -1;
80101122:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101127:	e9 9f 00 00 00       	jmp    801011cb <fileread+0xba>
  if(f->type == FD_PIPE)
8010112c:	8b 45 08             	mov    0x8(%ebp),%eax
8010112f:	8b 00                	mov    (%eax),%eax
80101131:	83 f8 01             	cmp    $0x1,%eax
80101134:	75 1e                	jne    80101154 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 40 0c             	mov    0xc(%eax),%eax
8010113c:	8b 55 10             	mov    0x10(%ebp),%edx
8010113f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101143:	8b 55 0c             	mov    0xc(%ebp),%edx
80101146:	89 54 24 04          	mov    %edx,0x4(%esp)
8010114a:	89 04 24             	mov    %eax,(%esp)
8010114d:	e8 ab 31 00 00       	call   801042fd <piperead>
80101152:	eb 77                	jmp    801011cb <fileread+0xba>
  if(f->type == FD_INODE){
80101154:	8b 45 08             	mov    0x8(%ebp),%eax
80101157:	8b 00                	mov    (%eax),%eax
80101159:	83 f8 02             	cmp    $0x2,%eax
8010115c:	75 61                	jne    801011bf <fileread+0xae>
    ilock(f->ip);
8010115e:	8b 45 08             	mov    0x8(%ebp),%eax
80101161:	8b 40 10             	mov    0x10(%eax),%eax
80101164:	89 04 24             	mov    %eax,(%esp)
80101167:	e8 85 07 00 00       	call   801018f1 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010116c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010116f:	8b 45 08             	mov    0x8(%ebp),%eax
80101172:	8b 50 14             	mov    0x14(%eax),%edx
80101175:	8b 45 08             	mov    0x8(%ebp),%eax
80101178:	8b 40 10             	mov    0x10(%eax),%eax
8010117b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010117f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101183:	8b 55 0c             	mov    0xc(%ebp),%edx
80101186:	89 54 24 04          	mov    %edx,0x4(%esp)
8010118a:	89 04 24             	mov    %eax,(%esp)
8010118d:	e8 5b 0c 00 00       	call   80101ded <readi>
80101192:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101195:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101199:	7e 11                	jle    801011ac <fileread+0x9b>
      f->off += r;
8010119b:	8b 45 08             	mov    0x8(%ebp),%eax
8010119e:	8b 50 14             	mov    0x14(%eax),%edx
801011a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011a4:	01 c2                	add    %eax,%edx
801011a6:	8b 45 08             	mov    0x8(%ebp),%eax
801011a9:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011ac:	8b 45 08             	mov    0x8(%ebp),%eax
801011af:	8b 40 10             	mov    0x10(%eax),%eax
801011b2:	89 04 24             	mov    %eax,(%esp)
801011b5:	e8 8b 08 00 00       	call   80101a45 <iunlock>
    return r;
801011ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011bd:	eb 0c                	jmp    801011cb <fileread+0xba>
  }
  panic("fileread");
801011bf:	c7 04 24 3b 86 10 80 	movl   $0x8010863b,(%esp)
801011c6:	e8 72 f3 ff ff       	call   8010053d <panic>
}
801011cb:	c9                   	leave  
801011cc:	c3                   	ret    

801011cd <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011cd:	55                   	push   %ebp
801011ce:	89 e5                	mov    %esp,%ebp
801011d0:	53                   	push   %ebx
801011d1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011d4:	8b 45 08             	mov    0x8(%ebp),%eax
801011d7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011db:	84 c0                	test   %al,%al
801011dd:	75 0a                	jne    801011e9 <filewrite+0x1c>
    return -1;
801011df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011e4:	e9 23 01 00 00       	jmp    8010130c <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011e9:	8b 45 08             	mov    0x8(%ebp),%eax
801011ec:	8b 00                	mov    (%eax),%eax
801011ee:	83 f8 01             	cmp    $0x1,%eax
801011f1:	75 21                	jne    80101214 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011f3:	8b 45 08             	mov    0x8(%ebp),%eax
801011f6:	8b 40 0c             	mov    0xc(%eax),%eax
801011f9:	8b 55 10             	mov    0x10(%ebp),%edx
801011fc:	89 54 24 08          	mov    %edx,0x8(%esp)
80101200:	8b 55 0c             	mov    0xc(%ebp),%edx
80101203:	89 54 24 04          	mov    %edx,0x4(%esp)
80101207:	89 04 24             	mov    %eax,(%esp)
8010120a:	e8 fe 2f 00 00       	call   8010420d <pipewrite>
8010120f:	e9 f8 00 00 00       	jmp    8010130c <filewrite+0x13f>
  if(f->type == FD_INODE){
80101214:	8b 45 08             	mov    0x8(%ebp),%eax
80101217:	8b 00                	mov    (%eax),%eax
80101219:	83 f8 02             	cmp    $0x2,%eax
8010121c:	0f 85 de 00 00 00    	jne    80101300 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101222:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101229:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101230:	e9 a8 00 00 00       	jmp    801012dd <filewrite+0x110>
      int n1 = n - i;
80101235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101238:	8b 55 10             	mov    0x10(%ebp),%edx
8010123b:	89 d1                	mov    %edx,%ecx
8010123d:	29 c1                	sub    %eax,%ecx
8010123f:	89 c8                	mov    %ecx,%eax
80101241:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101247:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010124a:	7e 06                	jle    80101252 <filewrite+0x85>
        n1 = max;
8010124c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010124f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101252:	e8 b6 22 00 00       	call   8010350d <begin_op>
      ilock(f->ip);
80101257:	8b 45 08             	mov    0x8(%ebp),%eax
8010125a:	8b 40 10             	mov    0x10(%eax),%eax
8010125d:	89 04 24             	mov    %eax,(%esp)
80101260:	e8 8c 06 00 00       	call   801018f1 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101265:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101268:	8b 45 08             	mov    0x8(%ebp),%eax
8010126b:	8b 48 14             	mov    0x14(%eax),%ecx
8010126e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101271:	89 c2                	mov    %eax,%edx
80101273:	03 55 0c             	add    0xc(%ebp),%edx
80101276:	8b 45 08             	mov    0x8(%ebp),%eax
80101279:	8b 40 10             	mov    0x10(%eax),%eax
8010127c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101280:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80101284:	89 54 24 04          	mov    %edx,0x4(%esp)
80101288:	89 04 24             	mov    %eax,(%esp)
8010128b:	e8 c8 0c 00 00       	call   80101f58 <writei>
80101290:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101293:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101297:	7e 11                	jle    801012aa <filewrite+0xdd>
        f->off += r;
80101299:	8b 45 08             	mov    0x8(%ebp),%eax
8010129c:	8b 50 14             	mov    0x14(%eax),%edx
8010129f:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a2:	01 c2                	add    %eax,%edx
801012a4:	8b 45 08             	mov    0x8(%ebp),%eax
801012a7:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012aa:	8b 45 08             	mov    0x8(%ebp),%eax
801012ad:	8b 40 10             	mov    0x10(%eax),%eax
801012b0:	89 04 24             	mov    %eax,(%esp)
801012b3:	e8 8d 07 00 00       	call   80101a45 <iunlock>
      end_op();
801012b8:	e8 d1 22 00 00       	call   8010358e <end_op>

      if(r < 0)
801012bd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012c1:	78 28                	js     801012eb <filewrite+0x11e>
        break;
      if(r != n1)
801012c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012c6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012c9:	74 0c                	je     801012d7 <filewrite+0x10a>
        panic("short filewrite");
801012cb:	c7 04 24 44 86 10 80 	movl   $0x80108644,(%esp)
801012d2:	e8 66 f2 ff ff       	call   8010053d <panic>
      i += r;
801012d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012da:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012e0:	3b 45 10             	cmp    0x10(%ebp),%eax
801012e3:	0f 8c 4c ff ff ff    	jl     80101235 <filewrite+0x68>
801012e9:	eb 01                	jmp    801012ec <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
801012eb:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ef:	3b 45 10             	cmp    0x10(%ebp),%eax
801012f2:	75 05                	jne    801012f9 <filewrite+0x12c>
801012f4:	8b 45 10             	mov    0x10(%ebp),%eax
801012f7:	eb 05                	jmp    801012fe <filewrite+0x131>
801012f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012fe:	eb 0c                	jmp    8010130c <filewrite+0x13f>
  }
  panic("filewrite");
80101300:	c7 04 24 54 86 10 80 	movl   $0x80108654,(%esp)
80101307:	e8 31 f2 ff ff       	call   8010053d <panic>
}
8010130c:	83 c4 24             	add    $0x24,%esp
8010130f:	5b                   	pop    %ebx
80101310:	5d                   	pop    %ebp
80101311:	c3                   	ret    
	...

80101314 <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101314:	55                   	push   %ebp
80101315:	89 e5                	mov    %esp,%ebp
80101317:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010131a:	8b 45 08             	mov    0x8(%ebp),%eax
8010131d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101324:	00 
80101325:	89 04 24             	mov    %eax,(%esp)
80101328:	e8 79 ee ff ff       	call   801001a6 <bread>
8010132d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101333:	83 c0 18             	add    $0x18,%eax
80101336:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
8010133d:	00 
8010133e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101342:	8b 45 0c             	mov    0xc(%ebp),%eax
80101345:	89 04 24             	mov    %eax,(%esp)
80101348:	e8 2c 3f 00 00       	call   80105279 <memmove>
  brelse(bp);
8010134d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101350:	89 04 24             	mov    %eax,(%esp)
80101353:	e8 bf ee ff ff       	call   80100217 <brelse>
}
80101358:	c9                   	leave  
80101359:	c3                   	ret    

8010135a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010135a:	55                   	push   %ebp
8010135b:	89 e5                	mov    %esp,%ebp
8010135d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101360:	8b 55 0c             	mov    0xc(%ebp),%edx
80101363:	8b 45 08             	mov    0x8(%ebp),%eax
80101366:	89 54 24 04          	mov    %edx,0x4(%esp)
8010136a:	89 04 24             	mov    %eax,(%esp)
8010136d:	e8 34 ee ff ff       	call   801001a6 <bread>
80101372:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101375:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101378:	83 c0 18             	add    $0x18,%eax
8010137b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101382:	00 
80101383:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010138a:	00 
8010138b:	89 04 24             	mov    %eax,(%esp)
8010138e:	e8 13 3e 00 00       	call   801051a6 <memset>
  log_write(bp);
80101393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101396:	89 04 24             	mov    %eax,(%esp)
80101399:	e8 74 23 00 00       	call   80103712 <log_write>
  brelse(bp);
8010139e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a1:	89 04 24             	mov    %eax,(%esp)
801013a4:	e8 6e ee ff ff       	call   80100217 <brelse>
}
801013a9:	c9                   	leave  
801013aa:	c3                   	ret    

801013ab <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013ab:	55                   	push   %ebp
801013ac:	89 e5                	mov    %esp,%ebp
801013ae:	53                   	push   %ebx
801013af:	83 ec 24             	sub    $0x24,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801013b2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801013b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013c0:	e9 11 01 00 00       	jmp    801014d6 <balloc+0x12b>
    bp = bread(dev, BBLOCK(b, sb));
801013c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c8:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013ce:	85 c0                	test   %eax,%eax
801013d0:	0f 48 c2             	cmovs  %edx,%eax
801013d3:	c1 f8 0c             	sar    $0xc,%eax
801013d6:	89 c2                	mov    %eax,%edx
801013d8:	a1 38 12 11 80       	mov    0x80111238,%eax
801013dd:	01 d0                	add    %edx,%eax
801013df:	89 44 24 04          	mov    %eax,0x4(%esp)
801013e3:	8b 45 08             	mov    0x8(%ebp),%eax
801013e6:	89 04 24             	mov    %eax,(%esp)
801013e9:	e8 b8 ed ff ff       	call   801001a6 <bread>
801013ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013f1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013f8:	e9 a7 00 00 00       	jmp    801014a4 <balloc+0xf9>
      m = 1 << (bi % 8);
801013fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101400:	89 c2                	mov    %eax,%edx
80101402:	c1 fa 1f             	sar    $0x1f,%edx
80101405:	c1 ea 1d             	shr    $0x1d,%edx
80101408:	01 d0                	add    %edx,%eax
8010140a:	83 e0 07             	and    $0x7,%eax
8010140d:	29 d0                	sub    %edx,%eax
8010140f:	ba 01 00 00 00       	mov    $0x1,%edx
80101414:	89 d3                	mov    %edx,%ebx
80101416:	89 c1                	mov    %eax,%ecx
80101418:	d3 e3                	shl    %cl,%ebx
8010141a:	89 d8                	mov    %ebx,%eax
8010141c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010141f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101422:	8d 50 07             	lea    0x7(%eax),%edx
80101425:	85 c0                	test   %eax,%eax
80101427:	0f 48 c2             	cmovs  %edx,%eax
8010142a:	c1 f8 03             	sar    $0x3,%eax
8010142d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101430:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101435:	0f b6 c0             	movzbl %al,%eax
80101438:	23 45 e8             	and    -0x18(%ebp),%eax
8010143b:	85 c0                	test   %eax,%eax
8010143d:	75 61                	jne    801014a0 <balloc+0xf5>
        bp->data[bi/8] |= m;  // Mark block in use.
8010143f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101442:	8d 50 07             	lea    0x7(%eax),%edx
80101445:	85 c0                	test   %eax,%eax
80101447:	0f 48 c2             	cmovs  %edx,%eax
8010144a:	c1 f8 03             	sar    $0x3,%eax
8010144d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101450:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101455:	89 d1                	mov    %edx,%ecx
80101457:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010145a:	09 ca                	or     %ecx,%edx
8010145c:	89 d1                	mov    %edx,%ecx
8010145e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101461:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101465:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101468:	89 04 24             	mov    %eax,(%esp)
8010146b:	e8 a2 22 00 00       	call   80103712 <log_write>
        brelse(bp);
80101470:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 9c ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010147b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010147e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101481:	01 c2                	add    %eax,%edx
80101483:	8b 45 08             	mov    0x8(%ebp),%eax
80101486:	89 54 24 04          	mov    %edx,0x4(%esp)
8010148a:	89 04 24             	mov    %eax,(%esp)
8010148d:	e8 c8 fe ff ff       	call   8010135a <bzero>
        return b + bi;
80101492:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101495:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101498:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010149a:	83 c4 24             	add    $0x24,%esp
8010149d:	5b                   	pop    %ebx
8010149e:	5d                   	pop    %ebp
8010149f:	c3                   	ret    
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014a0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014a4:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014ab:	7f 17                	jg     801014c4 <balloc+0x119>
801014ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014b3:	01 d0                	add    %edx,%eax
801014b5:	89 c2                	mov    %eax,%edx
801014b7:	a1 20 12 11 80       	mov    0x80111220,%eax
801014bc:	39 c2                	cmp    %eax,%edx
801014be:	0f 82 39 ff ff ff    	jb     801013fd <balloc+0x52>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014c7:	89 04 24             	mov    %eax,(%esp)
801014ca:	e8 48 ed ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
801014cf:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014d9:	a1 20 12 11 80       	mov    0x80111220,%eax
801014de:	39 c2                	cmp    %eax,%edx
801014e0:	0f 82 df fe ff ff    	jb     801013c5 <balloc+0x1a>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014e6:	c7 04 24 60 86 10 80 	movl   $0x80108660,(%esp)
801014ed:	e8 4b f0 ff ff       	call   8010053d <panic>

801014f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014f2:	55                   	push   %ebp
801014f3:	89 e5                	mov    %esp,%ebp
801014f5:	53                   	push   %ebx
801014f6:	83 ec 24             	sub    $0x24,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
801014f9:	c7 44 24 04 20 12 11 	movl   $0x80111220,0x4(%esp)
80101500:	80 
80101501:	8b 45 08             	mov    0x8(%ebp),%eax
80101504:	89 04 24             	mov    %eax,(%esp)
80101507:	e8 08 fe ff ff       	call   80101314 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
8010150c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010150f:	89 c2                	mov    %eax,%edx
80101511:	c1 ea 0c             	shr    $0xc,%edx
80101514:	a1 38 12 11 80       	mov    0x80111238,%eax
80101519:	01 c2                	add    %eax,%edx
8010151b:	8b 45 08             	mov    0x8(%ebp),%eax
8010151e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101522:	89 04 24             	mov    %eax,(%esp)
80101525:	e8 7c ec ff ff       	call   801001a6 <bread>
8010152a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010152d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101530:	25 ff 0f 00 00       	and    $0xfff,%eax
80101535:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101538:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153b:	89 c2                	mov    %eax,%edx
8010153d:	c1 fa 1f             	sar    $0x1f,%edx
80101540:	c1 ea 1d             	shr    $0x1d,%edx
80101543:	01 d0                	add    %edx,%eax
80101545:	83 e0 07             	and    $0x7,%eax
80101548:	29 d0                	sub    %edx,%eax
8010154a:	ba 01 00 00 00       	mov    $0x1,%edx
8010154f:	89 d3                	mov    %edx,%ebx
80101551:	89 c1                	mov    %eax,%ecx
80101553:	d3 e3                	shl    %cl,%ebx
80101555:	89 d8                	mov    %ebx,%eax
80101557:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010155a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010155d:	8d 50 07             	lea    0x7(%eax),%edx
80101560:	85 c0                	test   %eax,%eax
80101562:	0f 48 c2             	cmovs  %edx,%eax
80101565:	c1 f8 03             	sar    $0x3,%eax
80101568:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010156b:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101570:	0f b6 c0             	movzbl %al,%eax
80101573:	23 45 ec             	and    -0x14(%ebp),%eax
80101576:	85 c0                	test   %eax,%eax
80101578:	75 0c                	jne    80101586 <bfree+0x94>
    panic("freeing free block");
8010157a:	c7 04 24 76 86 10 80 	movl   $0x80108676,(%esp)
80101581:	e8 b7 ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101586:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101589:	8d 50 07             	lea    0x7(%eax),%edx
8010158c:	85 c0                	test   %eax,%eax
8010158e:	0f 48 c2             	cmovs  %edx,%eax
80101591:	c1 f8 03             	sar    $0x3,%eax
80101594:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101597:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010159c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010159f:	f7 d1                	not    %ecx
801015a1:	21 ca                	and    %ecx,%edx
801015a3:	89 d1                	mov    %edx,%ecx
801015a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015a8:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015af:	89 04 24             	mov    %eax,(%esp)
801015b2:	e8 5b 21 00 00       	call   80103712 <log_write>
  brelse(bp);
801015b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015ba:	89 04 24             	mov    %eax,(%esp)
801015bd:	e8 55 ec ff ff       	call   80100217 <brelse>
}
801015c2:	83 c4 24             	add    $0x24,%esp
801015c5:	5b                   	pop    %ebx
801015c6:	5d                   	pop    %ebp
801015c7:	c3                   	ret    

801015c8 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
801015c8:	55                   	push   %ebp
801015c9:	89 e5                	mov    %esp,%ebp
801015cb:	57                   	push   %edi
801015cc:	56                   	push   %esi
801015cd:	53                   	push   %ebx
801015ce:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
801015d1:	c7 44 24 04 89 86 10 	movl   $0x80108689,0x4(%esp)
801015d8:	80 
801015d9:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801015e0:	e8 51 39 00 00       	call   80104f36 <initlock>
  readsb(dev, &sb);
801015e5:	c7 44 24 04 20 12 11 	movl   $0x80111220,0x4(%esp)
801015ec:	80 
801015ed:	8b 45 08             	mov    0x8(%ebp),%eax
801015f0:	89 04 24             	mov    %eax,(%esp)
801015f3:	e8 1c fd ff ff       	call   80101314 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
801015f8:	a1 38 12 11 80       	mov    0x80111238,%eax
801015fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101600:	8b 3d 34 12 11 80    	mov    0x80111234,%edi
80101606:	8b 35 30 12 11 80    	mov    0x80111230,%esi
8010160c:	8b 1d 2c 12 11 80    	mov    0x8011122c,%ebx
80101612:	8b 0d 28 12 11 80    	mov    0x80111228,%ecx
80101618:	8b 15 24 12 11 80    	mov    0x80111224,%edx
8010161e:	a1 20 12 11 80       	mov    0x80111220,%eax
80101623:	89 45 e0             	mov    %eax,-0x20(%ebp)
80101626:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101629:	89 44 24 1c          	mov    %eax,0x1c(%esp)
8010162d:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101631:	89 74 24 14          	mov    %esi,0x14(%esp)
80101635:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80101639:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010163d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101641:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101644:	89 44 24 04          	mov    %eax,0x4(%esp)
80101648:	c7 04 24 90 86 10 80 	movl   $0x80108690,(%esp)
8010164f:	e8 4d ed ff ff       	call   801003a1 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
80101654:	83 c4 3c             	add    $0x3c,%esp
80101657:	5b                   	pop    %ebx
80101658:	5e                   	pop    %esi
80101659:	5f                   	pop    %edi
8010165a:	5d                   	pop    %ebp
8010165b:	c3                   	ret    

8010165c <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010165c:	55                   	push   %ebp
8010165d:	89 e5                	mov    %esp,%ebp
8010165f:	83 ec 38             	sub    $0x38,%esp
80101662:	8b 45 0c             	mov    0xc(%ebp),%eax
80101665:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101669:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101670:	e9 9e 00 00 00       	jmp    80101713 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101678:	89 c2                	mov    %eax,%edx
8010167a:	c1 ea 03             	shr    $0x3,%edx
8010167d:	a1 34 12 11 80       	mov    0x80111234,%eax
80101682:	01 d0                	add    %edx,%eax
80101684:	89 44 24 04          	mov    %eax,0x4(%esp)
80101688:	8b 45 08             	mov    0x8(%ebp),%eax
8010168b:	89 04 24             	mov    %eax,(%esp)
8010168e:	e8 13 eb ff ff       	call   801001a6 <bread>
80101693:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101696:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101699:	8d 50 18             	lea    0x18(%eax),%edx
8010169c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010169f:	83 e0 07             	and    $0x7,%eax
801016a2:	c1 e0 06             	shl    $0x6,%eax
801016a5:	01 d0                	add    %edx,%eax
801016a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801016aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016ad:	0f b7 00             	movzwl (%eax),%eax
801016b0:	66 85 c0             	test   %ax,%ax
801016b3:	75 4f                	jne    80101704 <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
801016b5:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801016bc:	00 
801016bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801016c4:	00 
801016c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016c8:	89 04 24             	mov    %eax,(%esp)
801016cb:	e8 d6 3a 00 00       	call   801051a6 <memset>
      dip->type = type;
801016d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016d3:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801016d7:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801016da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016dd:	89 04 24             	mov    %eax,(%esp)
801016e0:	e8 2d 20 00 00       	call   80103712 <log_write>
      brelse(bp);
801016e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016e8:	89 04 24             	mov    %eax,(%esp)
801016eb:	e8 27 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801016f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801016f7:	8b 45 08             	mov    0x8(%ebp),%eax
801016fa:	89 04 24             	mov    %eax,(%esp)
801016fd:	e8 eb 00 00 00       	call   801017ed <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101702:	c9                   	leave  
80101703:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80101704:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101707:	89 04 24             	mov    %eax,(%esp)
8010170a:	e8 08 eb ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010170f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101713:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101716:	a1 28 12 11 80       	mov    0x80111228,%eax
8010171b:	39 c2                	cmp    %eax,%edx
8010171d:	0f 82 52 ff ff ff    	jb     80101675 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101723:	c7 04 24 e3 86 10 80 	movl   $0x801086e3,(%esp)
8010172a:	e8 0e ee ff ff       	call   8010053d <panic>

8010172f <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010172f:	55                   	push   %ebp
80101730:	89 e5                	mov    %esp,%ebp
80101732:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101735:	8b 45 08             	mov    0x8(%ebp),%eax
80101738:	8b 40 04             	mov    0x4(%eax),%eax
8010173b:	89 c2                	mov    %eax,%edx
8010173d:	c1 ea 03             	shr    $0x3,%edx
80101740:	a1 34 12 11 80       	mov    0x80111234,%eax
80101745:	01 c2                	add    %eax,%edx
80101747:	8b 45 08             	mov    0x8(%ebp),%eax
8010174a:	8b 00                	mov    (%eax),%eax
8010174c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101750:	89 04 24             	mov    %eax,(%esp)
80101753:	e8 4e ea ff ff       	call   801001a6 <bread>
80101758:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010175b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010175e:	8d 50 18             	lea    0x18(%eax),%edx
80101761:	8b 45 08             	mov    0x8(%ebp),%eax
80101764:	8b 40 04             	mov    0x4(%eax),%eax
80101767:	83 e0 07             	and    $0x7,%eax
8010176a:	c1 e0 06             	shl    $0x6,%eax
8010176d:	01 d0                	add    %edx,%eax
8010176f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101772:	8b 45 08             	mov    0x8(%ebp),%eax
80101775:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101779:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010177c:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101786:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101789:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010178d:	8b 45 08             	mov    0x8(%ebp),%eax
80101790:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101794:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101797:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010179b:	8b 45 08             	mov    0x8(%ebp),%eax
8010179e:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801017a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a5:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801017a9:	8b 45 08             	mov    0x8(%ebp),%eax
801017ac:	8b 50 18             	mov    0x18(%eax),%edx
801017af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017b2:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801017b5:	8b 45 08             	mov    0x8(%ebp),%eax
801017b8:	8d 50 1c             	lea    0x1c(%eax),%edx
801017bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017be:	83 c0 0c             	add    $0xc,%eax
801017c1:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801017c8:	00 
801017c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801017cd:	89 04 24             	mov    %eax,(%esp)
801017d0:	e8 a4 3a 00 00       	call   80105279 <memmove>
  log_write(bp);
801017d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d8:	89 04 24             	mov    %eax,(%esp)
801017db:	e8 32 1f 00 00       	call   80103712 <log_write>
  brelse(bp);
801017e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e3:	89 04 24             	mov    %eax,(%esp)
801017e6:	e8 2c ea ff ff       	call   80100217 <brelse>
}
801017eb:	c9                   	leave  
801017ec:	c3                   	ret    

801017ed <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801017ed:	55                   	push   %ebp
801017ee:	89 e5                	mov    %esp,%ebp
801017f0:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801017f3:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017fa:	e8 58 37 00 00       	call   80104f57 <acquire>

  // Is the inode already cached?
  empty = 0;
801017ff:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101806:	c7 45 f4 74 12 11 80 	movl   $0x80111274,-0xc(%ebp)
8010180d:	eb 59                	jmp    80101868 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010180f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101812:	8b 40 08             	mov    0x8(%eax),%eax
80101815:	85 c0                	test   %eax,%eax
80101817:	7e 35                	jle    8010184e <iget+0x61>
80101819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181c:	8b 00                	mov    (%eax),%eax
8010181e:	3b 45 08             	cmp    0x8(%ebp),%eax
80101821:	75 2b                	jne    8010184e <iget+0x61>
80101823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101826:	8b 40 04             	mov    0x4(%eax),%eax
80101829:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010182c:	75 20                	jne    8010184e <iget+0x61>
      ip->ref++;
8010182e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101831:	8b 40 08             	mov    0x8(%eax),%eax
80101834:	8d 50 01             	lea    0x1(%eax),%edx
80101837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010183a:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
8010183d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101844:	e8 70 37 00 00       	call   80104fb9 <release>
      return ip;
80101849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184c:	eb 6f                	jmp    801018bd <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010184e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101852:	75 10                	jne    80101864 <iget+0x77>
80101854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101857:	8b 40 08             	mov    0x8(%eax),%eax
8010185a:	85 c0                	test   %eax,%eax
8010185c:	75 06                	jne    80101864 <iget+0x77>
      empty = ip;
8010185e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101861:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101864:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101868:	81 7d f4 14 22 11 80 	cmpl   $0x80112214,-0xc(%ebp)
8010186f:	72 9e                	jb     8010180f <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101871:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101875:	75 0c                	jne    80101883 <iget+0x96>
    panic("iget: no inodes");
80101877:	c7 04 24 f5 86 10 80 	movl   $0x801086f5,(%esp)
8010187e:	e8 ba ec ff ff       	call   8010053d <panic>

  ip = empty;
80101883:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101886:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101889:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010188c:	8b 55 08             	mov    0x8(%ebp),%edx
8010188f:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101894:	8b 55 0c             	mov    0xc(%ebp),%edx
80101897:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010189a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189d:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801018a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801018ae:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018b5:	e8 ff 36 00 00       	call   80104fb9 <release>

  return ip;
801018ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801018bd:	c9                   	leave  
801018be:	c3                   	ret    

801018bf <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801018bf:	55                   	push   %ebp
801018c0:	89 e5                	mov    %esp,%ebp
801018c2:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801018c5:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018cc:	e8 86 36 00 00       	call   80104f57 <acquire>
  ip->ref++;
801018d1:	8b 45 08             	mov    0x8(%ebp),%eax
801018d4:	8b 40 08             	mov    0x8(%eax),%eax
801018d7:	8d 50 01             	lea    0x1(%eax),%edx
801018da:	8b 45 08             	mov    0x8(%ebp),%eax
801018dd:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801018e0:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018e7:	e8 cd 36 00 00       	call   80104fb9 <release>
  return ip;
801018ec:	8b 45 08             	mov    0x8(%ebp),%eax
}
801018ef:	c9                   	leave  
801018f0:	c3                   	ret    

801018f1 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801018f1:	55                   	push   %ebp
801018f2:	89 e5                	mov    %esp,%ebp
801018f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801018f7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801018fb:	74 0a                	je     80101907 <ilock+0x16>
801018fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101900:	8b 40 08             	mov    0x8(%eax),%eax
80101903:	85 c0                	test   %eax,%eax
80101905:	7f 0c                	jg     80101913 <ilock+0x22>
    panic("ilock");
80101907:	c7 04 24 05 87 10 80 	movl   $0x80108705,(%esp)
8010190e:	e8 2a ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101913:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
8010191a:	e8 38 36 00 00       	call   80104f57 <acquire>
  while(ip->flags & I_BUSY)
8010191f:	eb 13                	jmp    80101934 <ilock+0x43>
    sleep(ip, &icache.lock);
80101921:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
80101928:	80 
80101929:	8b 45 08             	mov    0x8(%ebp),%eax
8010192c:	89 04 24             	mov    %eax,(%esp)
8010192f:	e8 45 33 00 00       	call   80104c79 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101934:	8b 45 08             	mov    0x8(%ebp),%eax
80101937:	8b 40 0c             	mov    0xc(%eax),%eax
8010193a:	83 e0 01             	and    $0x1,%eax
8010193d:	84 c0                	test   %al,%al
8010193f:	75 e0                	jne    80101921 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101941:	8b 45 08             	mov    0x8(%ebp),%eax
80101944:	8b 40 0c             	mov    0xc(%eax),%eax
80101947:	89 c2                	mov    %eax,%edx
80101949:	83 ca 01             	or     $0x1,%edx
8010194c:	8b 45 08             	mov    0x8(%ebp),%eax
8010194f:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101952:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101959:	e8 5b 36 00 00       	call   80104fb9 <release>

  if(!(ip->flags & I_VALID)){
8010195e:	8b 45 08             	mov    0x8(%ebp),%eax
80101961:	8b 40 0c             	mov    0xc(%eax),%eax
80101964:	83 e0 02             	and    $0x2,%eax
80101967:	85 c0                	test   %eax,%eax
80101969:	0f 85 d4 00 00 00    	jne    80101a43 <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010196f:	8b 45 08             	mov    0x8(%ebp),%eax
80101972:	8b 40 04             	mov    0x4(%eax),%eax
80101975:	89 c2                	mov    %eax,%edx
80101977:	c1 ea 03             	shr    $0x3,%edx
8010197a:	a1 34 12 11 80       	mov    0x80111234,%eax
8010197f:	01 c2                	add    %eax,%edx
80101981:	8b 45 08             	mov    0x8(%ebp),%eax
80101984:	8b 00                	mov    (%eax),%eax
80101986:	89 54 24 04          	mov    %edx,0x4(%esp)
8010198a:	89 04 24             	mov    %eax,(%esp)
8010198d:	e8 14 e8 ff ff       	call   801001a6 <bread>
80101992:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101998:	8d 50 18             	lea    0x18(%eax),%edx
8010199b:	8b 45 08             	mov    0x8(%ebp),%eax
8010199e:	8b 40 04             	mov    0x4(%eax),%eax
801019a1:	83 e0 07             	and    $0x7,%eax
801019a4:	c1 e0 06             	shl    $0x6,%eax
801019a7:	01 d0                	add    %edx,%eax
801019a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801019ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019af:	0f b7 10             	movzwl (%eax),%edx
801019b2:	8b 45 08             	mov    0x8(%ebp),%eax
801019b5:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801019b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019bc:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801019c0:	8b 45 08             	mov    0x8(%ebp),%eax
801019c3:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801019c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019ca:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801019ce:	8b 45 08             	mov    0x8(%ebp),%eax
801019d1:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801019d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019d8:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801019dc:	8b 45 08             	mov    0x8(%ebp),%eax
801019df:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801019e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019e6:	8b 50 08             	mov    0x8(%eax),%edx
801019e9:	8b 45 08             	mov    0x8(%ebp),%eax
801019ec:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801019ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f2:	8d 50 0c             	lea    0xc(%eax),%edx
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	83 c0 1c             	add    $0x1c,%eax
801019fb:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a02:	00 
80101a03:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a07:	89 04 24             	mov    %eax,(%esp)
80101a0a:	e8 6a 38 00 00       	call   80105279 <memmove>
    brelse(bp);
80101a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a12:	89 04 24             	mov    %eax,(%esp)
80101a15:	e8 fd e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1d:	8b 40 0c             	mov    0xc(%eax),%eax
80101a20:	89 c2                	mov    %eax,%edx
80101a22:	83 ca 02             	or     $0x2,%edx
80101a25:	8b 45 08             	mov    0x8(%ebp),%eax
80101a28:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a32:	66 85 c0             	test   %ax,%ax
80101a35:	75 0c                	jne    80101a43 <ilock+0x152>
      panic("ilock: no type");
80101a37:	c7 04 24 0b 87 10 80 	movl   $0x8010870b,(%esp)
80101a3e:	e8 fa ea ff ff       	call   8010053d <panic>
  }
}
80101a43:	c9                   	leave  
80101a44:	c3                   	ret    

80101a45 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a45:	55                   	push   %ebp
80101a46:	89 e5                	mov    %esp,%ebp
80101a48:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101a4b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a4f:	74 17                	je     80101a68 <iunlock+0x23>
80101a51:	8b 45 08             	mov    0x8(%ebp),%eax
80101a54:	8b 40 0c             	mov    0xc(%eax),%eax
80101a57:	83 e0 01             	and    $0x1,%eax
80101a5a:	85 c0                	test   %eax,%eax
80101a5c:	74 0a                	je     80101a68 <iunlock+0x23>
80101a5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a61:	8b 40 08             	mov    0x8(%eax),%eax
80101a64:	85 c0                	test   %eax,%eax
80101a66:	7f 0c                	jg     80101a74 <iunlock+0x2f>
    panic("iunlock");
80101a68:	c7 04 24 1a 87 10 80 	movl   $0x8010871a,(%esp)
80101a6f:	e8 c9 ea ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101a74:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a7b:	e8 d7 34 00 00       	call   80104f57 <acquire>
  ip->flags &= ~I_BUSY;
80101a80:	8b 45 08             	mov    0x8(%ebp),%eax
80101a83:	8b 40 0c             	mov    0xc(%eax),%eax
80101a86:	89 c2                	mov    %eax,%edx
80101a88:	83 e2 fe             	and    $0xfffffffe,%edx
80101a8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8e:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a91:	8b 45 08             	mov    0x8(%ebp),%eax
80101a94:	89 04 24             	mov    %eax,(%esp)
80101a97:	e8 b6 32 00 00       	call   80104d52 <wakeup>
  release(&icache.lock);
80101a9c:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101aa3:	e8 11 35 00 00       	call   80104fb9 <release>
}
80101aa8:	c9                   	leave  
80101aa9:	c3                   	ret    

80101aaa <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101aaa:	55                   	push   %ebp
80101aab:	89 e5                	mov    %esp,%ebp
80101aad:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101ab0:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101ab7:	e8 9b 34 00 00       	call   80104f57 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101abc:	8b 45 08             	mov    0x8(%ebp),%eax
80101abf:	8b 40 08             	mov    0x8(%eax),%eax
80101ac2:	83 f8 01             	cmp    $0x1,%eax
80101ac5:	0f 85 93 00 00 00    	jne    80101b5e <iput+0xb4>
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	8b 40 0c             	mov    0xc(%eax),%eax
80101ad1:	83 e0 02             	and    $0x2,%eax
80101ad4:	85 c0                	test   %eax,%eax
80101ad6:	0f 84 82 00 00 00    	je     80101b5e <iput+0xb4>
80101adc:	8b 45 08             	mov    0x8(%ebp),%eax
80101adf:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101ae3:	66 85 c0             	test   %ax,%ax
80101ae6:	75 76                	jne    80101b5e <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101ae8:	8b 45 08             	mov    0x8(%ebp),%eax
80101aeb:	8b 40 0c             	mov    0xc(%eax),%eax
80101aee:	83 e0 01             	and    $0x1,%eax
80101af1:	84 c0                	test   %al,%al
80101af3:	74 0c                	je     80101b01 <iput+0x57>
      panic("iput busy");
80101af5:	c7 04 24 22 87 10 80 	movl   $0x80108722,(%esp)
80101afc:	e8 3c ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101b01:	8b 45 08             	mov    0x8(%ebp),%eax
80101b04:	8b 40 0c             	mov    0xc(%eax),%eax
80101b07:	89 c2                	mov    %eax,%edx
80101b09:	83 ca 01             	or     $0x1,%edx
80101b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0f:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b12:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b19:	e8 9b 34 00 00       	call   80104fb9 <release>
    itrunc(ip);
80101b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b21:	89 04 24             	mov    %eax,(%esp)
80101b24:	e8 72 01 00 00       	call   80101c9b <itrunc>
    ip->type = 0;
80101b29:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2c:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b32:	8b 45 08             	mov    0x8(%ebp),%eax
80101b35:	89 04 24             	mov    %eax,(%esp)
80101b38:	e8 f2 fb ff ff       	call   8010172f <iupdate>
    acquire(&icache.lock);
80101b3d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b44:	e8 0e 34 00 00       	call   80104f57 <acquire>
    ip->flags = 0;
80101b49:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b53:	8b 45 08             	mov    0x8(%ebp),%eax
80101b56:	89 04 24             	mov    %eax,(%esp)
80101b59:	e8 f4 31 00 00       	call   80104d52 <wakeup>
  }
  ip->ref--;
80101b5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b61:	8b 40 08             	mov    0x8(%eax),%eax
80101b64:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b67:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6a:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b6d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b74:	e8 40 34 00 00       	call   80104fb9 <release>
}
80101b79:	c9                   	leave  
80101b7a:	c3                   	ret    

80101b7b <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b7b:	55                   	push   %ebp
80101b7c:	89 e5                	mov    %esp,%ebp
80101b7e:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b81:	8b 45 08             	mov    0x8(%ebp),%eax
80101b84:	89 04 24             	mov    %eax,(%esp)
80101b87:	e8 b9 fe ff ff       	call   80101a45 <iunlock>
  iput(ip);
80101b8c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8f:	89 04 24             	mov    %eax,(%esp)
80101b92:	e8 13 ff ff ff       	call   80101aaa <iput>
}
80101b97:	c9                   	leave  
80101b98:	c3                   	ret    

80101b99 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b99:	55                   	push   %ebp
80101b9a:	89 e5                	mov    %esp,%ebp
80101b9c:	53                   	push   %ebx
80101b9d:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101ba0:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101ba4:	77 3e                	ja     80101be4 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101ba6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba9:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bac:	83 c2 04             	add    $0x4,%edx
80101baf:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101bb3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bba:	75 20                	jne    80101bdc <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bbf:	8b 00                	mov    (%eax),%eax
80101bc1:	89 04 24             	mov    %eax,(%esp)
80101bc4:	e8 e2 f7 ff ff       	call   801013ab <balloc>
80101bc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcf:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bd2:	8d 4a 04             	lea    0x4(%edx),%ecx
80101bd5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bd8:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101bdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bdf:	e9 b1 00 00 00       	jmp    80101c95 <bmap+0xfc>
  }
  bn -= NDIRECT;
80101be4:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101be8:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101bec:	0f 87 97 00 00 00    	ja     80101c89 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101bf2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf5:	8b 40 4c             	mov    0x4c(%eax),%eax
80101bf8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bfb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bff:	75 19                	jne    80101c1a <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c01:	8b 45 08             	mov    0x8(%ebp),%eax
80101c04:	8b 00                	mov    (%eax),%eax
80101c06:	89 04 24             	mov    %eax,(%esp)
80101c09:	e8 9d f7 ff ff       	call   801013ab <balloc>
80101c0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c17:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1d:	8b 00                	mov    (%eax),%eax
80101c1f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c22:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c26:	89 04 24             	mov    %eax,(%esp)
80101c29:	e8 78 e5 ff ff       	call   801001a6 <bread>
80101c2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c34:	83 c0 18             	add    $0x18,%eax
80101c37:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c3d:	c1 e0 02             	shl    $0x2,%eax
80101c40:	03 45 ec             	add    -0x14(%ebp),%eax
80101c43:	8b 00                	mov    (%eax),%eax
80101c45:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c48:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c4c:	75 2b                	jne    80101c79 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101c4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c51:	c1 e0 02             	shl    $0x2,%eax
80101c54:	89 c3                	mov    %eax,%ebx
80101c56:	03 5d ec             	add    -0x14(%ebp),%ebx
80101c59:	8b 45 08             	mov    0x8(%ebp),%eax
80101c5c:	8b 00                	mov    (%eax),%eax
80101c5e:	89 04 24             	mov    %eax,(%esp)
80101c61:	e8 45 f7 ff ff       	call   801013ab <balloc>
80101c66:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c6c:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c71:	89 04 24             	mov    %eax,(%esp)
80101c74:	e8 99 1a 00 00       	call   80103712 <log_write>
    }
    brelse(bp);
80101c79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c7c:	89 04 24             	mov    %eax,(%esp)
80101c7f:	e8 93 e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c87:	eb 0c                	jmp    80101c95 <bmap+0xfc>
  }

  panic("bmap: out of range");
80101c89:	c7 04 24 2c 87 10 80 	movl   $0x8010872c,(%esp)
80101c90:	e8 a8 e8 ff ff       	call   8010053d <panic>
}
80101c95:	83 c4 24             	add    $0x24,%esp
80101c98:	5b                   	pop    %ebx
80101c99:	5d                   	pop    %ebp
80101c9a:	c3                   	ret    

80101c9b <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c9b:	55                   	push   %ebp
80101c9c:	89 e5                	mov    %esp,%ebp
80101c9e:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101ca1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ca8:	eb 44                	jmp    80101cee <itrunc+0x53>
    if(ip->addrs[i]){
80101caa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cad:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cb0:	83 c2 04             	add    $0x4,%edx
80101cb3:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101cb7:	85 c0                	test   %eax,%eax
80101cb9:	74 2f                	je     80101cea <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cc1:	83 c2 04             	add    $0x4,%edx
80101cc4:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ccb:	8b 00                	mov    (%eax),%eax
80101ccd:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cd1:	89 04 24             	mov    %eax,(%esp)
80101cd4:	e8 19 f8 ff ff       	call   801014f2 <bfree>
      ip->addrs[i] = 0;
80101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cdc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cdf:	83 c2 04             	add    $0x4,%edx
80101ce2:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101ce9:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101cea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101cee:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101cf2:	7e b6                	jle    80101caa <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101cf4:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf7:	8b 40 4c             	mov    0x4c(%eax),%eax
80101cfa:	85 c0                	test   %eax,%eax
80101cfc:	0f 84 8f 00 00 00    	je     80101d91 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d08:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0b:	8b 00                	mov    (%eax),%eax
80101d0d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d11:	89 04 24             	mov    %eax,(%esp)
80101d14:	e8 8d e4 ff ff       	call   801001a6 <bread>
80101d19:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d1f:	83 c0 18             	add    $0x18,%eax
80101d22:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d25:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d2c:	eb 2f                	jmp    80101d5d <itrunc+0xc2>
      if(a[j])
80101d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d31:	c1 e0 02             	shl    $0x2,%eax
80101d34:	03 45 e8             	add    -0x18(%ebp),%eax
80101d37:	8b 00                	mov    (%eax),%eax
80101d39:	85 c0                	test   %eax,%eax
80101d3b:	74 1c                	je     80101d59 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101d3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d40:	c1 e0 02             	shl    $0x2,%eax
80101d43:	03 45 e8             	add    -0x18(%ebp),%eax
80101d46:	8b 10                	mov    (%eax),%edx
80101d48:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4b:	8b 00                	mov    (%eax),%eax
80101d4d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d51:	89 04 24             	mov    %eax,(%esp)
80101d54:	e8 99 f7 ff ff       	call   801014f2 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d59:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d60:	83 f8 7f             	cmp    $0x7f,%eax
80101d63:	76 c9                	jbe    80101d2e <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d65:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d68:	89 04 24             	mov    %eax,(%esp)
80101d6b:	e8 a7 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d70:	8b 45 08             	mov    0x8(%ebp),%eax
80101d73:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d76:	8b 45 08             	mov    0x8(%ebp),%eax
80101d79:	8b 00                	mov    (%eax),%eax
80101d7b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d7f:	89 04 24             	mov    %eax,(%esp)
80101d82:	e8 6b f7 ff ff       	call   801014f2 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d87:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8a:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d91:	8b 45 08             	mov    0x8(%ebp),%eax
80101d94:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9e:	89 04 24             	mov    %eax,(%esp)
80101da1:	e8 89 f9 ff ff       	call   8010172f <iupdate>
}
80101da6:	c9                   	leave  
80101da7:	c3                   	ret    

80101da8 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101da8:	55                   	push   %ebp
80101da9:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101dab:	8b 45 08             	mov    0x8(%ebp),%eax
80101dae:	8b 00                	mov    (%eax),%eax
80101db0:	89 c2                	mov    %eax,%edx
80101db2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101db5:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101db8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbb:	8b 50 04             	mov    0x4(%eax),%edx
80101dbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dc1:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc7:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101dcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dce:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101dd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd4:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ddb:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80101de2:	8b 50 18             	mov    0x18(%eax),%edx
80101de5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101de8:	89 50 10             	mov    %edx,0x10(%eax)
}
80101deb:	5d                   	pop    %ebp
80101dec:	c3                   	ret    

80101ded <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101ded:	55                   	push   %ebp
80101dee:	89 e5                	mov    %esp,%ebp
80101df0:	53                   	push   %ebx
80101df1:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101df4:	8b 45 08             	mov    0x8(%ebp),%eax
80101df7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101dfb:	66 83 f8 03          	cmp    $0x3,%ax
80101dff:	75 60                	jne    80101e61 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e01:	8b 45 08             	mov    0x8(%ebp),%eax
80101e04:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e08:	66 85 c0             	test   %ax,%ax
80101e0b:	78 20                	js     80101e2d <readi+0x40>
80101e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e10:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e14:	66 83 f8 09          	cmp    $0x9,%ax
80101e18:	7f 13                	jg     80101e2d <readi+0x40>
80101e1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e21:	98                   	cwtl   
80101e22:	8b 04 c5 c0 11 11 80 	mov    -0x7feeee40(,%eax,8),%eax
80101e29:	85 c0                	test   %eax,%eax
80101e2b:	75 0a                	jne    80101e37 <readi+0x4a>
      return -1;
80101e2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e32:	e9 1b 01 00 00       	jmp    80101f52 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101e37:	8b 45 08             	mov    0x8(%ebp),%eax
80101e3a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e3e:	98                   	cwtl   
80101e3f:	8b 14 c5 c0 11 11 80 	mov    -0x7feeee40(,%eax,8),%edx
80101e46:	8b 45 14             	mov    0x14(%ebp),%eax
80101e49:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e50:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e54:	8b 45 08             	mov    0x8(%ebp),%eax
80101e57:	89 04 24             	mov    %eax,(%esp)
80101e5a:	ff d2                	call   *%edx
80101e5c:	e9 f1 00 00 00       	jmp    80101f52 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101e61:	8b 45 08             	mov    0x8(%ebp),%eax
80101e64:	8b 40 18             	mov    0x18(%eax),%eax
80101e67:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e6a:	72 0d                	jb     80101e79 <readi+0x8c>
80101e6c:	8b 45 14             	mov    0x14(%ebp),%eax
80101e6f:	8b 55 10             	mov    0x10(%ebp),%edx
80101e72:	01 d0                	add    %edx,%eax
80101e74:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e77:	73 0a                	jae    80101e83 <readi+0x96>
    return -1;
80101e79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e7e:	e9 cf 00 00 00       	jmp    80101f52 <readi+0x165>
  if(off + n > ip->size)
80101e83:	8b 45 14             	mov    0x14(%ebp),%eax
80101e86:	8b 55 10             	mov    0x10(%ebp),%edx
80101e89:	01 c2                	add    %eax,%edx
80101e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8e:	8b 40 18             	mov    0x18(%eax),%eax
80101e91:	39 c2                	cmp    %eax,%edx
80101e93:	76 0c                	jbe    80101ea1 <readi+0xb4>
    n = ip->size - off;
80101e95:	8b 45 08             	mov    0x8(%ebp),%eax
80101e98:	8b 40 18             	mov    0x18(%eax),%eax
80101e9b:	2b 45 10             	sub    0x10(%ebp),%eax
80101e9e:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ea1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ea8:	e9 96 00 00 00       	jmp    80101f43 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101ead:	8b 45 10             	mov    0x10(%ebp),%eax
80101eb0:	c1 e8 09             	shr    $0x9,%eax
80101eb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eba:	89 04 24             	mov    %eax,(%esp)
80101ebd:	e8 d7 fc ff ff       	call   80101b99 <bmap>
80101ec2:	8b 55 08             	mov    0x8(%ebp),%edx
80101ec5:	8b 12                	mov    (%edx),%edx
80101ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ecb:	89 14 24             	mov    %edx,(%esp)
80101ece:	e8 d3 e2 ff ff       	call   801001a6 <bread>
80101ed3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101ed6:	8b 45 10             	mov    0x10(%ebp),%eax
80101ed9:	89 c2                	mov    %eax,%edx
80101edb:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101ee1:	b8 00 02 00 00       	mov    $0x200,%eax
80101ee6:	89 c1                	mov    %eax,%ecx
80101ee8:	29 d1                	sub    %edx,%ecx
80101eea:	89 ca                	mov    %ecx,%edx
80101eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eef:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ef2:	89 cb                	mov    %ecx,%ebx
80101ef4:	29 c3                	sub    %eax,%ebx
80101ef6:	89 d8                	mov    %ebx,%eax
80101ef8:	39 c2                	cmp    %eax,%edx
80101efa:	0f 46 c2             	cmovbe %edx,%eax
80101efd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f03:	8d 50 18             	lea    0x18(%eax),%edx
80101f06:	8b 45 10             	mov    0x10(%ebp),%eax
80101f09:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f0e:	01 c2                	add    %eax,%edx
80101f10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f13:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f17:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f1e:	89 04 24             	mov    %eax,(%esp)
80101f21:	e8 53 33 00 00       	call   80105279 <memmove>
    brelse(bp);
80101f26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f29:	89 04 24             	mov    %eax,(%esp)
80101f2c:	e8 e6 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f31:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f34:	01 45 f4             	add    %eax,-0xc(%ebp)
80101f37:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f3a:	01 45 10             	add    %eax,0x10(%ebp)
80101f3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f40:	01 45 0c             	add    %eax,0xc(%ebp)
80101f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f46:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f49:	0f 82 5e ff ff ff    	jb     80101ead <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f4f:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f52:	83 c4 24             	add    $0x24,%esp
80101f55:	5b                   	pop    %ebx
80101f56:	5d                   	pop    %ebp
80101f57:	c3                   	ret    

80101f58 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f58:	55                   	push   %ebp
80101f59:	89 e5                	mov    %esp,%ebp
80101f5b:	53                   	push   %ebx
80101f5c:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f5f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f62:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f66:	66 83 f8 03          	cmp    $0x3,%ax
80101f6a:	75 60                	jne    80101fcc <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f73:	66 85 c0             	test   %ax,%ax
80101f76:	78 20                	js     80101f98 <writei+0x40>
80101f78:	8b 45 08             	mov    0x8(%ebp),%eax
80101f7b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f7f:	66 83 f8 09          	cmp    $0x9,%ax
80101f83:	7f 13                	jg     80101f98 <writei+0x40>
80101f85:	8b 45 08             	mov    0x8(%ebp),%eax
80101f88:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f8c:	98                   	cwtl   
80101f8d:	8b 04 c5 c4 11 11 80 	mov    -0x7feeee3c(,%eax,8),%eax
80101f94:	85 c0                	test   %eax,%eax
80101f96:	75 0a                	jne    80101fa2 <writei+0x4a>
      return -1;
80101f98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f9d:	e9 46 01 00 00       	jmp    801020e8 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101fa2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa5:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fa9:	98                   	cwtl   
80101faa:	8b 14 c5 c4 11 11 80 	mov    -0x7feeee3c(,%eax,8),%edx
80101fb1:	8b 45 14             	mov    0x14(%ebp),%eax
80101fb4:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fbb:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fbf:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc2:	89 04 24             	mov    %eax,(%esp)
80101fc5:	ff d2                	call   *%edx
80101fc7:	e9 1c 01 00 00       	jmp    801020e8 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fcf:	8b 40 18             	mov    0x18(%eax),%eax
80101fd2:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fd5:	72 0d                	jb     80101fe4 <writei+0x8c>
80101fd7:	8b 45 14             	mov    0x14(%ebp),%eax
80101fda:	8b 55 10             	mov    0x10(%ebp),%edx
80101fdd:	01 d0                	add    %edx,%eax
80101fdf:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fe2:	73 0a                	jae    80101fee <writei+0x96>
    return -1;
80101fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fe9:	e9 fa 00 00 00       	jmp    801020e8 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101fee:	8b 45 14             	mov    0x14(%ebp),%eax
80101ff1:	8b 55 10             	mov    0x10(%ebp),%edx
80101ff4:	01 d0                	add    %edx,%eax
80101ff6:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101ffb:	76 0a                	jbe    80102007 <writei+0xaf>
    return -1;
80101ffd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102002:	e9 e1 00 00 00       	jmp    801020e8 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102007:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010200e:	e9 a1 00 00 00       	jmp    801020b4 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102013:	8b 45 10             	mov    0x10(%ebp),%eax
80102016:	c1 e8 09             	shr    $0x9,%eax
80102019:	89 44 24 04          	mov    %eax,0x4(%esp)
8010201d:	8b 45 08             	mov    0x8(%ebp),%eax
80102020:	89 04 24             	mov    %eax,(%esp)
80102023:	e8 71 fb ff ff       	call   80101b99 <bmap>
80102028:	8b 55 08             	mov    0x8(%ebp),%edx
8010202b:	8b 12                	mov    (%edx),%edx
8010202d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102031:	89 14 24             	mov    %edx,(%esp)
80102034:	e8 6d e1 ff ff       	call   801001a6 <bread>
80102039:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010203c:	8b 45 10             	mov    0x10(%ebp),%eax
8010203f:	89 c2                	mov    %eax,%edx
80102041:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102047:	b8 00 02 00 00       	mov    $0x200,%eax
8010204c:	89 c1                	mov    %eax,%ecx
8010204e:	29 d1                	sub    %edx,%ecx
80102050:	89 ca                	mov    %ecx,%edx
80102052:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102055:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102058:	89 cb                	mov    %ecx,%ebx
8010205a:	29 c3                	sub    %eax,%ebx
8010205c:	89 d8                	mov    %ebx,%eax
8010205e:	39 c2                	cmp    %eax,%edx
80102060:	0f 46 c2             	cmovbe %edx,%eax
80102063:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102066:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102069:	8d 50 18             	lea    0x18(%eax),%edx
8010206c:	8b 45 10             	mov    0x10(%ebp),%eax
8010206f:	25 ff 01 00 00       	and    $0x1ff,%eax
80102074:	01 c2                	add    %eax,%edx
80102076:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102079:	89 44 24 08          	mov    %eax,0x8(%esp)
8010207d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102080:	89 44 24 04          	mov    %eax,0x4(%esp)
80102084:	89 14 24             	mov    %edx,(%esp)
80102087:	e8 ed 31 00 00       	call   80105279 <memmove>
    log_write(bp);
8010208c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010208f:	89 04 24             	mov    %eax,(%esp)
80102092:	e8 7b 16 00 00       	call   80103712 <log_write>
    brelse(bp);
80102097:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010209a:	89 04 24             	mov    %eax,(%esp)
8010209d:	e8 75 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020a5:	01 45 f4             	add    %eax,-0xc(%ebp)
801020a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ab:	01 45 10             	add    %eax,0x10(%ebp)
801020ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020b1:	01 45 0c             	add    %eax,0xc(%ebp)
801020b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020b7:	3b 45 14             	cmp    0x14(%ebp),%eax
801020ba:	0f 82 53 ff ff ff    	jb     80102013 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801020c0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801020c4:	74 1f                	je     801020e5 <writei+0x18d>
801020c6:	8b 45 08             	mov    0x8(%ebp),%eax
801020c9:	8b 40 18             	mov    0x18(%eax),%eax
801020cc:	3b 45 10             	cmp    0x10(%ebp),%eax
801020cf:	73 14                	jae    801020e5 <writei+0x18d>
    ip->size = off;
801020d1:	8b 45 08             	mov    0x8(%ebp),%eax
801020d4:	8b 55 10             	mov    0x10(%ebp),%edx
801020d7:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801020da:	8b 45 08             	mov    0x8(%ebp),%eax
801020dd:	89 04 24             	mov    %eax,(%esp)
801020e0:	e8 4a f6 ff ff       	call   8010172f <iupdate>
  }
  return n;
801020e5:	8b 45 14             	mov    0x14(%ebp),%eax
}
801020e8:	83 c4 24             	add    $0x24,%esp
801020eb:	5b                   	pop    %ebx
801020ec:	5d                   	pop    %ebp
801020ed:	c3                   	ret    

801020ee <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801020ee:	55                   	push   %ebp
801020ef:	89 e5                	mov    %esp,%ebp
801020f1:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020f4:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020fb:	00 
801020fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801020ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80102103:	8b 45 08             	mov    0x8(%ebp),%eax
80102106:	89 04 24             	mov    %eax,(%esp)
80102109:	e8 0f 32 00 00       	call   8010531d <strncmp>
}
8010210e:	c9                   	leave  
8010210f:	c3                   	ret    

80102110 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102110:	55                   	push   %ebp
80102111:	89 e5                	mov    %esp,%ebp
80102113:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102116:	8b 45 08             	mov    0x8(%ebp),%eax
80102119:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010211d:	66 83 f8 01          	cmp    $0x1,%ax
80102121:	74 0c                	je     8010212f <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102123:	c7 04 24 3f 87 10 80 	movl   $0x8010873f,(%esp)
8010212a:	e8 0e e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010212f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102136:	e9 87 00 00 00       	jmp    801021c2 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010213b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102142:	00 
80102143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102146:	89 44 24 08          	mov    %eax,0x8(%esp)
8010214a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010214d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102151:	8b 45 08             	mov    0x8(%ebp),%eax
80102154:	89 04 24             	mov    %eax,(%esp)
80102157:	e8 91 fc ff ff       	call   80101ded <readi>
8010215c:	83 f8 10             	cmp    $0x10,%eax
8010215f:	74 0c                	je     8010216d <dirlookup+0x5d>
      panic("dirlink read");
80102161:	c7 04 24 51 87 10 80 	movl   $0x80108751,(%esp)
80102168:	e8 d0 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010216d:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102171:	66 85 c0             	test   %ax,%ax
80102174:	74 47                	je     801021bd <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102176:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102179:	83 c0 02             	add    $0x2,%eax
8010217c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102180:	8b 45 0c             	mov    0xc(%ebp),%eax
80102183:	89 04 24             	mov    %eax,(%esp)
80102186:	e8 63 ff ff ff       	call   801020ee <namecmp>
8010218b:	85 c0                	test   %eax,%eax
8010218d:	75 2f                	jne    801021be <dirlookup+0xae>
      // entry matches path element
      if(poff)
8010218f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102193:	74 08                	je     8010219d <dirlookup+0x8d>
        *poff = off;
80102195:	8b 45 10             	mov    0x10(%ebp),%eax
80102198:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010219b:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010219d:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021a1:	0f b7 c0             	movzwl %ax,%eax
801021a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801021a7:	8b 45 08             	mov    0x8(%ebp),%eax
801021aa:	8b 00                	mov    (%eax),%eax
801021ac:	8b 55 f0             	mov    -0x10(%ebp),%edx
801021af:	89 54 24 04          	mov    %edx,0x4(%esp)
801021b3:	89 04 24             	mov    %eax,(%esp)
801021b6:	e8 32 f6 ff ff       	call   801017ed <iget>
801021bb:	eb 19                	jmp    801021d6 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
801021bd:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801021be:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801021c2:	8b 45 08             	mov    0x8(%ebp),%eax
801021c5:	8b 40 18             	mov    0x18(%eax),%eax
801021c8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801021cb:	0f 87 6a ff ff ff    	ja     8010213b <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801021d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801021d6:	c9                   	leave  
801021d7:	c3                   	ret    

801021d8 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801021d8:	55                   	push   %ebp
801021d9:	89 e5                	mov    %esp,%ebp
801021db:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801021de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801021e5:	00 
801021e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801021e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ed:	8b 45 08             	mov    0x8(%ebp),%eax
801021f0:	89 04 24             	mov    %eax,(%esp)
801021f3:	e8 18 ff ff ff       	call   80102110 <dirlookup>
801021f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021ff:	74 15                	je     80102216 <dirlink+0x3e>
    iput(ip);
80102201:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102204:	89 04 24             	mov    %eax,(%esp)
80102207:	e8 9e f8 ff ff       	call   80101aaa <iput>
    return -1;
8010220c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102211:	e9 b8 00 00 00       	jmp    801022ce <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102216:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010221d:	eb 44                	jmp    80102263 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010221f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102222:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102229:	00 
8010222a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010222e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102231:	89 44 24 04          	mov    %eax,0x4(%esp)
80102235:	8b 45 08             	mov    0x8(%ebp),%eax
80102238:	89 04 24             	mov    %eax,(%esp)
8010223b:	e8 ad fb ff ff       	call   80101ded <readi>
80102240:	83 f8 10             	cmp    $0x10,%eax
80102243:	74 0c                	je     80102251 <dirlink+0x79>
      panic("dirlink read");
80102245:	c7 04 24 51 87 10 80 	movl   $0x80108751,(%esp)
8010224c:	e8 ec e2 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102251:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102255:	66 85 c0             	test   %ax,%ax
80102258:	74 18                	je     80102272 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010225a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010225d:	83 c0 10             	add    $0x10,%eax
80102260:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102263:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102266:	8b 45 08             	mov    0x8(%ebp),%eax
80102269:	8b 40 18             	mov    0x18(%eax),%eax
8010226c:	39 c2                	cmp    %eax,%edx
8010226e:	72 af                	jb     8010221f <dirlink+0x47>
80102270:	eb 01                	jmp    80102273 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102272:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102273:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010227a:	00 
8010227b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010227e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102282:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102285:	83 c0 02             	add    $0x2,%eax
80102288:	89 04 24             	mov    %eax,(%esp)
8010228b:	e8 e5 30 00 00       	call   80105375 <strncpy>
  de.inum = inum;
80102290:	8b 45 10             	mov    0x10(%ebp),%eax
80102293:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010229a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022a1:	00 
801022a2:	89 44 24 08          	mov    %eax,0x8(%esp)
801022a6:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ad:	8b 45 08             	mov    0x8(%ebp),%eax
801022b0:	89 04 24             	mov    %eax,(%esp)
801022b3:	e8 a0 fc ff ff       	call   80101f58 <writei>
801022b8:	83 f8 10             	cmp    $0x10,%eax
801022bb:	74 0c                	je     801022c9 <dirlink+0xf1>
    panic("dirlink");
801022bd:	c7 04 24 5e 87 10 80 	movl   $0x8010875e,(%esp)
801022c4:	e8 74 e2 ff ff       	call   8010053d <panic>
  
  return 0;
801022c9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022ce:	c9                   	leave  
801022cf:	c3                   	ret    

801022d0 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801022d0:	55                   	push   %ebp
801022d1:	89 e5                	mov    %esp,%ebp
801022d3:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801022d6:	eb 04                	jmp    801022dc <skipelem+0xc>
    path++;
801022d8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801022dc:	8b 45 08             	mov    0x8(%ebp),%eax
801022df:	0f b6 00             	movzbl (%eax),%eax
801022e2:	3c 2f                	cmp    $0x2f,%al
801022e4:	74 f2                	je     801022d8 <skipelem+0x8>
    path++;
  if(*path == 0)
801022e6:	8b 45 08             	mov    0x8(%ebp),%eax
801022e9:	0f b6 00             	movzbl (%eax),%eax
801022ec:	84 c0                	test   %al,%al
801022ee:	75 0a                	jne    801022fa <skipelem+0x2a>
    return 0;
801022f0:	b8 00 00 00 00       	mov    $0x0,%eax
801022f5:	e9 86 00 00 00       	jmp    80102380 <skipelem+0xb0>
  s = path;
801022fa:	8b 45 08             	mov    0x8(%ebp),%eax
801022fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102300:	eb 04                	jmp    80102306 <skipelem+0x36>
    path++;
80102302:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102306:	8b 45 08             	mov    0x8(%ebp),%eax
80102309:	0f b6 00             	movzbl (%eax),%eax
8010230c:	3c 2f                	cmp    $0x2f,%al
8010230e:	74 0a                	je     8010231a <skipelem+0x4a>
80102310:	8b 45 08             	mov    0x8(%ebp),%eax
80102313:	0f b6 00             	movzbl (%eax),%eax
80102316:	84 c0                	test   %al,%al
80102318:	75 e8                	jne    80102302 <skipelem+0x32>
    path++;
  len = path - s;
8010231a:	8b 55 08             	mov    0x8(%ebp),%edx
8010231d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102320:	89 d1                	mov    %edx,%ecx
80102322:	29 c1                	sub    %eax,%ecx
80102324:	89 c8                	mov    %ecx,%eax
80102326:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102329:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010232d:	7e 1c                	jle    8010234b <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
8010232f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102336:	00 
80102337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010233e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102341:	89 04 24             	mov    %eax,(%esp)
80102344:	e8 30 2f 00 00       	call   80105279 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102349:	eb 28                	jmp    80102373 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010234b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010234e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102355:	89 44 24 04          	mov    %eax,0x4(%esp)
80102359:	8b 45 0c             	mov    0xc(%ebp),%eax
8010235c:	89 04 24             	mov    %eax,(%esp)
8010235f:	e8 15 2f 00 00       	call   80105279 <memmove>
    name[len] = 0;
80102364:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102367:	03 45 0c             	add    0xc(%ebp),%eax
8010236a:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010236d:	eb 04                	jmp    80102373 <skipelem+0xa3>
    path++;
8010236f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102373:	8b 45 08             	mov    0x8(%ebp),%eax
80102376:	0f b6 00             	movzbl (%eax),%eax
80102379:	3c 2f                	cmp    $0x2f,%al
8010237b:	74 f2                	je     8010236f <skipelem+0x9f>
    path++;
  return path;
8010237d:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102380:	c9                   	leave  
80102381:	c3                   	ret    

80102382 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102382:	55                   	push   %ebp
80102383:	89 e5                	mov    %esp,%ebp
80102385:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102388:	8b 45 08             	mov    0x8(%ebp),%eax
8010238b:	0f b6 00             	movzbl (%eax),%eax
8010238e:	3c 2f                	cmp    $0x2f,%al
80102390:	75 1c                	jne    801023ae <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102392:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102399:	00 
8010239a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801023a1:	e8 47 f4 ff ff       	call   801017ed <iget>
801023a6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023a9:	e9 af 00 00 00       	jmp    8010245d <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801023ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801023b4:	8b 40 68             	mov    0x68(%eax),%eax
801023b7:	89 04 24             	mov    %eax,(%esp)
801023ba:	e8 00 f5 ff ff       	call   801018bf <idup>
801023bf:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801023c2:	e9 96 00 00 00       	jmp    8010245d <namex+0xdb>
    ilock(ip);
801023c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ca:	89 04 24             	mov    %eax,(%esp)
801023cd:	e8 1f f5 ff ff       	call   801018f1 <ilock>
    if(ip->type != T_DIR){
801023d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801023d9:	66 83 f8 01          	cmp    $0x1,%ax
801023dd:	74 15                	je     801023f4 <namex+0x72>
      iunlockput(ip);
801023df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023e2:	89 04 24             	mov    %eax,(%esp)
801023e5:	e8 91 f7 ff ff       	call   80101b7b <iunlockput>
      return 0;
801023ea:	b8 00 00 00 00       	mov    $0x0,%eax
801023ef:	e9 a3 00 00 00       	jmp    80102497 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801023f4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023f8:	74 1d                	je     80102417 <namex+0x95>
801023fa:	8b 45 08             	mov    0x8(%ebp),%eax
801023fd:	0f b6 00             	movzbl (%eax),%eax
80102400:	84 c0                	test   %al,%al
80102402:	75 13                	jne    80102417 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102404:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102407:	89 04 24             	mov    %eax,(%esp)
8010240a:	e8 36 f6 ff ff       	call   80101a45 <iunlock>
      return ip;
8010240f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102412:	e9 80 00 00 00       	jmp    80102497 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102417:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010241e:	00 
8010241f:	8b 45 10             	mov    0x10(%ebp),%eax
80102422:	89 44 24 04          	mov    %eax,0x4(%esp)
80102426:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102429:	89 04 24             	mov    %eax,(%esp)
8010242c:	e8 df fc ff ff       	call   80102110 <dirlookup>
80102431:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102434:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102438:	75 12                	jne    8010244c <namex+0xca>
      iunlockput(ip);
8010243a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010243d:	89 04 24             	mov    %eax,(%esp)
80102440:	e8 36 f7 ff ff       	call   80101b7b <iunlockput>
      return 0;
80102445:	b8 00 00 00 00       	mov    $0x0,%eax
8010244a:	eb 4b                	jmp    80102497 <namex+0x115>
    }
    iunlockput(ip);
8010244c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244f:	89 04 24             	mov    %eax,(%esp)
80102452:	e8 24 f7 ff ff       	call   80101b7b <iunlockput>
    ip = next;
80102457:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010245a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010245d:	8b 45 10             	mov    0x10(%ebp),%eax
80102460:	89 44 24 04          	mov    %eax,0x4(%esp)
80102464:	8b 45 08             	mov    0x8(%ebp),%eax
80102467:	89 04 24             	mov    %eax,(%esp)
8010246a:	e8 61 fe ff ff       	call   801022d0 <skipelem>
8010246f:	89 45 08             	mov    %eax,0x8(%ebp)
80102472:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102476:	0f 85 4b ff ff ff    	jne    801023c7 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010247c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102480:	74 12                	je     80102494 <namex+0x112>
    iput(ip);
80102482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102485:	89 04 24             	mov    %eax,(%esp)
80102488:	e8 1d f6 ff ff       	call   80101aaa <iput>
    return 0;
8010248d:	b8 00 00 00 00       	mov    $0x0,%eax
80102492:	eb 03                	jmp    80102497 <namex+0x115>
  }
  return ip;
80102494:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102497:	c9                   	leave  
80102498:	c3                   	ret    

80102499 <namei>:

struct inode*
namei(char *path)
{
80102499:	55                   	push   %ebp
8010249a:	89 e5                	mov    %esp,%ebp
8010249c:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010249f:	8d 45 ea             	lea    -0x16(%ebp),%eax
801024a2:	89 44 24 08          	mov    %eax,0x8(%esp)
801024a6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801024ad:	00 
801024ae:	8b 45 08             	mov    0x8(%ebp),%eax
801024b1:	89 04 24             	mov    %eax,(%esp)
801024b4:	e8 c9 fe ff ff       	call   80102382 <namex>
}
801024b9:	c9                   	leave  
801024ba:	c3                   	ret    

801024bb <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801024bb:	55                   	push   %ebp
801024bc:	89 e5                	mov    %esp,%ebp
801024be:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801024c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801024c4:	89 44 24 08          	mov    %eax,0x8(%esp)
801024c8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024cf:	00 
801024d0:	8b 45 08             	mov    0x8(%ebp),%eax
801024d3:	89 04 24             	mov    %eax,(%esp)
801024d6:	e8 a7 fe ff ff       	call   80102382 <namex>
}
801024db:	c9                   	leave  
801024dc:	c3                   	ret    
801024dd:	00 00                	add    %al,(%eax)
	...

801024e0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801024e0:	55                   	push   %ebp
801024e1:	89 e5                	mov    %esp,%ebp
801024e3:	53                   	push   %ebx
801024e4:	83 ec 14             	sub    $0x14,%esp
801024e7:	8b 45 08             	mov    0x8(%ebp),%eax
801024ea:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024ee:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801024f2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801024f6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801024fa:	ec                   	in     (%dx),%al
801024fb:	89 c3                	mov    %eax,%ebx
801024fd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102500:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102504:	83 c4 14             	add    $0x14,%esp
80102507:	5b                   	pop    %ebx
80102508:	5d                   	pop    %ebp
80102509:	c3                   	ret    

8010250a <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010250a:	55                   	push   %ebp
8010250b:	89 e5                	mov    %esp,%ebp
8010250d:	57                   	push   %edi
8010250e:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010250f:	8b 55 08             	mov    0x8(%ebp),%edx
80102512:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102515:	8b 45 10             	mov    0x10(%ebp),%eax
80102518:	89 cb                	mov    %ecx,%ebx
8010251a:	89 df                	mov    %ebx,%edi
8010251c:	89 c1                	mov    %eax,%ecx
8010251e:	fc                   	cld    
8010251f:	f3 6d                	rep insl (%dx),%es:(%edi)
80102521:	89 c8                	mov    %ecx,%eax
80102523:	89 fb                	mov    %edi,%ebx
80102525:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102528:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010252b:	5b                   	pop    %ebx
8010252c:	5f                   	pop    %edi
8010252d:	5d                   	pop    %ebp
8010252e:	c3                   	ret    

8010252f <outb>:

static inline void
outb(ushort port, uchar data)
{
8010252f:	55                   	push   %ebp
80102530:	89 e5                	mov    %esp,%ebp
80102532:	83 ec 08             	sub    $0x8,%esp
80102535:	8b 55 08             	mov    0x8(%ebp),%edx
80102538:	8b 45 0c             	mov    0xc(%ebp),%eax
8010253b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010253f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102542:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102546:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010254a:	ee                   	out    %al,(%dx)
}
8010254b:	c9                   	leave  
8010254c:	c3                   	ret    

8010254d <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
8010254d:	55                   	push   %ebp
8010254e:	89 e5                	mov    %esp,%ebp
80102550:	56                   	push   %esi
80102551:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102552:	8b 55 08             	mov    0x8(%ebp),%edx
80102555:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102558:	8b 45 10             	mov    0x10(%ebp),%eax
8010255b:	89 cb                	mov    %ecx,%ebx
8010255d:	89 de                	mov    %ebx,%esi
8010255f:	89 c1                	mov    %eax,%ecx
80102561:	fc                   	cld    
80102562:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102564:	89 c8                	mov    %ecx,%eax
80102566:	89 f3                	mov    %esi,%ebx
80102568:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010256b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010256e:	5b                   	pop    %ebx
8010256f:	5e                   	pop    %esi
80102570:	5d                   	pop    %ebp
80102571:	c3                   	ret    

80102572 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102572:	55                   	push   %ebp
80102573:	89 e5                	mov    %esp,%ebp
80102575:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102578:	90                   	nop
80102579:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102580:	e8 5b ff ff ff       	call   801024e0 <inb>
80102585:	0f b6 c0             	movzbl %al,%eax
80102588:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010258b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010258e:	25 c0 00 00 00       	and    $0xc0,%eax
80102593:	83 f8 40             	cmp    $0x40,%eax
80102596:	75 e1                	jne    80102579 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102598:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010259c:	74 11                	je     801025af <idewait+0x3d>
8010259e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801025a1:	83 e0 21             	and    $0x21,%eax
801025a4:	85 c0                	test   %eax,%eax
801025a6:	74 07                	je     801025af <idewait+0x3d>
    return -1;
801025a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025ad:	eb 05                	jmp    801025b4 <idewait+0x42>
  return 0;
801025af:	b8 00 00 00 00       	mov    $0x0,%eax
}
801025b4:	c9                   	leave  
801025b5:	c3                   	ret    

801025b6 <ideinit>:

void
ideinit(void)
{
801025b6:	55                   	push   %ebp
801025b7:	89 e5                	mov    %esp,%ebp
801025b9:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
801025bc:	c7 44 24 04 66 87 10 	movl   $0x80108766,0x4(%esp)
801025c3:	80 
801025c4:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801025cb:	e8 66 29 00 00       	call   80104f36 <initlock>
  picenable(IRQ_IDE);
801025d0:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025d7:	e8 e5 18 00 00       	call   80103ec1 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801025dc:	a1 40 29 11 80       	mov    0x80112940,%eax
801025e1:	83 e8 01             	sub    $0x1,%eax
801025e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801025e8:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025ef:	e8 46 04 00 00       	call   80102a3a <ioapicenable>
  idewait(0);
801025f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025fb:	e8 72 ff ff ff       	call   80102572 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102600:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102607:	00 
80102608:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010260f:	e8 1b ff ff ff       	call   8010252f <outb>
  for(i=0; i<1000; i++){
80102614:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010261b:	eb 20                	jmp    8010263d <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010261d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102624:	e8 b7 fe ff ff       	call   801024e0 <inb>
80102629:	84 c0                	test   %al,%al
8010262b:	74 0c                	je     80102639 <ideinit+0x83>
      havedisk1 = 1;
8010262d:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102634:	00 00 00 
      break;
80102637:	eb 0d                	jmp    80102646 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102639:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010263d:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102644:	7e d7                	jle    8010261d <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102646:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
8010264d:	00 
8010264e:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102655:	e8 d5 fe ff ff       	call   8010252f <outb>
}
8010265a:	c9                   	leave  
8010265b:	c3                   	ret    

8010265c <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010265c:	55                   	push   %ebp
8010265d:	89 e5                	mov    %esp,%ebp
8010265f:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102662:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102666:	75 0c                	jne    80102674 <idestart+0x18>
    panic("idestart");
80102668:	c7 04 24 6a 87 10 80 	movl   $0x8010876a,(%esp)
8010266f:	e8 c9 de ff ff       	call   8010053d <panic>
  if(b->blockno >= FSSIZE)
80102674:	8b 45 08             	mov    0x8(%ebp),%eax
80102677:	8b 40 08             	mov    0x8(%eax),%eax
8010267a:	3d e7 03 00 00       	cmp    $0x3e7,%eax
8010267f:	76 0c                	jbe    8010268d <idestart+0x31>
    panic("incorrect blockno");
80102681:	c7 04 24 73 87 10 80 	movl   $0x80108773,(%esp)
80102688:	e8 b0 de ff ff       	call   8010053d <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
8010268d:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102694:	8b 45 08             	mov    0x8(%ebp),%eax
80102697:	8b 50 08             	mov    0x8(%eax),%edx
8010269a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010269d:	0f af c2             	imul   %edx,%eax
801026a0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
801026a3:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
801026a7:	7e 0c                	jle    801026b5 <idestart+0x59>
801026a9:	c7 04 24 6a 87 10 80 	movl   $0x8010876a,(%esp)
801026b0:	e8 88 de ff ff       	call   8010053d <panic>
  
  idewait(0);
801026b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026bc:	e8 b1 fe ff ff       	call   80102572 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801026c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026c8:	00 
801026c9:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801026d0:	e8 5a fe ff ff       	call   8010252f <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
801026d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026d8:	0f b6 c0             	movzbl %al,%eax
801026db:	89 44 24 04          	mov    %eax,0x4(%esp)
801026df:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801026e6:	e8 44 fe ff ff       	call   8010252f <outb>
  outb(0x1f3, sector & 0xff);
801026eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026ee:	0f b6 c0             	movzbl %al,%eax
801026f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801026f5:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801026fc:	e8 2e fe ff ff       	call   8010252f <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102704:	c1 f8 08             	sar    $0x8,%eax
80102707:	0f b6 c0             	movzbl %al,%eax
8010270a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010270e:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102715:	e8 15 fe ff ff       	call   8010252f <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
8010271a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010271d:	c1 f8 10             	sar    $0x10,%eax
80102720:	0f b6 c0             	movzbl %al,%eax
80102723:	89 44 24 04          	mov    %eax,0x4(%esp)
80102727:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010272e:	e8 fc fd ff ff       	call   8010252f <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102733:	8b 45 08             	mov    0x8(%ebp),%eax
80102736:	8b 40 04             	mov    0x4(%eax),%eax
80102739:	83 e0 01             	and    $0x1,%eax
8010273c:	89 c2                	mov    %eax,%edx
8010273e:	c1 e2 04             	shl    $0x4,%edx
80102741:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102744:	c1 f8 18             	sar    $0x18,%eax
80102747:	83 e0 0f             	and    $0xf,%eax
8010274a:	09 d0                	or     %edx,%eax
8010274c:	83 c8 e0             	or     $0xffffffe0,%eax
8010274f:	0f b6 c0             	movzbl %al,%eax
80102752:	89 44 24 04          	mov    %eax,0x4(%esp)
80102756:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010275d:	e8 cd fd ff ff       	call   8010252f <outb>
  if(b->flags & B_DIRTY){
80102762:	8b 45 08             	mov    0x8(%ebp),%eax
80102765:	8b 00                	mov    (%eax),%eax
80102767:	83 e0 04             	and    $0x4,%eax
8010276a:	85 c0                	test   %eax,%eax
8010276c:	74 34                	je     801027a2 <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
8010276e:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102775:	00 
80102776:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010277d:	e8 ad fd ff ff       	call   8010252f <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102782:	8b 45 08             	mov    0x8(%ebp),%eax
80102785:	83 c0 18             	add    $0x18,%eax
80102788:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010278f:	00 
80102790:	89 44 24 04          	mov    %eax,0x4(%esp)
80102794:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010279b:	e8 ad fd ff ff       	call   8010254d <outsl>
801027a0:	eb 14                	jmp    801027b6 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801027a2:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801027a9:	00 
801027aa:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027b1:	e8 79 fd ff ff       	call   8010252f <outb>
  }
}
801027b6:	c9                   	leave  
801027b7:	c3                   	ret    

801027b8 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801027b8:	55                   	push   %ebp
801027b9:	89 e5                	mov    %esp,%ebp
801027bb:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801027be:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027c5:	e8 8d 27 00 00       	call   80104f57 <acquire>
  if((b = idequeue) == 0){
801027ca:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
801027d2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801027d6:	75 11                	jne    801027e9 <ideintr+0x31>
    release(&idelock);
801027d8:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027df:	e8 d5 27 00 00       	call   80104fb9 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801027e4:	e9 90 00 00 00       	jmp    80102879 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801027e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027ec:	8b 40 14             	mov    0x14(%eax),%eax
801027ef:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801027f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027f7:	8b 00                	mov    (%eax),%eax
801027f9:	83 e0 04             	and    $0x4,%eax
801027fc:	85 c0                	test   %eax,%eax
801027fe:	75 2e                	jne    8010282e <ideintr+0x76>
80102800:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102807:	e8 66 fd ff ff       	call   80102572 <idewait>
8010280c:	85 c0                	test   %eax,%eax
8010280e:	78 1e                	js     8010282e <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102813:	83 c0 18             	add    $0x18,%eax
80102816:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010281d:	00 
8010281e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102822:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102829:	e8 dc fc ff ff       	call   8010250a <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010282e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102831:	8b 00                	mov    (%eax),%eax
80102833:	89 c2                	mov    %eax,%edx
80102835:	83 ca 02             	or     $0x2,%edx
80102838:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010283b:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010283d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102840:	8b 00                	mov    (%eax),%eax
80102842:	89 c2                	mov    %eax,%edx
80102844:	83 e2 fb             	and    $0xfffffffb,%edx
80102847:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010284a:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010284c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010284f:	89 04 24             	mov    %eax,(%esp)
80102852:	e8 fb 24 00 00       	call   80104d52 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102857:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010285c:	85 c0                	test   %eax,%eax
8010285e:	74 0d                	je     8010286d <ideintr+0xb5>
    idestart(idequeue);
80102860:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102865:	89 04 24             	mov    %eax,(%esp)
80102868:	e8 ef fd ff ff       	call   8010265c <idestart>

  release(&idelock);
8010286d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102874:	e8 40 27 00 00       	call   80104fb9 <release>
}
80102879:	c9                   	leave  
8010287a:	c3                   	ret    

8010287b <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010287b:	55                   	push   %ebp
8010287c:	89 e5                	mov    %esp,%ebp
8010287e:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102881:	8b 45 08             	mov    0x8(%ebp),%eax
80102884:	8b 00                	mov    (%eax),%eax
80102886:	83 e0 01             	and    $0x1,%eax
80102889:	85 c0                	test   %eax,%eax
8010288b:	75 0c                	jne    80102899 <iderw+0x1e>
    panic("iderw: buf not busy");
8010288d:	c7 04 24 85 87 10 80 	movl   $0x80108785,(%esp)
80102894:	e8 a4 dc ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102899:	8b 45 08             	mov    0x8(%ebp),%eax
8010289c:	8b 00                	mov    (%eax),%eax
8010289e:	83 e0 06             	and    $0x6,%eax
801028a1:	83 f8 02             	cmp    $0x2,%eax
801028a4:	75 0c                	jne    801028b2 <iderw+0x37>
    panic("iderw: nothing to do");
801028a6:	c7 04 24 99 87 10 80 	movl   $0x80108799,(%esp)
801028ad:	e8 8b dc ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801028b2:	8b 45 08             	mov    0x8(%ebp),%eax
801028b5:	8b 40 04             	mov    0x4(%eax),%eax
801028b8:	85 c0                	test   %eax,%eax
801028ba:	74 15                	je     801028d1 <iderw+0x56>
801028bc:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801028c1:	85 c0                	test   %eax,%eax
801028c3:	75 0c                	jne    801028d1 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801028c5:	c7 04 24 ae 87 10 80 	movl   $0x801087ae,(%esp)
801028cc:	e8 6c dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC:acquire-lock
801028d1:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028d8:	e8 7a 26 00 00       	call   80104f57 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801028dd:	8b 45 08             	mov    0x8(%ebp),%eax
801028e0:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801028e7:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
801028ee:	eb 0b                	jmp    801028fb <iderw+0x80>
801028f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028f3:	8b 00                	mov    (%eax),%eax
801028f5:	83 c0 14             	add    $0x14,%eax
801028f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028fe:	8b 00                	mov    (%eax),%eax
80102900:	85 c0                	test   %eax,%eax
80102902:	75 ec                	jne    801028f0 <iderw+0x75>
    ;
  *pp = b;
80102904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102907:	8b 55 08             	mov    0x8(%ebp),%edx
8010290a:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010290c:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102911:	3b 45 08             	cmp    0x8(%ebp),%eax
80102914:	75 22                	jne    80102938 <iderw+0xbd>
    idestart(b);
80102916:	8b 45 08             	mov    0x8(%ebp),%eax
80102919:	89 04 24             	mov    %eax,(%esp)
8010291c:	e8 3b fd ff ff       	call   8010265c <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102921:	eb 15                	jmp    80102938 <iderw+0xbd>
    sleep(b, &idelock);
80102923:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010292a:	80 
8010292b:	8b 45 08             	mov    0x8(%ebp),%eax
8010292e:	89 04 24             	mov    %eax,(%esp)
80102931:	e8 43 23 00 00       	call   80104c79 <sleep>
80102936:	eb 01                	jmp    80102939 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102938:	90                   	nop
80102939:	8b 45 08             	mov    0x8(%ebp),%eax
8010293c:	8b 00                	mov    (%eax),%eax
8010293e:	83 e0 06             	and    $0x6,%eax
80102941:	83 f8 02             	cmp    $0x2,%eax
80102944:	75 dd                	jne    80102923 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102946:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010294d:	e8 67 26 00 00       	call   80104fb9 <release>
}
80102952:	c9                   	leave  
80102953:	c3                   	ret    

80102954 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102954:	55                   	push   %ebp
80102955:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102957:	a1 14 22 11 80       	mov    0x80112214,%eax
8010295c:	8b 55 08             	mov    0x8(%ebp),%edx
8010295f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102961:	a1 14 22 11 80       	mov    0x80112214,%eax
80102966:	8b 40 10             	mov    0x10(%eax),%eax
}
80102969:	5d                   	pop    %ebp
8010296a:	c3                   	ret    

8010296b <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010296b:	55                   	push   %ebp
8010296c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010296e:	a1 14 22 11 80       	mov    0x80112214,%eax
80102973:	8b 55 08             	mov    0x8(%ebp),%edx
80102976:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102978:	a1 14 22 11 80       	mov    0x80112214,%eax
8010297d:	8b 55 0c             	mov    0xc(%ebp),%edx
80102980:	89 50 10             	mov    %edx,0x10(%eax)
}
80102983:	5d                   	pop    %ebp
80102984:	c3                   	ret    

80102985 <ioapicinit>:

void
ioapicinit(void)
{
80102985:	55                   	push   %ebp
80102986:	89 e5                	mov    %esp,%ebp
80102988:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010298b:	a1 44 23 11 80       	mov    0x80112344,%eax
80102990:	85 c0                	test   %eax,%eax
80102992:	0f 84 9f 00 00 00    	je     80102a37 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102998:	c7 05 14 22 11 80 00 	movl   $0xfec00000,0x80112214
8010299f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801029a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029a9:	e8 a6 ff ff ff       	call   80102954 <ioapicread>
801029ae:	c1 e8 10             	shr    $0x10,%eax
801029b1:	25 ff 00 00 00       	and    $0xff,%eax
801029b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801029b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801029c0:	e8 8f ff ff ff       	call   80102954 <ioapicread>
801029c5:	c1 e8 18             	shr    $0x18,%eax
801029c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801029cb:	0f b6 05 40 23 11 80 	movzbl 0x80112340,%eax
801029d2:	0f b6 c0             	movzbl %al,%eax
801029d5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801029d8:	74 0c                	je     801029e6 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801029da:	c7 04 24 cc 87 10 80 	movl   $0x801087cc,(%esp)
801029e1:	e8 bb d9 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029ed:	eb 3e                	jmp    80102a2d <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801029ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f2:	83 c0 20             	add    $0x20,%eax
801029f5:	0d 00 00 01 00       	or     $0x10000,%eax
801029fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029fd:	83 c2 08             	add    $0x8,%edx
80102a00:	01 d2                	add    %edx,%edx
80102a02:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a06:	89 14 24             	mov    %edx,(%esp)
80102a09:	e8 5d ff ff ff       	call   8010296b <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a11:	83 c0 08             	add    $0x8,%eax
80102a14:	01 c0                	add    %eax,%eax
80102a16:	83 c0 01             	add    $0x1,%eax
80102a19:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a20:	00 
80102a21:	89 04 24             	mov    %eax,(%esp)
80102a24:	e8 42 ff ff ff       	call   8010296b <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a29:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a30:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102a33:	7e ba                	jle    801029ef <ioapicinit+0x6a>
80102a35:	eb 01                	jmp    80102a38 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102a37:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102a38:	c9                   	leave  
80102a39:	c3                   	ret    

80102a3a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102a3a:	55                   	push   %ebp
80102a3b:	89 e5                	mov    %esp,%ebp
80102a3d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102a40:	a1 44 23 11 80       	mov    0x80112344,%eax
80102a45:	85 c0                	test   %eax,%eax
80102a47:	74 39                	je     80102a82 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102a49:	8b 45 08             	mov    0x8(%ebp),%eax
80102a4c:	83 c0 20             	add    $0x20,%eax
80102a4f:	8b 55 08             	mov    0x8(%ebp),%edx
80102a52:	83 c2 08             	add    $0x8,%edx
80102a55:	01 d2                	add    %edx,%edx
80102a57:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a5b:	89 14 24             	mov    %edx,(%esp)
80102a5e:	e8 08 ff ff ff       	call   8010296b <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102a63:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a66:	c1 e0 18             	shl    $0x18,%eax
80102a69:	8b 55 08             	mov    0x8(%ebp),%edx
80102a6c:	83 c2 08             	add    $0x8,%edx
80102a6f:	01 d2                	add    %edx,%edx
80102a71:	83 c2 01             	add    $0x1,%edx
80102a74:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a78:	89 14 24             	mov    %edx,(%esp)
80102a7b:	e8 eb fe ff ff       	call   8010296b <ioapicwrite>
80102a80:	eb 01                	jmp    80102a83 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102a82:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102a83:	c9                   	leave  
80102a84:	c3                   	ret    
80102a85:	00 00                	add    %al,(%eax)
	...

80102a88 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a88:	55                   	push   %ebp
80102a89:	89 e5                	mov    %esp,%ebp
80102a8b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a8e:	05 00 00 00 80       	add    $0x80000000,%eax
80102a93:	5d                   	pop    %ebp
80102a94:	c3                   	ret    

80102a95 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a95:	55                   	push   %ebp
80102a96:	89 e5                	mov    %esp,%ebp
80102a98:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a9b:	c7 44 24 04 fe 87 10 	movl   $0x801087fe,0x4(%esp)
80102aa2:	80 
80102aa3:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102aaa:	e8 87 24 00 00       	call   80104f36 <initlock>
  kmem.use_lock = 0;
80102aaf:	c7 05 54 22 11 80 00 	movl   $0x0,0x80112254
80102ab6:	00 00 00 
  freerange(vstart, vend);
80102ab9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102abc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 26 00 00 00       	call   80102af1 <freerange>
}
80102acb:	c9                   	leave  
80102acc:	c3                   	ret    

80102acd <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102acd:	55                   	push   %ebp
80102ace:	89 e5                	mov    %esp,%ebp
80102ad0:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102ad3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ad6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ada:	8b 45 08             	mov    0x8(%ebp),%eax
80102add:	89 04 24             	mov    %eax,(%esp)
80102ae0:	e8 0c 00 00 00       	call   80102af1 <freerange>
  kmem.use_lock = 1;
80102ae5:	c7 05 54 22 11 80 01 	movl   $0x1,0x80112254
80102aec:	00 00 00 
}
80102aef:	c9                   	leave  
80102af0:	c3                   	ret    

80102af1 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102af1:	55                   	push   %ebp
80102af2:	89 e5                	mov    %esp,%ebp
80102af4:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102af7:	8b 45 08             	mov    0x8(%ebp),%eax
80102afa:	05 ff 0f 00 00       	add    $0xfff,%eax
80102aff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102b04:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b07:	eb 12                	jmp    80102b1b <freerange+0x2a>
    kfree(p);
80102b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b0c:	89 04 24             	mov    %eax,(%esp)
80102b0f:	e8 16 00 00 00       	call   80102b2a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b14:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1e:	05 00 10 00 00       	add    $0x1000,%eax
80102b23:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b26:	76 e1                	jbe    80102b09 <freerange+0x18>
    kfree(p);
}
80102b28:	c9                   	leave  
80102b29:	c3                   	ret    

80102b2a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b2a:	55                   	push   %ebp
80102b2b:	89 e5                	mov    %esp,%ebp
80102b2d:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102b30:	8b 45 08             	mov    0x8(%ebp),%eax
80102b33:	25 ff 0f 00 00       	and    $0xfff,%eax
80102b38:	85 c0                	test   %eax,%eax
80102b3a:	75 1b                	jne    80102b57 <kfree+0x2d>
80102b3c:	81 7d 08 3c 51 11 80 	cmpl   $0x8011513c,0x8(%ebp)
80102b43:	72 12                	jb     80102b57 <kfree+0x2d>
80102b45:	8b 45 08             	mov    0x8(%ebp),%eax
80102b48:	89 04 24             	mov    %eax,(%esp)
80102b4b:	e8 38 ff ff ff       	call   80102a88 <v2p>
80102b50:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102b55:	76 0c                	jbe    80102b63 <kfree+0x39>
    panic("kfree");
80102b57:	c7 04 24 03 88 10 80 	movl   $0x80108803,(%esp)
80102b5e:	e8 da d9 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102b63:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102b6a:	00 
80102b6b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102b72:	00 
80102b73:	8b 45 08             	mov    0x8(%ebp),%eax
80102b76:	89 04 24             	mov    %eax,(%esp)
80102b79:	e8 28 26 00 00       	call   801051a6 <memset>

  if(kmem.use_lock)
80102b7e:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b83:	85 c0                	test   %eax,%eax
80102b85:	74 0c                	je     80102b93 <kfree+0x69>
    acquire(&kmem.lock);
80102b87:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b8e:	e8 c4 23 00 00       	call   80104f57 <acquire>
  r = (struct run*)v;
80102b93:	8b 45 08             	mov    0x8(%ebp),%eax
80102b96:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b99:	8b 15 58 22 11 80    	mov    0x80112258,%edx
80102b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ba2:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102ba4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ba7:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102bac:	a1 54 22 11 80       	mov    0x80112254,%eax
80102bb1:	85 c0                	test   %eax,%eax
80102bb3:	74 0c                	je     80102bc1 <kfree+0x97>
    release(&kmem.lock);
80102bb5:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102bbc:	e8 f8 23 00 00       	call   80104fb9 <release>
}
80102bc1:	c9                   	leave  
80102bc2:	c3                   	ret    

80102bc3 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102bc3:	55                   	push   %ebp
80102bc4:	89 e5                	mov    %esp,%ebp
80102bc6:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102bc9:	a1 54 22 11 80       	mov    0x80112254,%eax
80102bce:	85 c0                	test   %eax,%eax
80102bd0:	74 0c                	je     80102bde <kalloc+0x1b>
    acquire(&kmem.lock);
80102bd2:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102bd9:	e8 79 23 00 00       	call   80104f57 <acquire>
  r = kmem.freelist;
80102bde:	a1 58 22 11 80       	mov    0x80112258,%eax
80102be3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102be6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102bea:	74 0a                	je     80102bf6 <kalloc+0x33>
    kmem.freelist = r->next;
80102bec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bef:	8b 00                	mov    (%eax),%eax
80102bf1:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102bf6:	a1 54 22 11 80       	mov    0x80112254,%eax
80102bfb:	85 c0                	test   %eax,%eax
80102bfd:	74 0c                	je     80102c0b <kalloc+0x48>
    release(&kmem.lock);
80102bff:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102c06:	e8 ae 23 00 00       	call   80104fb9 <release>
  return (char*)r;
80102c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c0e:	c9                   	leave  
80102c0f:	c3                   	ret    

80102c10 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c10:	55                   	push   %ebp
80102c11:	89 e5                	mov    %esp,%ebp
80102c13:	53                   	push   %ebx
80102c14:	83 ec 14             	sub    $0x14,%esp
80102c17:	8b 45 08             	mov    0x8(%ebp),%eax
80102c1a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c1e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102c22:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102c26:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102c2a:	ec                   	in     (%dx),%al
80102c2b:	89 c3                	mov    %eax,%ebx
80102c2d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102c30:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102c34:	83 c4 14             	add    $0x14,%esp
80102c37:	5b                   	pop    %ebx
80102c38:	5d                   	pop    %ebp
80102c39:	c3                   	ret    

80102c3a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c3a:	55                   	push   %ebp
80102c3b:	89 e5                	mov    %esp,%ebp
80102c3d:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c40:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102c47:	e8 c4 ff ff ff       	call   80102c10 <inb>
80102c4c:	0f b6 c0             	movzbl %al,%eax
80102c4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c55:	83 e0 01             	and    $0x1,%eax
80102c58:	85 c0                	test   %eax,%eax
80102c5a:	75 0a                	jne    80102c66 <kbdgetc+0x2c>
    return -1;
80102c5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c61:	e9 23 01 00 00       	jmp    80102d89 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102c66:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102c6d:	e8 9e ff ff ff       	call   80102c10 <inb>
80102c72:	0f b6 c0             	movzbl %al,%eax
80102c75:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102c78:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102c7f:	75 17                	jne    80102c98 <kbdgetc+0x5e>
    shift |= E0ESC;
80102c81:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c86:	83 c8 40             	or     $0x40,%eax
80102c89:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c8e:	b8 00 00 00 00       	mov    $0x0,%eax
80102c93:	e9 f1 00 00 00       	jmp    80102d89 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102c98:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c9b:	25 80 00 00 00       	and    $0x80,%eax
80102ca0:	85 c0                	test   %eax,%eax
80102ca2:	74 45                	je     80102ce9 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102ca4:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ca9:	83 e0 40             	and    $0x40,%eax
80102cac:	85 c0                	test   %eax,%eax
80102cae:	75 08                	jne    80102cb8 <kbdgetc+0x7e>
80102cb0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cb3:	83 e0 7f             	and    $0x7f,%eax
80102cb6:	eb 03                	jmp    80102cbb <kbdgetc+0x81>
80102cb8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cbb:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102cbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cc1:	05 20 90 10 80       	add    $0x80109020,%eax
80102cc6:	0f b6 00             	movzbl (%eax),%eax
80102cc9:	83 c8 40             	or     $0x40,%eax
80102ccc:	0f b6 c0             	movzbl %al,%eax
80102ccf:	f7 d0                	not    %eax
80102cd1:	89 c2                	mov    %eax,%edx
80102cd3:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cd8:	21 d0                	and    %edx,%eax
80102cda:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102cdf:	b8 00 00 00 00       	mov    $0x0,%eax
80102ce4:	e9 a0 00 00 00       	jmp    80102d89 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102ce9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cee:	83 e0 40             	and    $0x40,%eax
80102cf1:	85 c0                	test   %eax,%eax
80102cf3:	74 14                	je     80102d09 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102cf5:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102cfc:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d01:	83 e0 bf             	and    $0xffffffbf,%eax
80102d04:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102d09:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d0c:	05 20 90 10 80       	add    $0x80109020,%eax
80102d11:	0f b6 00             	movzbl (%eax),%eax
80102d14:	0f b6 d0             	movzbl %al,%edx
80102d17:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d1c:	09 d0                	or     %edx,%eax
80102d1e:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102d23:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d26:	05 20 91 10 80       	add    $0x80109120,%eax
80102d2b:	0f b6 00             	movzbl (%eax),%eax
80102d2e:	0f b6 d0             	movzbl %al,%edx
80102d31:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d36:	31 d0                	xor    %edx,%eax
80102d38:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d3d:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d42:	83 e0 03             	and    $0x3,%eax
80102d45:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102d4c:	03 45 fc             	add    -0x4(%ebp),%eax
80102d4f:	0f b6 00             	movzbl (%eax),%eax
80102d52:	0f b6 c0             	movzbl %al,%eax
80102d55:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102d58:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d5d:	83 e0 08             	and    $0x8,%eax
80102d60:	85 c0                	test   %eax,%eax
80102d62:	74 22                	je     80102d86 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102d64:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102d68:	76 0c                	jbe    80102d76 <kbdgetc+0x13c>
80102d6a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102d6e:	77 06                	ja     80102d76 <kbdgetc+0x13c>
      c += 'A' - 'a';
80102d70:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102d74:	eb 10                	jmp    80102d86 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102d76:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102d7a:	76 0a                	jbe    80102d86 <kbdgetc+0x14c>
80102d7c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102d80:	77 04                	ja     80102d86 <kbdgetc+0x14c>
      c += 'a' - 'A';
80102d82:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d86:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d89:	c9                   	leave  
80102d8a:	c3                   	ret    

80102d8b <kbdintr>:

void
kbdintr(void)
{
80102d8b:	55                   	push   %ebp
80102d8c:	89 e5                	mov    %esp,%ebp
80102d8e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d91:	c7 04 24 3a 2c 10 80 	movl   $0x80102c3a,(%esp)
80102d98:	e8 2b da ff ff       	call   801007c8 <consoleintr>
}
80102d9d:	c9                   	leave  
80102d9e:	c3                   	ret    
	...

80102da0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102da0:	55                   	push   %ebp
80102da1:	89 e5                	mov    %esp,%ebp
80102da3:	53                   	push   %ebx
80102da4:	83 ec 14             	sub    $0x14,%esp
80102da7:	8b 45 08             	mov    0x8(%ebp),%eax
80102daa:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dae:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102db2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102db6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102dba:	ec                   	in     (%dx),%al
80102dbb:	89 c3                	mov    %eax,%ebx
80102dbd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102dc0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102dc4:	83 c4 14             	add    $0x14,%esp
80102dc7:	5b                   	pop    %ebx
80102dc8:	5d                   	pop    %ebp
80102dc9:	c3                   	ret    

80102dca <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102dca:	55                   	push   %ebp
80102dcb:	89 e5                	mov    %esp,%ebp
80102dcd:	83 ec 08             	sub    $0x8,%esp
80102dd0:	8b 55 08             	mov    0x8(%ebp),%edx
80102dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102dd6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102dda:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ddd:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102de1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102de5:	ee                   	out    %al,(%dx)
}
80102de6:	c9                   	leave  
80102de7:	c3                   	ret    

80102de8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102de8:	55                   	push   %ebp
80102de9:	89 e5                	mov    %esp,%ebp
80102deb:	53                   	push   %ebx
80102dec:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102def:	9c                   	pushf  
80102df0:	5b                   	pop    %ebx
80102df1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102df4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102df7:	83 c4 10             	add    $0x10,%esp
80102dfa:	5b                   	pop    %ebx
80102dfb:	5d                   	pop    %ebp
80102dfc:	c3                   	ret    

80102dfd <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102dfd:	55                   	push   %ebp
80102dfe:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e00:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e05:	8b 55 08             	mov    0x8(%ebp),%edx
80102e08:	c1 e2 02             	shl    $0x2,%edx
80102e0b:	01 c2                	add    %eax,%edx
80102e0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e10:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102e12:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e17:	83 c0 20             	add    $0x20,%eax
80102e1a:	8b 00                	mov    (%eax),%eax
}
80102e1c:	5d                   	pop    %ebp
80102e1d:	c3                   	ret    

80102e1e <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102e1e:	55                   	push   %ebp
80102e1f:	89 e5                	mov    %esp,%ebp
80102e21:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102e24:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e29:	85 c0                	test   %eax,%eax
80102e2b:	0f 84 47 01 00 00    	je     80102f78 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102e31:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e38:	00 
80102e39:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e40:	e8 b8 ff ff ff       	call   80102dfd <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102e45:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e4c:	00 
80102e4d:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102e54:	e8 a4 ff ff ff       	call   80102dfd <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102e59:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102e60:	00 
80102e61:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102e68:	e8 90 ff ff ff       	call   80102dfd <lapicw>
  lapicw(TICR, 10000000); 
80102e6d:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102e74:	00 
80102e75:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102e7c:	e8 7c ff ff ff       	call   80102dfd <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102e81:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e88:	00 
80102e89:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102e90:	e8 68 ff ff ff       	call   80102dfd <lapicw>
  lapicw(LINT1, MASKED);
80102e95:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e9c:	00 
80102e9d:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102ea4:	e8 54 ff ff ff       	call   80102dfd <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102ea9:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102eae:	83 c0 30             	add    $0x30,%eax
80102eb1:	8b 00                	mov    (%eax),%eax
80102eb3:	c1 e8 10             	shr    $0x10,%eax
80102eb6:	25 ff 00 00 00       	and    $0xff,%eax
80102ebb:	83 f8 03             	cmp    $0x3,%eax
80102ebe:	76 14                	jbe    80102ed4 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102ec0:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ec7:	00 
80102ec8:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102ecf:	e8 29 ff ff ff       	call   80102dfd <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102ed4:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102edb:	00 
80102edc:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102ee3:	e8 15 ff ff ff       	call   80102dfd <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102ee8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102eef:	00 
80102ef0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102ef7:	e8 01 ff ff ff       	call   80102dfd <lapicw>
  lapicw(ESR, 0);
80102efc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f03:	00 
80102f04:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f0b:	e8 ed fe ff ff       	call   80102dfd <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f10:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f17:	00 
80102f18:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f1f:	e8 d9 fe ff ff       	call   80102dfd <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f24:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f2b:	00 
80102f2c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f33:	e8 c5 fe ff ff       	call   80102dfd <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f38:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f3f:	00 
80102f40:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f47:	e8 b1 fe ff ff       	call   80102dfd <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f4c:	90                   	nop
80102f4d:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f52:	05 00 03 00 00       	add    $0x300,%eax
80102f57:	8b 00                	mov    (%eax),%eax
80102f59:	25 00 10 00 00       	and    $0x1000,%eax
80102f5e:	85 c0                	test   %eax,%eax
80102f60:	75 eb                	jne    80102f4d <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102f62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f69:	00 
80102f6a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102f71:	e8 87 fe ff ff       	call   80102dfd <lapicw>
80102f76:	eb 01                	jmp    80102f79 <lapicinit+0x15b>

void
lapicinit(void)
{
  if(!lapic) 
    return;
80102f78:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102f79:	c9                   	leave  
80102f7a:	c3                   	ret    

80102f7b <cpunum>:

int
cpunum(void)
{
80102f7b:	55                   	push   %ebp
80102f7c:	89 e5                	mov    %esp,%ebp
80102f7e:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102f81:	e8 62 fe ff ff       	call   80102de8 <readeflags>
80102f86:	25 00 02 00 00       	and    $0x200,%eax
80102f8b:	85 c0                	test   %eax,%eax
80102f8d:	74 29                	je     80102fb8 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102f8f:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102f94:	85 c0                	test   %eax,%eax
80102f96:	0f 94 c2             	sete   %dl
80102f99:	83 c0 01             	add    $0x1,%eax
80102f9c:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102fa1:	84 d2                	test   %dl,%dl
80102fa3:	74 13                	je     80102fb8 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102fa5:	8b 45 04             	mov    0x4(%ebp),%eax
80102fa8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fac:	c7 04 24 0c 88 10 80 	movl   $0x8010880c,(%esp)
80102fb3:	e8 e9 d3 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102fb8:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102fbd:	85 c0                	test   %eax,%eax
80102fbf:	74 0f                	je     80102fd0 <cpunum+0x55>
    return lapic[ID]>>24;
80102fc1:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102fc6:	83 c0 20             	add    $0x20,%eax
80102fc9:	8b 00                	mov    (%eax),%eax
80102fcb:	c1 e8 18             	shr    $0x18,%eax
80102fce:	eb 05                	jmp    80102fd5 <cpunum+0x5a>
  return 0;
80102fd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102fd5:	c9                   	leave  
80102fd6:	c3                   	ret    

80102fd7 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102fd7:	55                   	push   %ebp
80102fd8:	89 e5                	mov    %esp,%ebp
80102fda:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102fdd:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102fe2:	85 c0                	test   %eax,%eax
80102fe4:	74 14                	je     80102ffa <lapiceoi+0x23>
    lapicw(EOI, 0);
80102fe6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fed:	00 
80102fee:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102ff5:	e8 03 fe ff ff       	call   80102dfd <lapicw>
}
80102ffa:	c9                   	leave  
80102ffb:	c3                   	ret    

80102ffc <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102ffc:	55                   	push   %ebp
80102ffd:	89 e5                	mov    %esp,%ebp
}
80102fff:	5d                   	pop    %ebp
80103000:	c3                   	ret    

80103001 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103001:	55                   	push   %ebp
80103002:	89 e5                	mov    %esp,%ebp
80103004:	83 ec 1c             	sub    $0x1c,%esp
80103007:	8b 45 08             	mov    0x8(%ebp),%eax
8010300a:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010300d:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103014:	00 
80103015:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010301c:	e8 a9 fd ff ff       	call   80102dca <outb>
  outb(CMOS_PORT+1, 0x0A);
80103021:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103028:	00 
80103029:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103030:	e8 95 fd ff ff       	call   80102dca <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103035:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010303c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010303f:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103044:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103047:	8d 50 02             	lea    0x2(%eax),%edx
8010304a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010304d:	c1 e8 04             	shr    $0x4,%eax
80103050:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103053:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103057:	c1 e0 18             	shl    $0x18,%eax
8010305a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010305e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103065:	e8 93 fd ff ff       	call   80102dfd <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010306a:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103071:	00 
80103072:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103079:	e8 7f fd ff ff       	call   80102dfd <lapicw>
  microdelay(200);
8010307e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103085:	e8 72 ff ff ff       	call   80102ffc <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010308a:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103091:	00 
80103092:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103099:	e8 5f fd ff ff       	call   80102dfd <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010309e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801030a5:	e8 52 ff ff ff       	call   80102ffc <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030aa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030b1:	eb 40                	jmp    801030f3 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801030b3:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030b7:	c1 e0 18             	shl    $0x18,%eax
801030ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801030be:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030c5:	e8 33 fd ff ff       	call   80102dfd <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801030ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801030cd:	c1 e8 0c             	shr    $0xc,%eax
801030d0:	80 cc 06             	or     $0x6,%ah
801030d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801030d7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030de:	e8 1a fd ff ff       	call   80102dfd <lapicw>
    microdelay(200);
801030e3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801030ea:	e8 0d ff ff ff       	call   80102ffc <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030ef:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801030f3:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801030f7:	7e ba                	jle    801030b3 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801030f9:	c9                   	leave  
801030fa:	c3                   	ret    

801030fb <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801030fb:	55                   	push   %ebp
801030fc:	89 e5                	mov    %esp,%ebp
801030fe:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103101:	8b 45 08             	mov    0x8(%ebp),%eax
80103104:	0f b6 c0             	movzbl %al,%eax
80103107:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310b:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103112:	e8 b3 fc ff ff       	call   80102dca <outb>
  microdelay(200);
80103117:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010311e:	e8 d9 fe ff ff       	call   80102ffc <microdelay>

  return inb(CMOS_RETURN);
80103123:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010312a:	e8 71 fc ff ff       	call   80102da0 <inb>
8010312f:	0f b6 c0             	movzbl %al,%eax
}
80103132:	c9                   	leave  
80103133:	c3                   	ret    

80103134 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103134:	55                   	push   %ebp
80103135:	89 e5                	mov    %esp,%ebp
80103137:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010313a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103141:	e8 b5 ff ff ff       	call   801030fb <cmos_read>
80103146:	8b 55 08             	mov    0x8(%ebp),%edx
80103149:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010314b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103152:	e8 a4 ff ff ff       	call   801030fb <cmos_read>
80103157:	8b 55 08             	mov    0x8(%ebp),%edx
8010315a:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
8010315d:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103164:	e8 92 ff ff ff       	call   801030fb <cmos_read>
80103169:	8b 55 08             	mov    0x8(%ebp),%edx
8010316c:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010316f:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103176:	e8 80 ff ff ff       	call   801030fb <cmos_read>
8010317b:	8b 55 08             	mov    0x8(%ebp),%edx
8010317e:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103181:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103188:	e8 6e ff ff ff       	call   801030fb <cmos_read>
8010318d:	8b 55 08             	mov    0x8(%ebp),%edx
80103190:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103193:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
8010319a:	e8 5c ff ff ff       	call   801030fb <cmos_read>
8010319f:	8b 55 08             	mov    0x8(%ebp),%edx
801031a2:	89 42 14             	mov    %eax,0x14(%edx)
}
801031a5:	c9                   	leave  
801031a6:	c3                   	ret    

801031a7 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801031a7:	55                   	push   %ebp
801031a8:	89 e5                	mov    %esp,%ebp
801031aa:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031ad:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801031b4:	e8 42 ff ff ff       	call   801030fb <cmos_read>
801031b9:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031bf:	83 e0 04             	and    $0x4,%eax
801031c2:	85 c0                	test   %eax,%eax
801031c4:	0f 94 c0             	sete   %al
801031c7:	0f b6 c0             	movzbl %al,%eax
801031ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
801031cd:	eb 01                	jmp    801031d0 <cmostime+0x29>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801031cf:	90                   	nop

  bcd = (sb & (1 << 2)) == 0;

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801031d0:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031d3:	89 04 24             	mov    %eax,(%esp)
801031d6:	e8 59 ff ff ff       	call   80103134 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801031db:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801031e2:	e8 14 ff ff ff       	call   801030fb <cmos_read>
801031e7:	25 80 00 00 00       	and    $0x80,%eax
801031ec:	85 c0                	test   %eax,%eax
801031ee:	75 2b                	jne    8010321b <cmostime+0x74>
        continue;
    fill_rtcdate(&t2);
801031f0:	8d 45 c0             	lea    -0x40(%ebp),%eax
801031f3:	89 04 24             	mov    %eax,(%esp)
801031f6:	e8 39 ff ff ff       	call   80103134 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801031fb:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103202:	00 
80103203:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103206:	89 44 24 04          	mov    %eax,0x4(%esp)
8010320a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010320d:	89 04 24             	mov    %eax,(%esp)
80103210:	e8 08 20 00 00       	call   8010521d <memcmp>
80103215:	85 c0                	test   %eax,%eax
80103217:	75 b6                	jne    801031cf <cmostime+0x28>
      break;
80103219:	eb 03                	jmp    8010321e <cmostime+0x77>

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
8010321b:	90                   	nop
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
8010321c:	eb b1                	jmp    801031cf <cmostime+0x28>

  // convert
  if (bcd) {
8010321e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103222:	0f 84 a8 00 00 00    	je     801032d0 <cmostime+0x129>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103228:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010322b:	89 c2                	mov    %eax,%edx
8010322d:	c1 ea 04             	shr    $0x4,%edx
80103230:	89 d0                	mov    %edx,%eax
80103232:	c1 e0 02             	shl    $0x2,%eax
80103235:	01 d0                	add    %edx,%eax
80103237:	01 c0                	add    %eax,%eax
80103239:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010323c:	83 e2 0f             	and    $0xf,%edx
8010323f:	01 d0                	add    %edx,%eax
80103241:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103244:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103247:	89 c2                	mov    %eax,%edx
80103249:	c1 ea 04             	shr    $0x4,%edx
8010324c:	89 d0                	mov    %edx,%eax
8010324e:	c1 e0 02             	shl    $0x2,%eax
80103251:	01 d0                	add    %edx,%eax
80103253:	01 c0                	add    %eax,%eax
80103255:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103258:	83 e2 0f             	and    $0xf,%edx
8010325b:	01 d0                	add    %edx,%eax
8010325d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103260:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103263:	89 c2                	mov    %eax,%edx
80103265:	c1 ea 04             	shr    $0x4,%edx
80103268:	89 d0                	mov    %edx,%eax
8010326a:	c1 e0 02             	shl    $0x2,%eax
8010326d:	01 d0                	add    %edx,%eax
8010326f:	01 c0                	add    %eax,%eax
80103271:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103274:	83 e2 0f             	and    $0xf,%edx
80103277:	01 d0                	add    %edx,%eax
80103279:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010327c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010327f:	89 c2                	mov    %eax,%edx
80103281:	c1 ea 04             	shr    $0x4,%edx
80103284:	89 d0                	mov    %edx,%eax
80103286:	c1 e0 02             	shl    $0x2,%eax
80103289:	01 d0                	add    %edx,%eax
8010328b:	01 c0                	add    %eax,%eax
8010328d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103290:	83 e2 0f             	and    $0xf,%edx
80103293:	01 d0                	add    %edx,%eax
80103295:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103298:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010329b:	89 c2                	mov    %eax,%edx
8010329d:	c1 ea 04             	shr    $0x4,%edx
801032a0:	89 d0                	mov    %edx,%eax
801032a2:	c1 e0 02             	shl    $0x2,%eax
801032a5:	01 d0                	add    %edx,%eax
801032a7:	01 c0                	add    %eax,%eax
801032a9:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032ac:	83 e2 0f             	and    $0xf,%edx
801032af:	01 d0                	add    %edx,%eax
801032b1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032b7:	89 c2                	mov    %eax,%edx
801032b9:	c1 ea 04             	shr    $0x4,%edx
801032bc:	89 d0                	mov    %edx,%eax
801032be:	c1 e0 02             	shl    $0x2,%eax
801032c1:	01 d0                	add    %edx,%eax
801032c3:	01 c0                	add    %eax,%eax
801032c5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032c8:	83 e2 0f             	and    $0xf,%edx
801032cb:	01 d0                	add    %edx,%eax
801032cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801032d0:	8b 45 08             	mov    0x8(%ebp),%eax
801032d3:	8b 55 d8             	mov    -0x28(%ebp),%edx
801032d6:	89 10                	mov    %edx,(%eax)
801032d8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801032db:	89 50 04             	mov    %edx,0x4(%eax)
801032de:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032e1:	89 50 08             	mov    %edx,0x8(%eax)
801032e4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032e7:	89 50 0c             	mov    %edx,0xc(%eax)
801032ea:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032ed:	89 50 10             	mov    %edx,0x10(%eax)
801032f0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032f3:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801032f6:	8b 45 08             	mov    0x8(%ebp),%eax
801032f9:	8b 40 14             	mov    0x14(%eax),%eax
801032fc:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103302:	8b 45 08             	mov    0x8(%ebp),%eax
80103305:	89 50 14             	mov    %edx,0x14(%eax)
}
80103308:	c9                   	leave  
80103309:	c3                   	ret    
	...

8010330c <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
8010330c:	55                   	push   %ebp
8010330d:	89 e5                	mov    %esp,%ebp
8010330f:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103312:	c7 44 24 04 38 88 10 	movl   $0x80108838,0x4(%esp)
80103319:	80 
8010331a:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103321:	e8 10 1c 00 00       	call   80104f36 <initlock>
  readsb(dev, &sb);
80103326:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103329:	89 44 24 04          	mov    %eax,0x4(%esp)
8010332d:	8b 45 08             	mov    0x8(%ebp),%eax
80103330:	89 04 24             	mov    %eax,(%esp)
80103333:	e8 dc df ff ff       	call   80101314 <readsb>
  log.start = sb.logstart;
80103338:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010333b:	a3 94 22 11 80       	mov    %eax,0x80112294
  log.size = sb.nlog;
80103340:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103343:	a3 98 22 11 80       	mov    %eax,0x80112298
  log.dev = dev;
80103348:	8b 45 08             	mov    0x8(%ebp),%eax
8010334b:	a3 a4 22 11 80       	mov    %eax,0x801122a4
  recover_from_log();
80103350:	e8 97 01 00 00       	call   801034ec <recover_from_log>
}
80103355:	c9                   	leave  
80103356:	c3                   	ret    

80103357 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103357:	55                   	push   %ebp
80103358:	89 e5                	mov    %esp,%ebp
8010335a:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010335d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103364:	e9 89 00 00 00       	jmp    801033f2 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103369:	a1 94 22 11 80       	mov    0x80112294,%eax
8010336e:	03 45 f4             	add    -0xc(%ebp),%eax
80103371:	83 c0 01             	add    $0x1,%eax
80103374:	89 c2                	mov    %eax,%edx
80103376:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010337b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010337f:	89 04 24             	mov    %eax,(%esp)
80103382:	e8 1f ce ff ff       	call   801001a6 <bread>
80103387:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010338a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338d:	83 c0 10             	add    $0x10,%eax
80103390:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103397:	89 c2                	mov    %eax,%edx
80103399:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010339e:	89 54 24 04          	mov    %edx,0x4(%esp)
801033a2:	89 04 24             	mov    %eax,(%esp)
801033a5:	e8 fc cd ff ff       	call   801001a6 <bread>
801033aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033b0:	8d 50 18             	lea    0x18(%eax),%edx
801033b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033b6:	83 c0 18             	add    $0x18,%eax
801033b9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801033c0:	00 
801033c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801033c5:	89 04 24             	mov    %eax,(%esp)
801033c8:	e8 ac 1e 00 00       	call   80105279 <memmove>
    bwrite(dbuf);  // write dst to disk
801033cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033d0:	89 04 24             	mov    %eax,(%esp)
801033d3:	e8 05 ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801033d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033db:	89 04 24             	mov    %eax,(%esp)
801033de:	e8 34 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801033e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033e6:	89 04 24             	mov    %eax,(%esp)
801033e9:	e8 29 ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801033ee:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033f2:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801033f7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033fa:	0f 8f 69 ff ff ff    	jg     80103369 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103400:	c9                   	leave  
80103401:	c3                   	ret    

80103402 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103402:	55                   	push   %ebp
80103403:	89 e5                	mov    %esp,%ebp
80103405:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103408:	a1 94 22 11 80       	mov    0x80112294,%eax
8010340d:	89 c2                	mov    %eax,%edx
8010340f:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103414:	89 54 24 04          	mov    %edx,0x4(%esp)
80103418:	89 04 24             	mov    %eax,(%esp)
8010341b:	e8 86 cd ff ff       	call   801001a6 <bread>
80103420:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103426:	83 c0 18             	add    $0x18,%eax
80103429:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010342c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010342f:	8b 00                	mov    (%eax),%eax
80103431:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  for (i = 0; i < log.lh.n; i++) {
80103436:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010343d:	eb 1b                	jmp    8010345a <read_head+0x58>
    log.lh.block[i] = lh->block[i];
8010343f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103442:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103445:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103449:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010344c:	83 c2 10             	add    $0x10,%edx
8010344f:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103456:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010345a:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010345f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103462:	7f db                	jg     8010343f <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103464:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103467:	89 04 24             	mov    %eax,(%esp)
8010346a:	e8 a8 cd ff ff       	call   80100217 <brelse>
}
8010346f:	c9                   	leave  
80103470:	c3                   	ret    

80103471 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103471:	55                   	push   %ebp
80103472:	89 e5                	mov    %esp,%ebp
80103474:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103477:	a1 94 22 11 80       	mov    0x80112294,%eax
8010347c:	89 c2                	mov    %eax,%edx
8010347e:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103483:	89 54 24 04          	mov    %edx,0x4(%esp)
80103487:	89 04 24             	mov    %eax,(%esp)
8010348a:	e8 17 cd ff ff       	call   801001a6 <bread>
8010348f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103492:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103495:	83 c0 18             	add    $0x18,%eax
80103498:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010349b:	8b 15 a8 22 11 80    	mov    0x801122a8,%edx
801034a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034a4:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034a6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034ad:	eb 1b                	jmp    801034ca <write_head+0x59>
    hb->block[i] = log.lh.block[i];
801034af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034b2:	83 c0 10             	add    $0x10,%eax
801034b5:	8b 0c 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%ecx
801034bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034c2:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801034c6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034ca:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801034cf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034d2:	7f db                	jg     801034af <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
801034d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034d7:	89 04 24             	mov    %eax,(%esp)
801034da:	e8 fe cc ff ff       	call   801001dd <bwrite>
  brelse(buf);
801034df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034e2:	89 04 24             	mov    %eax,(%esp)
801034e5:	e8 2d cd ff ff       	call   80100217 <brelse>
}
801034ea:	c9                   	leave  
801034eb:	c3                   	ret    

801034ec <recover_from_log>:

static void
recover_from_log(void)
{
801034ec:	55                   	push   %ebp
801034ed:	89 e5                	mov    %esp,%ebp
801034ef:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801034f2:	e8 0b ff ff ff       	call   80103402 <read_head>
  install_trans(); // if committed, copy from log to disk
801034f7:	e8 5b fe ff ff       	call   80103357 <install_trans>
  log.lh.n = 0;
801034fc:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103503:	00 00 00 
  write_head(); // clear the log
80103506:	e8 66 ff ff ff       	call   80103471 <write_head>
}
8010350b:	c9                   	leave  
8010350c:	c3                   	ret    

8010350d <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
8010350d:	55                   	push   %ebp
8010350e:	89 e5                	mov    %esp,%ebp
80103510:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103513:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010351a:	e8 38 1a 00 00       	call   80104f57 <acquire>
  while(1){
    if(log.committing){
8010351f:	a1 a0 22 11 80       	mov    0x801122a0,%eax
80103524:	85 c0                	test   %eax,%eax
80103526:	74 16                	je     8010353e <begin_op+0x31>
      sleep(&log, &log.lock);
80103528:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
8010352f:	80 
80103530:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103537:	e8 3d 17 00 00       	call   80104c79 <sleep>
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
8010353c:	eb e1                	jmp    8010351f <begin_op+0x12>
{
  acquire(&log.lock);
  while(1){
    if(log.committing){
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010353e:	8b 0d a8 22 11 80    	mov    0x801122a8,%ecx
80103544:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103549:	8d 50 01             	lea    0x1(%eax),%edx
8010354c:	89 d0                	mov    %edx,%eax
8010354e:	c1 e0 02             	shl    $0x2,%eax
80103551:	01 d0                	add    %edx,%eax
80103553:	01 c0                	add    %eax,%eax
80103555:	01 c8                	add    %ecx,%eax
80103557:	83 f8 1e             	cmp    $0x1e,%eax
8010355a:	7e 16                	jle    80103572 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
8010355c:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103563:	80 
80103564:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010356b:	e8 09 17 00 00       	call   80104c79 <sleep>
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
80103570:	eb ad                	jmp    8010351f <begin_op+0x12>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    } else {
      log.outstanding += 1;
80103572:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103577:	83 c0 01             	add    $0x1,%eax
8010357a:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
8010357f:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103586:	e8 2e 1a 00 00       	call   80104fb9 <release>
      break;
8010358b:	90                   	nop
    }
  }
}
8010358c:	c9                   	leave  
8010358d:	c3                   	ret    

8010358e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
8010358e:	55                   	push   %ebp
8010358f:	89 e5                	mov    %esp,%ebp
80103591:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
8010359b:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801035a2:	e8 b0 19 00 00       	call   80104f57 <acquire>
  log.outstanding -= 1;
801035a7:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801035ac:	83 e8 01             	sub    $0x1,%eax
801035af:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
801035b4:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801035b9:	85 c0                	test   %eax,%eax
801035bb:	74 0c                	je     801035c9 <end_op+0x3b>
    panic("log.committing");
801035bd:	c7 04 24 3c 88 10 80 	movl   $0x8010883c,(%esp)
801035c4:	e8 74 cf ff ff       	call   8010053d <panic>
  if(log.outstanding == 0){
801035c9:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801035ce:	85 c0                	test   %eax,%eax
801035d0:	75 13                	jne    801035e5 <end_op+0x57>
    do_commit = 1;
801035d2:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801035d9:	c7 05 a0 22 11 80 01 	movl   $0x1,0x801122a0
801035e0:	00 00 00 
801035e3:	eb 0c                	jmp    801035f1 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
801035e5:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801035ec:	e8 61 17 00 00       	call   80104d52 <wakeup>
  }
  release(&log.lock);
801035f1:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801035f8:	e8 bc 19 00 00       	call   80104fb9 <release>

  if(do_commit){
801035fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103601:	74 33                	je     80103636 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103603:	e8 db 00 00 00       	call   801036e3 <commit>
    acquire(&log.lock);
80103608:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010360f:	e8 43 19 00 00       	call   80104f57 <acquire>
    log.committing = 0;
80103614:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
8010361b:	00 00 00 
    wakeup(&log);
8010361e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103625:	e8 28 17 00 00       	call   80104d52 <wakeup>
    release(&log.lock);
8010362a:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103631:	e8 83 19 00 00       	call   80104fb9 <release>
  }
}
80103636:	c9                   	leave  
80103637:	c3                   	ret    

80103638 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103638:	55                   	push   %ebp
80103639:	89 e5                	mov    %esp,%ebp
8010363b:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010363e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103645:	e9 89 00 00 00       	jmp    801036d3 <write_log+0x9b>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010364a:	a1 94 22 11 80       	mov    0x80112294,%eax
8010364f:	03 45 f4             	add    -0xc(%ebp),%eax
80103652:	83 c0 01             	add    $0x1,%eax
80103655:	89 c2                	mov    %eax,%edx
80103657:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010365c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103660:	89 04 24             	mov    %eax,(%esp)
80103663:	e8 3e cb ff ff       	call   801001a6 <bread>
80103668:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
8010366b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010366e:	83 c0 10             	add    $0x10,%eax
80103671:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103678:	89 c2                	mov    %eax,%edx
8010367a:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010367f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103683:	89 04 24             	mov    %eax,(%esp)
80103686:	e8 1b cb ff ff       	call   801001a6 <bread>
8010368b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
8010368e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103691:	8d 50 18             	lea    0x18(%eax),%edx
80103694:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103697:	83 c0 18             	add    $0x18,%eax
8010369a:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801036a1:	00 
801036a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801036a6:	89 04 24             	mov    %eax,(%esp)
801036a9:	e8 cb 1b 00 00       	call   80105279 <memmove>
    bwrite(to);  // write the log
801036ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036b1:	89 04 24             	mov    %eax,(%esp)
801036b4:	e8 24 cb ff ff       	call   801001dd <bwrite>
    brelse(from); 
801036b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036bc:	89 04 24             	mov    %eax,(%esp)
801036bf:	e8 53 cb ff ff       	call   80100217 <brelse>
    brelse(to);
801036c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036c7:	89 04 24             	mov    %eax,(%esp)
801036ca:	e8 48 cb ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801036cf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801036d3:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036d8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036db:	0f 8f 69 ff ff ff    	jg     8010364a <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
801036e1:	c9                   	leave  
801036e2:	c3                   	ret    

801036e3 <commit>:

static void
commit()
{
801036e3:	55                   	push   %ebp
801036e4:	89 e5                	mov    %esp,%ebp
801036e6:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
801036e9:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036ee:	85 c0                	test   %eax,%eax
801036f0:	7e 1e                	jle    80103710 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
801036f2:	e8 41 ff ff ff       	call   80103638 <write_log>
    write_head();    // Write header to disk -- the real commit
801036f7:	e8 75 fd ff ff       	call   80103471 <write_head>
    install_trans(); // Now install writes to home locations
801036fc:	e8 56 fc ff ff       	call   80103357 <install_trans>
    log.lh.n = 0; 
80103701:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103708:	00 00 00 
    write_head();    // Erase the transaction from the log
8010370b:	e8 61 fd ff ff       	call   80103471 <write_head>
  }
}
80103710:	c9                   	leave  
80103711:	c3                   	ret    

80103712 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103712:	55                   	push   %ebp
80103713:	89 e5                	mov    %esp,%ebp
80103715:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103718:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010371d:	83 f8 1d             	cmp    $0x1d,%eax
80103720:	7f 12                	jg     80103734 <log_write+0x22>
80103722:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103727:	8b 15 98 22 11 80    	mov    0x80112298,%edx
8010372d:	83 ea 01             	sub    $0x1,%edx
80103730:	39 d0                	cmp    %edx,%eax
80103732:	7c 0c                	jl     80103740 <log_write+0x2e>
    panic("too big a transaction");
80103734:	c7 04 24 4b 88 10 80 	movl   $0x8010884b,(%esp)
8010373b:	e8 fd cd ff ff       	call   8010053d <panic>
  if (log.outstanding < 1)
80103740:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103745:	85 c0                	test   %eax,%eax
80103747:	7f 0c                	jg     80103755 <log_write+0x43>
    panic("log_write outside of trans");
80103749:	c7 04 24 61 88 10 80 	movl   $0x80108861,(%esp)
80103750:	e8 e8 cd ff ff       	call   8010053d <panic>

  acquire(&log.lock);
80103755:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010375c:	e8 f6 17 00 00       	call   80104f57 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103761:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103768:	eb 1d                	jmp    80103787 <log_write+0x75>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
8010376a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010376d:	83 c0 10             	add    $0x10,%eax
80103770:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103777:	89 c2                	mov    %eax,%edx
80103779:	8b 45 08             	mov    0x8(%ebp),%eax
8010377c:	8b 40 08             	mov    0x8(%eax),%eax
8010377f:	39 c2                	cmp    %eax,%edx
80103781:	74 10                	je     80103793 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103783:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103787:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010378c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010378f:	7f d9                	jg     8010376a <log_write+0x58>
80103791:	eb 01                	jmp    80103794 <log_write+0x82>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
80103793:	90                   	nop
  }
  log.lh.block[i] = b->blockno;
80103794:	8b 45 08             	mov    0x8(%ebp),%eax
80103797:	8b 40 08             	mov    0x8(%eax),%eax
8010379a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010379d:	83 c2 10             	add    $0x10,%edx
801037a0:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
  if (i == log.lh.n)
801037a7:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801037ac:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037af:	75 0d                	jne    801037be <log_write+0xac>
    log.lh.n++;
801037b1:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801037b6:	83 c0 01             	add    $0x1,%eax
801037b9:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  b->flags |= B_DIRTY; // prevent eviction
801037be:	8b 45 08             	mov    0x8(%ebp),%eax
801037c1:	8b 00                	mov    (%eax),%eax
801037c3:	89 c2                	mov    %eax,%edx
801037c5:	83 ca 04             	or     $0x4,%edx
801037c8:	8b 45 08             	mov    0x8(%ebp),%eax
801037cb:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801037cd:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801037d4:	e8 e0 17 00 00       	call   80104fb9 <release>
}
801037d9:	c9                   	leave  
801037da:	c3                   	ret    
	...

801037dc <v2p>:
801037dc:	55                   	push   %ebp
801037dd:	89 e5                	mov    %esp,%ebp
801037df:	8b 45 08             	mov    0x8(%ebp),%eax
801037e2:	05 00 00 00 80       	add    $0x80000000,%eax
801037e7:	5d                   	pop    %ebp
801037e8:	c3                   	ret    

801037e9 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801037e9:	55                   	push   %ebp
801037ea:	89 e5                	mov    %esp,%ebp
801037ec:	8b 45 08             	mov    0x8(%ebp),%eax
801037ef:	05 00 00 00 80       	add    $0x80000000,%eax
801037f4:	5d                   	pop    %ebp
801037f5:	c3                   	ret    

801037f6 <xchg>:
  asm volatile("hlt");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801037f6:	55                   	push   %ebp
801037f7:	89 e5                	mov    %esp,%ebp
801037f9:	53                   	push   %ebx
801037fa:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801037fd:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103800:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103803:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103806:	89 c3                	mov    %eax,%ebx
80103808:	89 d8                	mov    %ebx,%eax
8010380a:	f0 87 02             	lock xchg %eax,(%edx)
8010380d:	89 c3                	mov    %eax,%ebx
8010380f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103812:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103815:	83 c4 10             	add    $0x10,%esp
80103818:	5b                   	pop    %ebx
80103819:	5d                   	pop    %ebp
8010381a:	c3                   	ret    

8010381b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010381b:	55                   	push   %ebp
8010381c:	89 e5                	mov    %esp,%ebp
8010381e:	83 e4 f0             	and    $0xfffffff0,%esp
80103821:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103824:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010382b:	80 
8010382c:	c7 04 24 3c 51 11 80 	movl   $0x8011513c,(%esp)
80103833:	e8 5d f2 ff ff       	call   80102a95 <kinit1>
  kvmalloc();      // kernel page table
80103838:	e8 d9 45 00 00       	call   80107e16 <kvmalloc>
  mpinit();        // collect info about this machine
8010383d:	e8 4f 04 00 00       	call   80103c91 <mpinit>
  lapicinit();
80103842:	e8 d7 f5 ff ff       	call   80102e1e <lapicinit>
  seginit();       // set up segments
80103847:	e8 6d 3f 00 00       	call   801077b9 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010384c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103852:	0f b6 00             	movzbl (%eax),%eax
80103855:	0f b6 c0             	movzbl %al,%eax
80103858:	89 44 24 04          	mov    %eax,0x4(%esp)
8010385c:	c7 04 24 7c 88 10 80 	movl   $0x8010887c,(%esp)
80103863:	e8 39 cb ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103868:	e8 89 06 00 00       	call   80103ef6 <picinit>
  ioapicinit();    // another interrupt controller
8010386d:	e8 13 f1 ff ff       	call   80102985 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103872:	e8 45 d2 ff ff       	call   80100abc <consoleinit>
  uartinit();      // serial port
80103877:	e8 88 32 00 00       	call   80106b04 <uartinit>
  pinit();         // process table
8010387c:	e8 90 0b 00 00       	call   80104411 <pinit>
  tvinit();        // trap vectors
80103881:	e8 a6 2d 00 00       	call   8010662c <tvinit>
  binit();         // buffer cache
80103886:	e8 a9 c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010388b:	e8 98 d6 ff ff       	call   80100f28 <fileinit>
  ideinit();       // disk
80103890:	e8 21 ed ff ff       	call   801025b6 <ideinit>
  if(!ismp)
80103895:	a1 44 23 11 80       	mov    0x80112344,%eax
8010389a:	85 c0                	test   %eax,%eax
8010389c:	75 05                	jne    801038a3 <main+0x88>
    timerinit();   // uniprocessor timer
8010389e:	e8 bf 2c 00 00       	call   80106562 <timerinit>
  startothers();   // start other processors
801038a3:	e8 7f 00 00 00       	call   80103927 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038a8:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801038af:	8e 
801038b0:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801038b7:	e8 11 f2 ff ff       	call   80102acd <kinit2>
  userinit();      // first user process
801038bc:	e8 6b 0c 00 00       	call   8010452c <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801038c1:	e8 1a 00 00 00       	call   801038e0 <mpmain>

801038c6 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801038c6:	55                   	push   %ebp
801038c7:	89 e5                	mov    %esp,%ebp
801038c9:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801038cc:	e8 5c 45 00 00       	call   80107e2d <switchkvm>
  seginit();
801038d1:	e8 e3 3e 00 00       	call   801077b9 <seginit>
  lapicinit();
801038d6:	e8 43 f5 ff ff       	call   80102e1e <lapicinit>
  mpmain();
801038db:	e8 00 00 00 00       	call   801038e0 <mpmain>

801038e0 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801038e0:	55                   	push   %ebp
801038e1:	89 e5                	mov    %esp,%ebp
801038e3:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801038e6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801038ec:	0f b6 00             	movzbl (%eax),%eax
801038ef:	0f b6 c0             	movzbl %al,%eax
801038f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801038f6:	c7 04 24 93 88 10 80 	movl   $0x80108893,(%esp)
801038fd:	e8 9f ca ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103902:	e8 99 2e 00 00       	call   801067a0 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103907:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010390d:	05 a8 00 00 00       	add    $0xa8,%eax
80103912:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103919:	00 
8010391a:	89 04 24             	mov    %eax,(%esp)
8010391d:	e8 d4 fe ff ff       	call   801037f6 <xchg>
  scheduler();     // start running processes
80103922:	e8 76 11 00 00       	call   80104a9d <scheduler>

80103927 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103927:	55                   	push   %ebp
80103928:	89 e5                	mov    %esp,%ebp
8010392a:	53                   	push   %ebx
8010392b:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010392e:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103935:	e8 af fe ff ff       	call   801037e9 <p2v>
8010393a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010393d:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103942:	89 44 24 08          	mov    %eax,0x8(%esp)
80103946:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
8010394d:	80 
8010394e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103951:	89 04 24             	mov    %eax,(%esp)
80103954:	e8 20 19 00 00       	call   80105279 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103959:	c7 45 f4 60 23 11 80 	movl   $0x80112360,-0xc(%ebp)
80103960:	e9 86 00 00 00       	jmp    801039eb <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103965:	e8 11 f6 ff ff       	call   80102f7b <cpunum>
8010396a:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103970:	05 60 23 11 80       	add    $0x80112360,%eax
80103975:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103978:	74 69                	je     801039e3 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010397a:	e8 44 f2 ff ff       	call   80102bc3 <kalloc>
8010397f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103982:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103985:	83 e8 04             	sub    $0x4,%eax
80103988:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010398b:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103991:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103993:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103996:	83 e8 08             	sub    $0x8,%eax
80103999:	c7 00 c6 38 10 80    	movl   $0x801038c6,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
8010399f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a2:	8d 58 f4             	lea    -0xc(%eax),%ebx
801039a5:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801039ac:	e8 2b fe ff ff       	call   801037dc <v2p>
801039b1:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801039b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039b6:	89 04 24             	mov    %eax,(%esp)
801039b9:	e8 1e fe ff ff       	call   801037dc <v2p>
801039be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039c1:	0f b6 12             	movzbl (%edx),%edx
801039c4:	0f b6 d2             	movzbl %dl,%edx
801039c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801039cb:	89 14 24             	mov    %edx,(%esp)
801039ce:	e8 2e f6 ff ff       	call   80103001 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801039d3:	90                   	nop
801039d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039d7:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801039dd:	85 c0                	test   %eax,%eax
801039df:	74 f3                	je     801039d4 <startothers+0xad>
801039e1:	eb 01                	jmp    801039e4 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
801039e3:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801039e4:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801039eb:	a1 40 29 11 80       	mov    0x80112940,%eax
801039f0:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801039f6:	05 60 23 11 80       	add    $0x80112360,%eax
801039fb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039fe:	0f 87 61 ff ff ff    	ja     80103965 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103a04:	83 c4 24             	add    $0x24,%esp
80103a07:	5b                   	pop    %ebx
80103a08:	5d                   	pop    %ebp
80103a09:	c3                   	ret    
	...

80103a0c <p2v>:
80103a0c:	55                   	push   %ebp
80103a0d:	89 e5                	mov    %esp,%ebp
80103a0f:	8b 45 08             	mov    0x8(%ebp),%eax
80103a12:	05 00 00 00 80       	add    $0x80000000,%eax
80103a17:	5d                   	pop    %ebp
80103a18:	c3                   	ret    

80103a19 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103a19:	55                   	push   %ebp
80103a1a:	89 e5                	mov    %esp,%ebp
80103a1c:	53                   	push   %ebx
80103a1d:	83 ec 14             	sub    $0x14,%esp
80103a20:	8b 45 08             	mov    0x8(%ebp),%eax
80103a23:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a27:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103a2b:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103a2f:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103a33:	ec                   	in     (%dx),%al
80103a34:	89 c3                	mov    %eax,%ebx
80103a36:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103a39:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103a3d:	83 c4 14             	add    $0x14,%esp
80103a40:	5b                   	pop    %ebx
80103a41:	5d                   	pop    %ebp
80103a42:	c3                   	ret    

80103a43 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a43:	55                   	push   %ebp
80103a44:	89 e5                	mov    %esp,%ebp
80103a46:	83 ec 08             	sub    $0x8,%esp
80103a49:	8b 55 08             	mov    0x8(%ebp),%edx
80103a4c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a4f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a53:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a56:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a5a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a5e:	ee                   	out    %al,(%dx)
}
80103a5f:	c9                   	leave  
80103a60:	c3                   	ret    

80103a61 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103a61:	55                   	push   %ebp
80103a62:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103a64:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103a69:	89 c2                	mov    %eax,%edx
80103a6b:	b8 60 23 11 80       	mov    $0x80112360,%eax
80103a70:	89 d1                	mov    %edx,%ecx
80103a72:	29 c1                	sub    %eax,%ecx
80103a74:	89 c8                	mov    %ecx,%eax
80103a76:	c1 f8 02             	sar    $0x2,%eax
80103a79:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103a7f:	5d                   	pop    %ebp
80103a80:	c3                   	ret    

80103a81 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103a81:	55                   	push   %ebp
80103a82:	89 e5                	mov    %esp,%ebp
80103a84:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103a87:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a8e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a95:	eb 13                	jmp    80103aaa <sum+0x29>
    sum += addr[i];
80103a97:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a9a:	03 45 08             	add    0x8(%ebp),%eax
80103a9d:	0f b6 00             	movzbl (%eax),%eax
80103aa0:	0f b6 c0             	movzbl %al,%eax
80103aa3:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103aa6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103aaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103aad:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103ab0:	7c e5                	jl     80103a97 <sum+0x16>
    sum += addr[i];
  return sum;
80103ab2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103ab5:	c9                   	leave  
80103ab6:	c3                   	ret    

80103ab7 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103ab7:	55                   	push   %ebp
80103ab8:	89 e5                	mov    %esp,%ebp
80103aba:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103abd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ac0:	89 04 24             	mov    %eax,(%esp)
80103ac3:	e8 44 ff ff ff       	call   80103a0c <p2v>
80103ac8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103acb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ace:	03 45 f0             	add    -0x10(%ebp),%eax
80103ad1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103ad4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ad7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ada:	eb 3f                	jmp    80103b1b <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103adc:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103ae3:	00 
80103ae4:	c7 44 24 04 a4 88 10 	movl   $0x801088a4,0x4(%esp)
80103aeb:	80 
80103aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aef:	89 04 24             	mov    %eax,(%esp)
80103af2:	e8 26 17 00 00       	call   8010521d <memcmp>
80103af7:	85 c0                	test   %eax,%eax
80103af9:	75 1c                	jne    80103b17 <mpsearch1+0x60>
80103afb:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103b02:	00 
80103b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b06:	89 04 24             	mov    %eax,(%esp)
80103b09:	e8 73 ff ff ff       	call   80103a81 <sum>
80103b0e:	84 c0                	test   %al,%al
80103b10:	75 05                	jne    80103b17 <mpsearch1+0x60>
      return (struct mp*)p;
80103b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b15:	eb 11                	jmp    80103b28 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103b17:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b1e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b21:	72 b9                	jb     80103adc <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103b23:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103b28:	c9                   	leave  
80103b29:	c3                   	ret    

80103b2a <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103b2a:	55                   	push   %ebp
80103b2b:	89 e5                	mov    %esp,%ebp
80103b2d:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103b30:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103b37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b3a:	83 c0 0f             	add    $0xf,%eax
80103b3d:	0f b6 00             	movzbl (%eax),%eax
80103b40:	0f b6 c0             	movzbl %al,%eax
80103b43:	89 c2                	mov    %eax,%edx
80103b45:	c1 e2 08             	shl    $0x8,%edx
80103b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b4b:	83 c0 0e             	add    $0xe,%eax
80103b4e:	0f b6 00             	movzbl (%eax),%eax
80103b51:	0f b6 c0             	movzbl %al,%eax
80103b54:	09 d0                	or     %edx,%eax
80103b56:	c1 e0 04             	shl    $0x4,%eax
80103b59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b60:	74 21                	je     80103b83 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103b62:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103b69:	00 
80103b6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b6d:	89 04 24             	mov    %eax,(%esp)
80103b70:	e8 42 ff ff ff       	call   80103ab7 <mpsearch1>
80103b75:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b78:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b7c:	74 50                	je     80103bce <mpsearch+0xa4>
      return mp;
80103b7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b81:	eb 5f                	jmp    80103be2 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b86:	83 c0 14             	add    $0x14,%eax
80103b89:	0f b6 00             	movzbl (%eax),%eax
80103b8c:	0f b6 c0             	movzbl %al,%eax
80103b8f:	89 c2                	mov    %eax,%edx
80103b91:	c1 e2 08             	shl    $0x8,%edx
80103b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b97:	83 c0 13             	add    $0x13,%eax
80103b9a:	0f b6 00             	movzbl (%eax),%eax
80103b9d:	0f b6 c0             	movzbl %al,%eax
80103ba0:	09 d0                	or     %edx,%eax
80103ba2:	c1 e0 0a             	shl    $0xa,%eax
80103ba5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103ba8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bab:	2d 00 04 00 00       	sub    $0x400,%eax
80103bb0:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103bb7:	00 
80103bb8:	89 04 24             	mov    %eax,(%esp)
80103bbb:	e8 f7 fe ff ff       	call   80103ab7 <mpsearch1>
80103bc0:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103bc3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103bc7:	74 05                	je     80103bce <mpsearch+0xa4>
      return mp;
80103bc9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bcc:	eb 14                	jmp    80103be2 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103bce:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103bd5:	00 
80103bd6:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103bdd:	e8 d5 fe ff ff       	call   80103ab7 <mpsearch1>
}
80103be2:	c9                   	leave  
80103be3:	c3                   	ret    

80103be4 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103be4:	55                   	push   %ebp
80103be5:	89 e5                	mov    %esp,%ebp
80103be7:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103bea:	e8 3b ff ff ff       	call   80103b2a <mpsearch>
80103bef:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bf2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103bf6:	74 0a                	je     80103c02 <mpconfig+0x1e>
80103bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bfb:	8b 40 04             	mov    0x4(%eax),%eax
80103bfe:	85 c0                	test   %eax,%eax
80103c00:	75 0a                	jne    80103c0c <mpconfig+0x28>
    return 0;
80103c02:	b8 00 00 00 00       	mov    $0x0,%eax
80103c07:	e9 83 00 00 00       	jmp    80103c8f <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103c0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c0f:	8b 40 04             	mov    0x4(%eax),%eax
80103c12:	89 04 24             	mov    %eax,(%esp)
80103c15:	e8 f2 fd ff ff       	call   80103a0c <p2v>
80103c1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103c1d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103c24:	00 
80103c25:	c7 44 24 04 a9 88 10 	movl   $0x801088a9,0x4(%esp)
80103c2c:	80 
80103c2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c30:	89 04 24             	mov    %eax,(%esp)
80103c33:	e8 e5 15 00 00       	call   8010521d <memcmp>
80103c38:	85 c0                	test   %eax,%eax
80103c3a:	74 07                	je     80103c43 <mpconfig+0x5f>
    return 0;
80103c3c:	b8 00 00 00 00       	mov    $0x0,%eax
80103c41:	eb 4c                	jmp    80103c8f <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103c43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c46:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c4a:	3c 01                	cmp    $0x1,%al
80103c4c:	74 12                	je     80103c60 <mpconfig+0x7c>
80103c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c51:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c55:	3c 04                	cmp    $0x4,%al
80103c57:	74 07                	je     80103c60 <mpconfig+0x7c>
    return 0;
80103c59:	b8 00 00 00 00       	mov    $0x0,%eax
80103c5e:	eb 2f                	jmp    80103c8f <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103c60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c63:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c67:	0f b7 c0             	movzwl %ax,%eax
80103c6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c71:	89 04 24             	mov    %eax,(%esp)
80103c74:	e8 08 fe ff ff       	call   80103a81 <sum>
80103c79:	84 c0                	test   %al,%al
80103c7b:	74 07                	je     80103c84 <mpconfig+0xa0>
    return 0;
80103c7d:	b8 00 00 00 00       	mov    $0x0,%eax
80103c82:	eb 0b                	jmp    80103c8f <mpconfig+0xab>
  *pmp = mp;
80103c84:	8b 45 08             	mov    0x8(%ebp),%eax
80103c87:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c8a:	89 10                	mov    %edx,(%eax)
  return conf;
80103c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103c8f:	c9                   	leave  
80103c90:	c3                   	ret    

80103c91 <mpinit>:

void
mpinit(void)
{
80103c91:	55                   	push   %ebp
80103c92:	89 e5                	mov    %esp,%ebp
80103c94:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103c97:	c7 05 44 b6 10 80 60 	movl   $0x80112360,0x8010b644
80103c9e:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103ca1:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103ca4:	89 04 24             	mov    %eax,(%esp)
80103ca7:	e8 38 ff ff ff       	call   80103be4 <mpconfig>
80103cac:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103caf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103cb3:	0f 84 9c 01 00 00    	je     80103e55 <mpinit+0x1c4>
    return;
  ismp = 1;
80103cb9:	c7 05 44 23 11 80 01 	movl   $0x1,0x80112344
80103cc0:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103cc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cc6:	8b 40 24             	mov    0x24(%eax),%eax
80103cc9:	a3 5c 22 11 80       	mov    %eax,0x8011225c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cd1:	83 c0 2c             	add    $0x2c,%eax
80103cd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cda:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103cde:	0f b7 c0             	movzwl %ax,%eax
80103ce1:	03 45 f0             	add    -0x10(%ebp),%eax
80103ce4:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103ce7:	e9 f4 00 00 00       	jmp    80103de0 <mpinit+0x14f>
    switch(*p){
80103cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cef:	0f b6 00             	movzbl (%eax),%eax
80103cf2:	0f b6 c0             	movzbl %al,%eax
80103cf5:	83 f8 04             	cmp    $0x4,%eax
80103cf8:	0f 87 bf 00 00 00    	ja     80103dbd <mpinit+0x12c>
80103cfe:	8b 04 85 ec 88 10 80 	mov    -0x7fef7714(,%eax,4),%eax
80103d05:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103d07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d0a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103d0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d10:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d14:	0f b6 d0             	movzbl %al,%edx
80103d17:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d1c:	39 c2                	cmp    %eax,%edx
80103d1e:	74 2d                	je     80103d4d <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103d20:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d23:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d27:	0f b6 d0             	movzbl %al,%edx
80103d2a:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d2f:	89 54 24 08          	mov    %edx,0x8(%esp)
80103d33:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d37:	c7 04 24 ae 88 10 80 	movl   $0x801088ae,(%esp)
80103d3e:	e8 5e c6 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103d43:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103d4a:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103d4d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103d50:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103d54:	0f b6 c0             	movzbl %al,%eax
80103d57:	83 e0 02             	and    $0x2,%eax
80103d5a:	85 c0                	test   %eax,%eax
80103d5c:	74 15                	je     80103d73 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103d5e:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d63:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103d69:	05 60 23 11 80       	add    $0x80112360,%eax
80103d6e:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103d73:	8b 15 40 29 11 80    	mov    0x80112940,%edx
80103d79:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d7e:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103d84:	81 c2 60 23 11 80    	add    $0x80112360,%edx
80103d8a:	88 02                	mov    %al,(%edx)
      ncpu++;
80103d8c:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d91:	83 c0 01             	add    $0x1,%eax
80103d94:	a3 40 29 11 80       	mov    %eax,0x80112940
      p += sizeof(struct mpproc);
80103d99:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103d9d:	eb 41                	jmp    80103de0 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103d9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103da2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103da5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103da8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103dac:	a2 40 23 11 80       	mov    %al,0x80112340
      p += sizeof(struct mpioapic);
80103db1:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103db5:	eb 29                	jmp    80103de0 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103db7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103dbb:	eb 23                	jmp    80103de0 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dc0:	0f b6 00             	movzbl (%eax),%eax
80103dc3:	0f b6 c0             	movzbl %al,%eax
80103dc6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103dca:	c7 04 24 cc 88 10 80 	movl   $0x801088cc,(%esp)
80103dd1:	e8 cb c5 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103dd6:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103ddd:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103de3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103de6:	0f 82 00 ff ff ff    	jb     80103cec <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103dec:	a1 44 23 11 80       	mov    0x80112344,%eax
80103df1:	85 c0                	test   %eax,%eax
80103df3:	75 1d                	jne    80103e12 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103df5:	c7 05 40 29 11 80 01 	movl   $0x1,0x80112940
80103dfc:	00 00 00 
    lapic = 0;
80103dff:	c7 05 5c 22 11 80 00 	movl   $0x0,0x8011225c
80103e06:	00 00 00 
    ioapicid = 0;
80103e09:	c6 05 40 23 11 80 00 	movb   $0x0,0x80112340
    return;
80103e10:	eb 44                	jmp    80103e56 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103e15:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103e19:	84 c0                	test   %al,%al
80103e1b:	74 39                	je     80103e56 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103e1d:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103e24:	00 
80103e25:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103e2c:	e8 12 fc ff ff       	call   80103a43 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103e31:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e38:	e8 dc fb ff ff       	call   80103a19 <inb>
80103e3d:	83 c8 01             	or     $0x1,%eax
80103e40:	0f b6 c0             	movzbl %al,%eax
80103e43:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e47:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103e4e:	e8 f0 fb ff ff       	call   80103a43 <outb>
80103e53:	eb 01                	jmp    80103e56 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103e55:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103e56:	c9                   	leave  
80103e57:	c3                   	ret    

80103e58 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e58:	55                   	push   %ebp
80103e59:	89 e5                	mov    %esp,%ebp
80103e5b:	83 ec 08             	sub    $0x8,%esp
80103e5e:	8b 55 08             	mov    0x8(%ebp),%edx
80103e61:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e64:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103e68:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103e6b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103e6f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103e73:	ee                   	out    %al,(%dx)
}
80103e74:	c9                   	leave  
80103e75:	c3                   	ret    

80103e76 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103e76:	55                   	push   %ebp
80103e77:	89 e5                	mov    %esp,%ebp
80103e79:	83 ec 0c             	sub    $0xc,%esp
80103e7c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e7f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103e83:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e87:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103e8d:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e91:	0f b6 c0             	movzbl %al,%eax
80103e94:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e98:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e9f:	e8 b4 ff ff ff       	call   80103e58 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103ea4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ea8:	66 c1 e8 08          	shr    $0x8,%ax
80103eac:	0f b6 c0             	movzbl %al,%eax
80103eaf:	89 44 24 04          	mov    %eax,0x4(%esp)
80103eb3:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103eba:	e8 99 ff ff ff       	call   80103e58 <outb>
}
80103ebf:	c9                   	leave  
80103ec0:	c3                   	ret    

80103ec1 <picenable>:

void
picenable(int irq)
{
80103ec1:	55                   	push   %ebp
80103ec2:	89 e5                	mov    %esp,%ebp
80103ec4:	53                   	push   %ebx
80103ec5:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103ec8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ecb:	ba 01 00 00 00       	mov    $0x1,%edx
80103ed0:	89 d3                	mov    %edx,%ebx
80103ed2:	89 c1                	mov    %eax,%ecx
80103ed4:	d3 e3                	shl    %cl,%ebx
80103ed6:	89 d8                	mov    %ebx,%eax
80103ed8:	89 c2                	mov    %eax,%edx
80103eda:	f7 d2                	not    %edx
80103edc:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103ee3:	21 d0                	and    %edx,%eax
80103ee5:	0f b7 c0             	movzwl %ax,%eax
80103ee8:	89 04 24             	mov    %eax,(%esp)
80103eeb:	e8 86 ff ff ff       	call   80103e76 <picsetmask>
}
80103ef0:	83 c4 04             	add    $0x4,%esp
80103ef3:	5b                   	pop    %ebx
80103ef4:	5d                   	pop    %ebp
80103ef5:	c3                   	ret    

80103ef6 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103ef6:	55                   	push   %ebp
80103ef7:	89 e5                	mov    %esp,%ebp
80103ef9:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103efc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f03:	00 
80103f04:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f0b:	e8 48 ff ff ff       	call   80103e58 <outb>
  outb(IO_PIC2+1, 0xFF);
80103f10:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103f17:	00 
80103f18:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f1f:	e8 34 ff ff ff       	call   80103e58 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103f24:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f2b:	00 
80103f2c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f33:	e8 20 ff ff ff       	call   80103e58 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103f38:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103f3f:	00 
80103f40:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f47:	e8 0c ff ff ff       	call   80103e58 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103f4c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103f53:	00 
80103f54:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f5b:	e8 f8 fe ff ff       	call   80103e58 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103f60:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103f67:	00 
80103f68:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f6f:	e8 e4 fe ff ff       	call   80103e58 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103f74:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f7b:	00 
80103f7c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f83:	e8 d0 fe ff ff       	call   80103e58 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103f88:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103f8f:	00 
80103f90:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f97:	e8 bc fe ff ff       	call   80103e58 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103f9c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103fa3:	00 
80103fa4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fab:	e8 a8 fe ff ff       	call   80103e58 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103fb0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103fb7:	00 
80103fb8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fbf:	e8 94 fe ff ff       	call   80103e58 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103fc4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103fcb:	00 
80103fcc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103fd3:	e8 80 fe ff ff       	call   80103e58 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103fd8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103fdf:	00 
80103fe0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103fe7:	e8 6c fe ff ff       	call   80103e58 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103fec:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103ff3:	00 
80103ff4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ffb:	e8 58 fe ff ff       	call   80103e58 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104000:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104007:	00 
80104008:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010400f:	e8 44 fe ff ff       	call   80103e58 <outb>

  if(irqmask != 0xFFFF)
80104014:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
8010401b:	66 83 f8 ff          	cmp    $0xffff,%ax
8010401f:	74 12                	je     80104033 <picinit+0x13d>
    picsetmask(irqmask);
80104021:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104028:	0f b7 c0             	movzwl %ax,%eax
8010402b:	89 04 24             	mov    %eax,(%esp)
8010402e:	e8 43 fe ff ff       	call   80103e76 <picsetmask>
}
80104033:	c9                   	leave  
80104034:	c3                   	ret    
80104035:	00 00                	add    %al,(%eax)
	...

80104038 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104038:	55                   	push   %ebp
80104039:	89 e5                	mov    %esp,%ebp
8010403b:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010403e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104045:	8b 45 0c             	mov    0xc(%ebp),%eax
80104048:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010404e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104051:	8b 10                	mov    (%eax),%edx
80104053:	8b 45 08             	mov    0x8(%ebp),%eax
80104056:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104058:	e8 e7 ce ff ff       	call   80100f44 <filealloc>
8010405d:	8b 55 08             	mov    0x8(%ebp),%edx
80104060:	89 02                	mov    %eax,(%edx)
80104062:	8b 45 08             	mov    0x8(%ebp),%eax
80104065:	8b 00                	mov    (%eax),%eax
80104067:	85 c0                	test   %eax,%eax
80104069:	0f 84 c8 00 00 00    	je     80104137 <pipealloc+0xff>
8010406f:	e8 d0 ce ff ff       	call   80100f44 <filealloc>
80104074:	8b 55 0c             	mov    0xc(%ebp),%edx
80104077:	89 02                	mov    %eax,(%edx)
80104079:	8b 45 0c             	mov    0xc(%ebp),%eax
8010407c:	8b 00                	mov    (%eax),%eax
8010407e:	85 c0                	test   %eax,%eax
80104080:	0f 84 b1 00 00 00    	je     80104137 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104086:	e8 38 eb ff ff       	call   80102bc3 <kalloc>
8010408b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010408e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104092:	0f 84 9e 00 00 00    	je     80104136 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010409b:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801040a2:	00 00 00 
  p->writeopen = 1;
801040a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040a8:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801040af:	00 00 00 
  p->nwrite = 0;
801040b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040b5:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801040bc:	00 00 00 
  p->nread = 0;
801040bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c2:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801040c9:	00 00 00 
  initlock(&p->lock, "pipe");
801040cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040cf:	c7 44 24 04 00 89 10 	movl   $0x80108900,0x4(%esp)
801040d6:	80 
801040d7:	89 04 24             	mov    %eax,(%esp)
801040da:	e8 57 0e 00 00       	call   80104f36 <initlock>
  (*f0)->type = FD_PIPE;
801040df:	8b 45 08             	mov    0x8(%ebp),%eax
801040e2:	8b 00                	mov    (%eax),%eax
801040e4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801040ea:	8b 45 08             	mov    0x8(%ebp),%eax
801040ed:	8b 00                	mov    (%eax),%eax
801040ef:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801040f3:	8b 45 08             	mov    0x8(%ebp),%eax
801040f6:	8b 00                	mov    (%eax),%eax
801040f8:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801040fc:	8b 45 08             	mov    0x8(%ebp),%eax
801040ff:	8b 00                	mov    (%eax),%eax
80104101:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104104:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104107:	8b 45 0c             	mov    0xc(%ebp),%eax
8010410a:	8b 00                	mov    (%eax),%eax
8010410c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104112:	8b 45 0c             	mov    0xc(%ebp),%eax
80104115:	8b 00                	mov    (%eax),%eax
80104117:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010411b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010411e:	8b 00                	mov    (%eax),%eax
80104120:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104124:	8b 45 0c             	mov    0xc(%ebp),%eax
80104127:	8b 00                	mov    (%eax),%eax
80104129:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010412c:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010412f:	b8 00 00 00 00       	mov    $0x0,%eax
80104134:	eb 43                	jmp    80104179 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104136:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104137:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010413b:	74 0b                	je     80104148 <pipealloc+0x110>
    kfree((char*)p);
8010413d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104140:	89 04 24             	mov    %eax,(%esp)
80104143:	e8 e2 e9 ff ff       	call   80102b2a <kfree>
  if(*f0)
80104148:	8b 45 08             	mov    0x8(%ebp),%eax
8010414b:	8b 00                	mov    (%eax),%eax
8010414d:	85 c0                	test   %eax,%eax
8010414f:	74 0d                	je     8010415e <pipealloc+0x126>
    fileclose(*f0);
80104151:	8b 45 08             	mov    0x8(%ebp),%eax
80104154:	8b 00                	mov    (%eax),%eax
80104156:	89 04 24             	mov    %eax,(%esp)
80104159:	e8 8e ce ff ff       	call   80100fec <fileclose>
  if(*f1)
8010415e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104161:	8b 00                	mov    (%eax),%eax
80104163:	85 c0                	test   %eax,%eax
80104165:	74 0d                	je     80104174 <pipealloc+0x13c>
    fileclose(*f1);
80104167:	8b 45 0c             	mov    0xc(%ebp),%eax
8010416a:	8b 00                	mov    (%eax),%eax
8010416c:	89 04 24             	mov    %eax,(%esp)
8010416f:	e8 78 ce ff ff       	call   80100fec <fileclose>
  return -1;
80104174:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104179:	c9                   	leave  
8010417a:	c3                   	ret    

8010417b <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010417b:	55                   	push   %ebp
8010417c:	89 e5                	mov    %esp,%ebp
8010417e:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104181:	8b 45 08             	mov    0x8(%ebp),%eax
80104184:	89 04 24             	mov    %eax,(%esp)
80104187:	e8 cb 0d 00 00       	call   80104f57 <acquire>
  if(writable){
8010418c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104190:	74 1f                	je     801041b1 <pipeclose+0x36>
    p->writeopen = 0;
80104192:	8b 45 08             	mov    0x8(%ebp),%eax
80104195:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010419c:	00 00 00 
    wakeup(&p->nread);
8010419f:	8b 45 08             	mov    0x8(%ebp),%eax
801041a2:	05 34 02 00 00       	add    $0x234,%eax
801041a7:	89 04 24             	mov    %eax,(%esp)
801041aa:	e8 a3 0b 00 00       	call   80104d52 <wakeup>
801041af:	eb 1d                	jmp    801041ce <pipeclose+0x53>
  } else {
    p->readopen = 0;
801041b1:	8b 45 08             	mov    0x8(%ebp),%eax
801041b4:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801041bb:	00 00 00 
    wakeup(&p->nwrite);
801041be:	8b 45 08             	mov    0x8(%ebp),%eax
801041c1:	05 38 02 00 00       	add    $0x238,%eax
801041c6:	89 04 24             	mov    %eax,(%esp)
801041c9:	e8 84 0b 00 00       	call   80104d52 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801041ce:	8b 45 08             	mov    0x8(%ebp),%eax
801041d1:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801041d7:	85 c0                	test   %eax,%eax
801041d9:	75 25                	jne    80104200 <pipeclose+0x85>
801041db:	8b 45 08             	mov    0x8(%ebp),%eax
801041de:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801041e4:	85 c0                	test   %eax,%eax
801041e6:	75 18                	jne    80104200 <pipeclose+0x85>
    release(&p->lock);
801041e8:	8b 45 08             	mov    0x8(%ebp),%eax
801041eb:	89 04 24             	mov    %eax,(%esp)
801041ee:	e8 c6 0d 00 00       	call   80104fb9 <release>
    kfree((char*)p);
801041f3:	8b 45 08             	mov    0x8(%ebp),%eax
801041f6:	89 04 24             	mov    %eax,(%esp)
801041f9:	e8 2c e9 ff ff       	call   80102b2a <kfree>
801041fe:	eb 0b                	jmp    8010420b <pipeclose+0x90>
  } else
    release(&p->lock);
80104200:	8b 45 08             	mov    0x8(%ebp),%eax
80104203:	89 04 24             	mov    %eax,(%esp)
80104206:	e8 ae 0d 00 00       	call   80104fb9 <release>
}
8010420b:	c9                   	leave  
8010420c:	c3                   	ret    

8010420d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010420d:	55                   	push   %ebp
8010420e:	89 e5                	mov    %esp,%ebp
80104210:	53                   	push   %ebx
80104211:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104214:	8b 45 08             	mov    0x8(%ebp),%eax
80104217:	89 04 24             	mov    %eax,(%esp)
8010421a:	e8 38 0d 00 00       	call   80104f57 <acquire>
  for(i = 0; i < n; i++){
8010421f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104226:	e9 a6 00 00 00       	jmp    801042d1 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
8010422b:	8b 45 08             	mov    0x8(%ebp),%eax
8010422e:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104234:	85 c0                	test   %eax,%eax
80104236:	74 0d                	je     80104245 <pipewrite+0x38>
80104238:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010423e:	8b 40 24             	mov    0x24(%eax),%eax
80104241:	85 c0                	test   %eax,%eax
80104243:	74 15                	je     8010425a <pipewrite+0x4d>
        release(&p->lock);
80104245:	8b 45 08             	mov    0x8(%ebp),%eax
80104248:	89 04 24             	mov    %eax,(%esp)
8010424b:	e8 69 0d 00 00       	call   80104fb9 <release>
        return -1;
80104250:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104255:	e9 9d 00 00 00       	jmp    801042f7 <pipewrite+0xea>
      }
      wakeup(&p->nread);
8010425a:	8b 45 08             	mov    0x8(%ebp),%eax
8010425d:	05 34 02 00 00       	add    $0x234,%eax
80104262:	89 04 24             	mov    %eax,(%esp)
80104265:	e8 e8 0a 00 00       	call   80104d52 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010426a:	8b 45 08             	mov    0x8(%ebp),%eax
8010426d:	8b 55 08             	mov    0x8(%ebp),%edx
80104270:	81 c2 38 02 00 00    	add    $0x238,%edx
80104276:	89 44 24 04          	mov    %eax,0x4(%esp)
8010427a:	89 14 24             	mov    %edx,(%esp)
8010427d:	e8 f7 09 00 00       	call   80104c79 <sleep>
80104282:	eb 01                	jmp    80104285 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104284:	90                   	nop
80104285:	8b 45 08             	mov    0x8(%ebp),%eax
80104288:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010428e:	8b 45 08             	mov    0x8(%ebp),%eax
80104291:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104297:	05 00 02 00 00       	add    $0x200,%eax
8010429c:	39 c2                	cmp    %eax,%edx
8010429e:	74 8b                	je     8010422b <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801042a0:	8b 45 08             	mov    0x8(%ebp),%eax
801042a3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801042a9:	89 c3                	mov    %eax,%ebx
801042ab:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801042b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042b4:	03 55 0c             	add    0xc(%ebp),%edx
801042b7:	0f b6 0a             	movzbl (%edx),%ecx
801042ba:	8b 55 08             	mov    0x8(%ebp),%edx
801042bd:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801042c1:	8d 50 01             	lea    0x1(%eax),%edx
801042c4:	8b 45 08             	mov    0x8(%ebp),%eax
801042c7:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801042cd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801042d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042d4:	3b 45 10             	cmp    0x10(%ebp),%eax
801042d7:	7c ab                	jl     80104284 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801042d9:	8b 45 08             	mov    0x8(%ebp),%eax
801042dc:	05 34 02 00 00       	add    $0x234,%eax
801042e1:	89 04 24             	mov    %eax,(%esp)
801042e4:	e8 69 0a 00 00       	call   80104d52 <wakeup>
  release(&p->lock);
801042e9:	8b 45 08             	mov    0x8(%ebp),%eax
801042ec:	89 04 24             	mov    %eax,(%esp)
801042ef:	e8 c5 0c 00 00       	call   80104fb9 <release>
  return n;
801042f4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801042f7:	83 c4 24             	add    $0x24,%esp
801042fa:	5b                   	pop    %ebx
801042fb:	5d                   	pop    %ebp
801042fc:	c3                   	ret    

801042fd <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801042fd:	55                   	push   %ebp
801042fe:	89 e5                	mov    %esp,%ebp
80104300:	53                   	push   %ebx
80104301:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104304:	8b 45 08             	mov    0x8(%ebp),%eax
80104307:	89 04 24             	mov    %eax,(%esp)
8010430a:	e8 48 0c 00 00       	call   80104f57 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010430f:	eb 3a                	jmp    8010434b <piperead+0x4e>
    if(proc->killed){
80104311:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104317:	8b 40 24             	mov    0x24(%eax),%eax
8010431a:	85 c0                	test   %eax,%eax
8010431c:	74 15                	je     80104333 <piperead+0x36>
      release(&p->lock);
8010431e:	8b 45 08             	mov    0x8(%ebp),%eax
80104321:	89 04 24             	mov    %eax,(%esp)
80104324:	e8 90 0c 00 00       	call   80104fb9 <release>
      return -1;
80104329:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010432e:	e9 b6 00 00 00       	jmp    801043e9 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104333:	8b 45 08             	mov    0x8(%ebp),%eax
80104336:	8b 55 08             	mov    0x8(%ebp),%edx
80104339:	81 c2 34 02 00 00    	add    $0x234,%edx
8010433f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104343:	89 14 24             	mov    %edx,(%esp)
80104346:	e8 2e 09 00 00       	call   80104c79 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010434b:	8b 45 08             	mov    0x8(%ebp),%eax
8010434e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104354:	8b 45 08             	mov    0x8(%ebp),%eax
80104357:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010435d:	39 c2                	cmp    %eax,%edx
8010435f:	75 0d                	jne    8010436e <piperead+0x71>
80104361:	8b 45 08             	mov    0x8(%ebp),%eax
80104364:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010436a:	85 c0                	test   %eax,%eax
8010436c:	75 a3                	jne    80104311 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010436e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104375:	eb 49                	jmp    801043c0 <piperead+0xc3>
    if(p->nread == p->nwrite)
80104377:	8b 45 08             	mov    0x8(%ebp),%eax
8010437a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104380:	8b 45 08             	mov    0x8(%ebp),%eax
80104383:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104389:	39 c2                	cmp    %eax,%edx
8010438b:	74 3d                	je     801043ca <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010438d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104390:	89 c2                	mov    %eax,%edx
80104392:	03 55 0c             	add    0xc(%ebp),%edx
80104395:	8b 45 08             	mov    0x8(%ebp),%eax
80104398:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010439e:	89 c3                	mov    %eax,%ebx
801043a0:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801043a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
801043a9:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801043ae:	88 0a                	mov    %cl,(%edx)
801043b0:	8d 50 01             	lea    0x1(%eax),%edx
801043b3:	8b 45 08             	mov    0x8(%ebp),%eax
801043b6:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801043bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c3:	3b 45 10             	cmp    0x10(%ebp),%eax
801043c6:	7c af                	jl     80104377 <piperead+0x7a>
801043c8:	eb 01                	jmp    801043cb <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
801043ca:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801043cb:	8b 45 08             	mov    0x8(%ebp),%eax
801043ce:	05 38 02 00 00       	add    $0x238,%eax
801043d3:	89 04 24             	mov    %eax,(%esp)
801043d6:	e8 77 09 00 00       	call   80104d52 <wakeup>
  release(&p->lock);
801043db:	8b 45 08             	mov    0x8(%ebp),%eax
801043de:	89 04 24             	mov    %eax,(%esp)
801043e1:	e8 d3 0b 00 00       	call   80104fb9 <release>
  return i;
801043e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801043e9:	83 c4 24             	add    $0x24,%esp
801043ec:	5b                   	pop    %ebx
801043ed:	5d                   	pop    %ebp
801043ee:	c3                   	ret    
	...

801043f0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801043f0:	55                   	push   %ebp
801043f1:	89 e5                	mov    %esp,%ebp
801043f3:	53                   	push   %ebx
801043f4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801043f7:	9c                   	pushf  
801043f8:	5b                   	pop    %ebx
801043f9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801043fc:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801043ff:	83 c4 10             	add    $0x10,%esp
80104402:	5b                   	pop    %ebx
80104403:	5d                   	pop    %ebp
80104404:	c3                   	ret    

80104405 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104405:	55                   	push   %ebp
80104406:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104408:	fb                   	sti    
}
80104409:	5d                   	pop    %ebp
8010440a:	c3                   	ret    

8010440b <hlt>:

static inline void
hlt(void)
{
8010440b:	55                   	push   %ebp
8010440c:	89 e5                	mov    %esp,%ebp
  asm volatile("hlt");
8010440e:	f4                   	hlt    
}
8010440f:	5d                   	pop    %ebp
80104410:	c3                   	ret    

80104411 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104411:	55                   	push   %ebp
80104412:	89 e5                	mov    %esp,%ebp
80104414:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104417:	c7 44 24 04 05 89 10 	movl   $0x80108905,0x4(%esp)
8010441e:	80 
8010441f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104426:	e8 0b 0b 00 00       	call   80104f36 <initlock>
}
8010442b:	c9                   	leave  
8010442c:	c3                   	ret    

8010442d <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010442d:	55                   	push   %ebp
8010442e:	89 e5                	mov    %esp,%ebp
80104430:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104433:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010443a:	e8 18 0b 00 00       	call   80104f57 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010443f:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104446:	eb 0e                	jmp    80104456 <allocproc+0x29>
    if(p->state == UNUSED)
80104448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444b:	8b 40 0c             	mov    0xc(%eax),%eax
8010444e:	85 c0                	test   %eax,%eax
80104450:	74 23                	je     80104475 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104452:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104456:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
8010445d:	72 e9                	jb     80104448 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010445f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104466:	e8 4e 0b 00 00       	call   80104fb9 <release>
  return 0;
8010446b:	b8 00 00 00 00       	mov    $0x0,%eax
80104470:	e9 b5 00 00 00       	jmp    8010452a <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104475:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104479:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104480:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104485:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104488:	89 42 10             	mov    %eax,0x10(%edx)
8010448b:	83 c0 01             	add    $0x1,%eax
8010448e:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104493:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010449a:	e8 1a 0b 00 00       	call   80104fb9 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010449f:	e8 1f e7 ff ff       	call   80102bc3 <kalloc>
801044a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044a7:	89 42 08             	mov    %eax,0x8(%edx)
801044aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ad:	8b 40 08             	mov    0x8(%eax),%eax
801044b0:	85 c0                	test   %eax,%eax
801044b2:	75 11                	jne    801044c5 <allocproc+0x98>
    p->state = UNUSED;
801044b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801044be:	b8 00 00 00 00       	mov    $0x0,%eax
801044c3:	eb 65                	jmp    8010452a <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801044c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c8:	8b 40 08             	mov    0x8(%eax),%eax
801044cb:	05 00 10 00 00       	add    $0x1000,%eax
801044d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801044d3:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801044d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044da:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044dd:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801044e0:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801044e4:	ba d4 65 10 80       	mov    $0x801065d4,%edx
801044e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044ec:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801044ee:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801044f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044f8:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801044fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044fe:	8b 40 1c             	mov    0x1c(%eax),%eax
80104501:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104508:	00 
80104509:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104510:	00 
80104511:	89 04 24             	mov    %eax,(%esp)
80104514:	e8 8d 0c 00 00       	call   801051a6 <memset>
  p->context->eip = (uint)forkret;
80104519:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010451c:	8b 40 1c             	mov    0x1c(%eax),%eax
8010451f:	ba 3a 4c 10 80       	mov    $0x80104c3a,%edx
80104524:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104527:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010452a:	c9                   	leave  
8010452b:	c3                   	ret    

8010452c <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010452c:	55                   	push   %ebp
8010452d:	89 e5                	mov    %esp,%ebp
8010452f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104532:	e8 f6 fe ff ff       	call   8010442d <allocproc>
80104537:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
8010453a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010453d:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104542:	e8 12 38 00 00       	call   80107d59 <setupkvm>
80104547:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010454a:	89 42 04             	mov    %eax,0x4(%edx)
8010454d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104550:	8b 40 04             	mov    0x4(%eax),%eax
80104553:	85 c0                	test   %eax,%eax
80104555:	75 0c                	jne    80104563 <userinit+0x37>
    panic("userinit: out of memory?");
80104557:	c7 04 24 0c 89 10 80 	movl   $0x8010890c,(%esp)
8010455e:	e8 da bf ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104563:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104568:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456b:	8b 40 04             	mov    0x4(%eax),%eax
8010456e:	89 54 24 08          	mov    %edx,0x8(%esp)
80104572:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104579:	80 
8010457a:	89 04 24             	mov    %eax,(%esp)
8010457d:	e8 2f 3a 00 00       	call   80107fb1 <inituvm>
  p->sz = PGSIZE;
80104582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104585:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
8010458b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010458e:	8b 40 18             	mov    0x18(%eax),%eax
80104591:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104598:	00 
80104599:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045a0:	00 
801045a1:	89 04 24             	mov    %eax,(%esp)
801045a4:	e8 fd 0b 00 00       	call   801051a6 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801045a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ac:	8b 40 18             	mov    0x18(%eax),%eax
801045af:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801045b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b8:	8b 40 18             	mov    0x18(%eax),%eax
801045bb:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801045c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c4:	8b 40 18             	mov    0x18(%eax),%eax
801045c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045ca:	8b 52 18             	mov    0x18(%edx),%edx
801045cd:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045d1:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801045d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d8:	8b 40 18             	mov    0x18(%eax),%eax
801045db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045de:	8b 52 18             	mov    0x18(%edx),%edx
801045e1:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045e5:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801045e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ec:	8b 40 18             	mov    0x18(%eax),%eax
801045ef:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801045f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f9:	8b 40 18             	mov    0x18(%eax),%eax
801045fc:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104606:	8b 40 18             	mov    0x18(%eax),%eax
80104609:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104610:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104613:	83 c0 6c             	add    $0x6c,%eax
80104616:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010461d:	00 
8010461e:	c7 44 24 04 25 89 10 	movl   $0x80108925,0x4(%esp)
80104625:	80 
80104626:	89 04 24             	mov    %eax,(%esp)
80104629:	e8 a8 0d 00 00       	call   801053d6 <safestrcpy>
  p->cwd = namei("/");
8010462e:	c7 04 24 2e 89 10 80 	movl   $0x8010892e,(%esp)
80104635:	e8 5f de ff ff       	call   80102499 <namei>
8010463a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010463d:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104640:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104643:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
8010464a:	c9                   	leave  
8010464b:	c3                   	ret    

8010464c <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010464c:	55                   	push   %ebp
8010464d:	89 e5                	mov    %esp,%ebp
8010464f:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104652:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104658:	8b 00                	mov    (%eax),%eax
8010465a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010465d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104661:	7e 34                	jle    80104697 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104663:	8b 45 08             	mov    0x8(%ebp),%eax
80104666:	89 c2                	mov    %eax,%edx
80104668:	03 55 f4             	add    -0xc(%ebp),%edx
8010466b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104671:	8b 40 04             	mov    0x4(%eax),%eax
80104674:	89 54 24 08          	mov    %edx,0x8(%esp)
80104678:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010467b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010467f:	89 04 24             	mov    %eax,(%esp)
80104682:	e8 a4 3a 00 00       	call   8010812b <allocuvm>
80104687:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010468a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010468e:	75 41                	jne    801046d1 <growproc+0x85>
      return -1;
80104690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104695:	eb 58                	jmp    801046ef <growproc+0xa3>
  } else if(n < 0){
80104697:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010469b:	79 34                	jns    801046d1 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
8010469d:	8b 45 08             	mov    0x8(%ebp),%eax
801046a0:	89 c2                	mov    %eax,%edx
801046a2:	03 55 f4             	add    -0xc(%ebp),%edx
801046a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046ab:	8b 40 04             	mov    0x4(%eax),%eax
801046ae:	89 54 24 08          	mov    %edx,0x8(%esp)
801046b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801046b9:	89 04 24             	mov    %eax,(%esp)
801046bc:	e8 44 3b 00 00       	call   80108205 <deallocuvm>
801046c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046c4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046c8:	75 07                	jne    801046d1 <growproc+0x85>
      return -1;
801046ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046cf:	eb 1e                	jmp    801046ef <growproc+0xa3>
  }
  proc->sz = sz;
801046d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046da:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801046dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046e2:	89 04 24             	mov    %eax,(%esp)
801046e5:	e8 60 37 00 00       	call   80107e4a <switchuvm>
  return 0;
801046ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046ef:	c9                   	leave  
801046f0:	c3                   	ret    

801046f1 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801046f1:	55                   	push   %ebp
801046f2:	89 e5                	mov    %esp,%ebp
801046f4:	57                   	push   %edi
801046f5:	56                   	push   %esi
801046f6:	53                   	push   %ebx
801046f7:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801046fa:	e8 2e fd ff ff       	call   8010442d <allocproc>
801046ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104702:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104706:	75 0a                	jne    80104712 <fork+0x21>
    return -1;
80104708:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010470d:	e9 52 01 00 00       	jmp    80104864 <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104712:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104718:	8b 10                	mov    (%eax),%edx
8010471a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104720:	8b 40 04             	mov    0x4(%eax),%eax
80104723:	89 54 24 04          	mov    %edx,0x4(%esp)
80104727:	89 04 24             	mov    %eax,(%esp)
8010472a:	e8 66 3c 00 00       	call   80108395 <copyuvm>
8010472f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104732:	89 42 04             	mov    %eax,0x4(%edx)
80104735:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104738:	8b 40 04             	mov    0x4(%eax),%eax
8010473b:	85 c0                	test   %eax,%eax
8010473d:	75 2c                	jne    8010476b <fork+0x7a>
    kfree(np->kstack);
8010473f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104742:	8b 40 08             	mov    0x8(%eax),%eax
80104745:	89 04 24             	mov    %eax,(%esp)
80104748:	e8 dd e3 ff ff       	call   80102b2a <kfree>
    np->kstack = 0;
8010474d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104750:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104757:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010475a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104761:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104766:	e9 f9 00 00 00       	jmp    80104864 <fork+0x173>
  }
  np->sz = proc->sz;
8010476b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104771:	8b 10                	mov    (%eax),%edx
80104773:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104776:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104778:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010477f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104782:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104785:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104788:	8b 50 18             	mov    0x18(%eax),%edx
8010478b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104791:	8b 40 18             	mov    0x18(%eax),%eax
80104794:	89 c3                	mov    %eax,%ebx
80104796:	b8 13 00 00 00       	mov    $0x13,%eax
8010479b:	89 d7                	mov    %edx,%edi
8010479d:	89 de                	mov    %ebx,%esi
8010479f:	89 c1                	mov    %eax,%ecx
801047a1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801047a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047a6:	8b 40 18             	mov    0x18(%eax),%eax
801047a9:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047b0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801047b7:	eb 3d                	jmp    801047f6 <fork+0x105>
    if(proc->ofile[i])
801047b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047bf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047c2:	83 c2 08             	add    $0x8,%edx
801047c5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047c9:	85 c0                	test   %eax,%eax
801047cb:	74 25                	je     801047f2 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801047cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047d6:	83 c2 08             	add    $0x8,%edx
801047d9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047dd:	89 04 24             	mov    %eax,(%esp)
801047e0:	e8 bf c7 ff ff       	call   80100fa4 <filedup>
801047e5:	8b 55 e0             	mov    -0x20(%ebp),%edx
801047e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801047eb:	83 c1 08             	add    $0x8,%ecx
801047ee:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801047f2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801047f6:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801047fa:	7e bd                	jle    801047b9 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801047fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104802:	8b 40 68             	mov    0x68(%eax),%eax
80104805:	89 04 24             	mov    %eax,(%esp)
80104808:	e8 b2 d0 ff ff       	call   801018bf <idup>
8010480d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104810:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104813:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104819:	8d 50 6c             	lea    0x6c(%eax),%edx
8010481c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010481f:	83 c0 6c             	add    $0x6c,%eax
80104822:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104829:	00 
8010482a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010482e:	89 04 24             	mov    %eax,(%esp)
80104831:	e8 a0 0b 00 00       	call   801053d6 <safestrcpy>
 
  pid = np->pid;
80104836:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104839:	8b 40 10             	mov    0x10(%eax),%eax
8010483c:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
8010483f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104846:	e8 0c 07 00 00       	call   80104f57 <acquire>
  np->state = RUNNABLE;
8010484b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010484e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104855:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010485c:	e8 58 07 00 00       	call   80104fb9 <release>
  
  return pid;
80104861:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104864:	83 c4 2c             	add    $0x2c,%esp
80104867:	5b                   	pop    %ebx
80104868:	5e                   	pop    %esi
80104869:	5f                   	pop    %edi
8010486a:	5d                   	pop    %ebp
8010486b:	c3                   	ret    

8010486c <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010486c:	55                   	push   %ebp
8010486d:	89 e5                	mov    %esp,%ebp
8010486f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104872:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104879:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010487e:	39 c2                	cmp    %eax,%edx
80104880:	75 0c                	jne    8010488e <exit+0x22>
    panic("init exiting");
80104882:	c7 04 24 30 89 10 80 	movl   $0x80108930,(%esp)
80104889:	e8 af bc ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010488e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104895:	eb 44                	jmp    801048db <exit+0x6f>
    if(proc->ofile[fd]){
80104897:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010489d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048a0:	83 c2 08             	add    $0x8,%edx
801048a3:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048a7:	85 c0                	test   %eax,%eax
801048a9:	74 2c                	je     801048d7 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801048ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048b1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048b4:	83 c2 08             	add    $0x8,%edx
801048b7:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048bb:	89 04 24             	mov    %eax,(%esp)
801048be:	e8 29 c7 ff ff       	call   80100fec <fileclose>
      proc->ofile[fd] = 0;
801048c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048cc:	83 c2 08             	add    $0x8,%edx
801048cf:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801048d6:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801048d7:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801048db:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801048df:	7e b6                	jle    80104897 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
801048e1:	e8 27 ec ff ff       	call   8010350d <begin_op>
  iput(proc->cwd);
801048e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ec:	8b 40 68             	mov    0x68(%eax),%eax
801048ef:	89 04 24             	mov    %eax,(%esp)
801048f2:	e8 b3 d1 ff ff       	call   80101aaa <iput>
  end_op();
801048f7:	e8 92 ec ff ff       	call   8010358e <end_op>
  proc->cwd = 0;
801048fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104902:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104909:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104910:	e8 42 06 00 00       	call   80104f57 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104915:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010491b:	8b 40 14             	mov    0x14(%eax),%eax
8010491e:	89 04 24             	mov    %eax,(%esp)
80104921:	e8 ee 03 00 00       	call   80104d14 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104926:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
8010492d:	eb 38                	jmp    80104967 <exit+0xfb>
    if(p->parent == proc){
8010492f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104932:	8b 50 14             	mov    0x14(%eax),%edx
80104935:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493b:	39 c2                	cmp    %eax,%edx
8010493d:	75 24                	jne    80104963 <exit+0xf7>
      p->parent = initproc;
8010493f:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104948:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010494b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494e:	8b 40 0c             	mov    0xc(%eax),%eax
80104951:	83 f8 05             	cmp    $0x5,%eax
80104954:	75 0d                	jne    80104963 <exit+0xf7>
        wakeup1(initproc);
80104956:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010495b:	89 04 24             	mov    %eax,(%esp)
8010495e:	e8 b1 03 00 00       	call   80104d14 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104963:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104967:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
8010496e:	72 bf                	jb     8010492f <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104970:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104976:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010497d:	e8 d4 01 00 00       	call   80104b56 <sched>
  panic("zombie exit");
80104982:	c7 04 24 3d 89 10 80 	movl   $0x8010893d,(%esp)
80104989:	e8 af bb ff ff       	call   8010053d <panic>

8010498e <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010498e:	55                   	push   %ebp
8010498f:	89 e5                	mov    %esp,%ebp
80104991:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104994:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010499b:	e8 b7 05 00 00       	call   80104f57 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801049a0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049a7:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801049ae:	e9 9a 00 00 00       	jmp    80104a4d <wait+0xbf>
      if(p->parent != proc)
801049b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b6:	8b 50 14             	mov    0x14(%eax),%edx
801049b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049bf:	39 c2                	cmp    %eax,%edx
801049c1:	0f 85 81 00 00 00    	jne    80104a48 <wait+0xba>
        continue;
      havekids = 1;
801049c7:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801049ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049d1:	8b 40 0c             	mov    0xc(%eax),%eax
801049d4:	83 f8 05             	cmp    $0x5,%eax
801049d7:	75 70                	jne    80104a49 <wait+0xbb>
        // Found one.
        pid = p->pid;
801049d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049dc:	8b 40 10             	mov    0x10(%eax),%eax
801049df:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801049e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e5:	8b 40 08             	mov    0x8(%eax),%eax
801049e8:	89 04 24             	mov    %eax,(%esp)
801049eb:	e8 3a e1 ff ff       	call   80102b2a <kfree>
        p->kstack = 0;
801049f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801049fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fd:	8b 40 04             	mov    0x4(%eax),%eax
80104a00:	89 04 24             	mov    %eax,(%esp)
80104a03:	e8 b9 38 00 00       	call   801082c1 <freevm>
        p->state = UNUSED;
80104a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a0b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a15:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a29:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a30:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104a37:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a3e:	e8 76 05 00 00       	call   80104fb9 <release>
        return pid;
80104a43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a46:	eb 53                	jmp    80104a9b <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104a48:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a49:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a4d:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104a54:	0f 82 59 ff ff ff    	jb     801049b3 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104a5a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a5e:	74 0d                	je     80104a6d <wait+0xdf>
80104a60:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a66:	8b 40 24             	mov    0x24(%eax),%eax
80104a69:	85 c0                	test   %eax,%eax
80104a6b:	74 13                	je     80104a80 <wait+0xf2>
      release(&ptable.lock);
80104a6d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a74:	e8 40 05 00 00       	call   80104fb9 <release>
      return -1;
80104a79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a7e:	eb 1b                	jmp    80104a9b <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104a80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a86:	c7 44 24 04 60 29 11 	movl   $0x80112960,0x4(%esp)
80104a8d:	80 
80104a8e:	89 04 24             	mov    %eax,(%esp)
80104a91:	e8 e3 01 00 00       	call   80104c79 <sleep>
  }
80104a96:	e9 05 ff ff ff       	jmp    801049a0 <wait+0x12>
}
80104a9b:	c9                   	leave  
80104a9c:	c3                   	ret    

80104a9d <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104a9d:	55                   	push   %ebp
80104a9e:	89 e5                	mov    %esp,%ebp
80104aa0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int foundproc = 1;
80104aa3:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104aaa:	e8 56 f9 ff ff       	call   80104405 <sti>

    if (!foundproc) hlt();
80104aaf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104ab3:	75 05                	jne    80104aba <scheduler+0x1d>
80104ab5:	e8 51 f9 ff ff       	call   8010440b <hlt>

    foundproc = 0;
80104aba:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104ac1:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ac8:	e8 8a 04 00 00       	call   80104f57 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104acd:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104ad4:	eb 66                	jmp    80104b3c <scheduler+0x9f>
      if(p->state != RUNNABLE)
80104ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad9:	8b 40 0c             	mov    0xc(%eax),%eax
80104adc:	83 f8 03             	cmp    $0x3,%eax
80104adf:	75 56                	jne    80104b37 <scheduler+0x9a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      foundproc = 1;
80104ae1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      proc = p;
80104ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aeb:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af4:	89 04 24             	mov    %eax,(%esp)
80104af7:	e8 4e 33 00 00       	call   80107e4a <switchuvm>
      p->state = RUNNING;
80104afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aff:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104b06:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b0c:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b0f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104b16:	83 c2 04             	add    $0x4,%edx
80104b19:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b1d:	89 14 24             	mov    %edx,(%esp)
80104b20:	e8 27 09 00 00       	call   8010544c <swtch>
      switchkvm();
80104b25:	e8 03 33 00 00       	call   80107e2d <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104b2a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104b31:	00 00 00 00 
80104b35:	eb 01                	jmp    80104b38 <scheduler+0x9b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104b37:	90                   	nop

    foundproc = 0;

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b38:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104b3c:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104b43:	72 91                	jb     80104ad6 <scheduler+0x39>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104b45:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b4c:	e8 68 04 00 00       	call   80104fb9 <release>

  }
80104b51:	e9 54 ff ff ff       	jmp    80104aaa <scheduler+0xd>

80104b56 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104b56:	55                   	push   %ebp
80104b57:	89 e5                	mov    %esp,%ebp
80104b59:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104b5c:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b63:	e8 0d 05 00 00       	call   80105075 <holding>
80104b68:	85 c0                	test   %eax,%eax
80104b6a:	75 0c                	jne    80104b78 <sched+0x22>
    panic("sched ptable.lock");
80104b6c:	c7 04 24 49 89 10 80 	movl   $0x80108949,(%esp)
80104b73:	e8 c5 b9 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104b78:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b7e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104b84:	83 f8 01             	cmp    $0x1,%eax
80104b87:	74 0c                	je     80104b95 <sched+0x3f>
    panic("sched locks");
80104b89:	c7 04 24 5b 89 10 80 	movl   $0x8010895b,(%esp)
80104b90:	e8 a8 b9 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104b95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b9b:	8b 40 0c             	mov    0xc(%eax),%eax
80104b9e:	83 f8 04             	cmp    $0x4,%eax
80104ba1:	75 0c                	jne    80104baf <sched+0x59>
    panic("sched running");
80104ba3:	c7 04 24 67 89 10 80 	movl   $0x80108967,(%esp)
80104baa:	e8 8e b9 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104baf:	e8 3c f8 ff ff       	call   801043f0 <readeflags>
80104bb4:	25 00 02 00 00       	and    $0x200,%eax
80104bb9:	85 c0                	test   %eax,%eax
80104bbb:	74 0c                	je     80104bc9 <sched+0x73>
    panic("sched interruptible");
80104bbd:	c7 04 24 75 89 10 80 	movl   $0x80108975,(%esp)
80104bc4:	e8 74 b9 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104bc9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bcf:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104bd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104bd8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bde:	8b 40 04             	mov    0x4(%eax),%eax
80104be1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104be8:	83 c2 1c             	add    $0x1c,%edx
80104beb:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bef:	89 14 24             	mov    %edx,(%esp)
80104bf2:	e8 55 08 00 00       	call   8010544c <swtch>
  cpu->intena = intena;
80104bf7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bfd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c00:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104c06:	c9                   	leave  
80104c07:	c3                   	ret    

80104c08 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104c08:	55                   	push   %ebp
80104c09:	89 e5                	mov    %esp,%ebp
80104c0b:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104c0e:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c15:	e8 3d 03 00 00       	call   80104f57 <acquire>
  proc->state = RUNNABLE;
80104c1a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c20:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104c27:	e8 2a ff ff ff       	call   80104b56 <sched>
  release(&ptable.lock);
80104c2c:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c33:	e8 81 03 00 00       	call   80104fb9 <release>
}
80104c38:	c9                   	leave  
80104c39:	c3                   	ret    

80104c3a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104c3a:	55                   	push   %ebp
80104c3b:	89 e5                	mov    %esp,%ebp
80104c3d:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104c40:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c47:	e8 6d 03 00 00       	call   80104fb9 <release>

  if (first) {
80104c4c:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104c51:	85 c0                	test   %eax,%eax
80104c53:	74 22                	je     80104c77 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104c55:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104c5c:	00 00 00 
    iinit(ROOTDEV);
80104c5f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80104c66:	e8 5d c9 ff ff       	call   801015c8 <iinit>
    initlog(ROOTDEV);
80104c6b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80104c72:	e8 95 e6 ff ff       	call   8010330c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104c77:	c9                   	leave  
80104c78:	c3                   	ret    

80104c79 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104c79:	55                   	push   %ebp
80104c7a:	89 e5                	mov    %esp,%ebp
80104c7c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104c7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c85:	85 c0                	test   %eax,%eax
80104c87:	75 0c                	jne    80104c95 <sleep+0x1c>
    panic("sleep");
80104c89:	c7 04 24 89 89 10 80 	movl   $0x80108989,(%esp)
80104c90:	e8 a8 b8 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104c95:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c99:	75 0c                	jne    80104ca7 <sleep+0x2e>
    panic("sleep without lk");
80104c9b:	c7 04 24 8f 89 10 80 	movl   $0x8010898f,(%esp)
80104ca2:	e8 96 b8 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104ca7:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104cae:	74 17                	je     80104cc7 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104cb0:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cb7:	e8 9b 02 00 00       	call   80104f57 <acquire>
    release(lk);
80104cbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cbf:	89 04 24             	mov    %eax,(%esp)
80104cc2:	e8 f2 02 00 00       	call   80104fb9 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104cc7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ccd:	8b 55 08             	mov    0x8(%ebp),%edx
80104cd0:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104cd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd9:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104ce0:	e8 71 fe ff ff       	call   80104b56 <sched>

  // Tidy up.
  proc->chan = 0;
80104ce5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ceb:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104cf2:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104cf9:	74 17                	je     80104d12 <sleep+0x99>
    release(&ptable.lock);
80104cfb:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d02:	e8 b2 02 00 00       	call   80104fb9 <release>
    acquire(lk);
80104d07:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d0a:	89 04 24             	mov    %eax,(%esp)
80104d0d:	e8 45 02 00 00       	call   80104f57 <acquire>
  }
}
80104d12:	c9                   	leave  
80104d13:	c3                   	ret    

80104d14 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104d14:	55                   	push   %ebp
80104d15:	89 e5                	mov    %esp,%ebp
80104d17:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104d1a:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104d21:	eb 24                	jmp    80104d47 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104d23:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d26:	8b 40 0c             	mov    0xc(%eax),%eax
80104d29:	83 f8 02             	cmp    $0x2,%eax
80104d2c:	75 15                	jne    80104d43 <wakeup1+0x2f>
80104d2e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d31:	8b 40 20             	mov    0x20(%eax),%eax
80104d34:	3b 45 08             	cmp    0x8(%ebp),%eax
80104d37:	75 0a                	jne    80104d43 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104d39:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d3c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104d43:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104d47:	81 7d fc 94 48 11 80 	cmpl   $0x80114894,-0x4(%ebp)
80104d4e:	72 d3                	jb     80104d23 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104d50:	c9                   	leave  
80104d51:	c3                   	ret    

80104d52 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104d52:	55                   	push   %ebp
80104d53:	89 e5                	mov    %esp,%ebp
80104d55:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104d58:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d5f:	e8 f3 01 00 00       	call   80104f57 <acquire>
  wakeup1(chan);
80104d64:	8b 45 08             	mov    0x8(%ebp),%eax
80104d67:	89 04 24             	mov    %eax,(%esp)
80104d6a:	e8 a5 ff ff ff       	call   80104d14 <wakeup1>
  release(&ptable.lock);
80104d6f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d76:	e8 3e 02 00 00       	call   80104fb9 <release>
}
80104d7b:	c9                   	leave  
80104d7c:	c3                   	ret    

80104d7d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104d7d:	55                   	push   %ebp
80104d7e:	89 e5                	mov    %esp,%ebp
80104d80:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104d83:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d8a:	e8 c8 01 00 00       	call   80104f57 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d8f:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104d96:	eb 41                	jmp    80104dd9 <kill+0x5c>
    if(p->pid == pid){
80104d98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d9b:	8b 40 10             	mov    0x10(%eax),%eax
80104d9e:	3b 45 08             	cmp    0x8(%ebp),%eax
80104da1:	75 32                	jne    80104dd5 <kill+0x58>
      p->killed = 1;
80104da3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104da6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db0:	8b 40 0c             	mov    0xc(%eax),%eax
80104db3:	83 f8 02             	cmp    $0x2,%eax
80104db6:	75 0a                	jne    80104dc2 <kill+0x45>
        p->state = RUNNABLE;
80104db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dbb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104dc2:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104dc9:	e8 eb 01 00 00       	call   80104fb9 <release>
      return 0;
80104dce:	b8 00 00 00 00       	mov    $0x0,%eax
80104dd3:	eb 1e                	jmp    80104df3 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dd5:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104dd9:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104de0:	72 b6                	jb     80104d98 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104de2:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104de9:	e8 cb 01 00 00       	call   80104fb9 <release>
  return -1;
80104dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104df3:	c9                   	leave  
80104df4:	c3                   	ret    

80104df5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104df5:	55                   	push   %ebp
80104df6:	89 e5                	mov    %esp,%ebp
80104df8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dfb:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104e02:	e9 d8 00 00 00       	jmp    80104edf <procdump+0xea>
    if(p->state == UNUSED)
80104e07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e0a:	8b 40 0c             	mov    0xc(%eax),%eax
80104e0d:	85 c0                	test   %eax,%eax
80104e0f:	0f 84 c5 00 00 00    	je     80104eda <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104e15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e18:	8b 40 0c             	mov    0xc(%eax),%eax
80104e1b:	83 f8 05             	cmp    $0x5,%eax
80104e1e:	77 23                	ja     80104e43 <procdump+0x4e>
80104e20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e23:	8b 40 0c             	mov    0xc(%eax),%eax
80104e26:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104e2d:	85 c0                	test   %eax,%eax
80104e2f:	74 12                	je     80104e43 <procdump+0x4e>
      state = states[p->state];
80104e31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e34:	8b 40 0c             	mov    0xc(%eax),%eax
80104e37:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104e3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104e41:	eb 07                	jmp    80104e4a <procdump+0x55>
    else
      state = "???";
80104e43:	c7 45 ec a0 89 10 80 	movl   $0x801089a0,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104e4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e4d:	8d 50 6c             	lea    0x6c(%eax),%edx
80104e50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e53:	8b 40 10             	mov    0x10(%eax),%eax
80104e56:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e5a:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104e5d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e61:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e65:	c7 04 24 a4 89 10 80 	movl   $0x801089a4,(%esp)
80104e6c:	e8 30 b5 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104e71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e74:	8b 40 0c             	mov    0xc(%eax),%eax
80104e77:	83 f8 02             	cmp    $0x2,%eax
80104e7a:	75 50                	jne    80104ecc <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104e7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e7f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104e82:	8b 40 0c             	mov    0xc(%eax),%eax
80104e85:	83 c0 08             	add    $0x8,%eax
80104e88:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104e8b:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e8f:	89 04 24             	mov    %eax,(%esp)
80104e92:	e8 71 01 00 00       	call   80105008 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104e97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e9e:	eb 1b                	jmp    80104ebb <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104ea0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ea3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104ea7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104eab:	c7 04 24 ad 89 10 80 	movl   $0x801089ad,(%esp)
80104eb2:	e8 ea b4 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104eb7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104ebb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104ebf:	7f 0b                	jg     80104ecc <procdump+0xd7>
80104ec1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec4:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104ec8:	85 c0                	test   %eax,%eax
80104eca:	75 d4                	jne    80104ea0 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104ecc:	c7 04 24 b1 89 10 80 	movl   $0x801089b1,(%esp)
80104ed3:	e8 c9 b4 ff ff       	call   801003a1 <cprintf>
80104ed8:	eb 01                	jmp    80104edb <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104eda:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104edb:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104edf:	81 7d f0 94 48 11 80 	cmpl   $0x80114894,-0x10(%ebp)
80104ee6:	0f 82 1b ff ff ff    	jb     80104e07 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104eec:	c9                   	leave  
80104eed:	c3                   	ret    
	...

80104ef0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104ef0:	55                   	push   %ebp
80104ef1:	89 e5                	mov    %esp,%ebp
80104ef3:	53                   	push   %ebx
80104ef4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104ef7:	9c                   	pushf  
80104ef8:	5b                   	pop    %ebx
80104ef9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104efc:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104eff:	83 c4 10             	add    $0x10,%esp
80104f02:	5b                   	pop    %ebx
80104f03:	5d                   	pop    %ebp
80104f04:	c3                   	ret    

80104f05 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104f05:	55                   	push   %ebp
80104f06:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f08:	fa                   	cli    
}
80104f09:	5d                   	pop    %ebp
80104f0a:	c3                   	ret    

80104f0b <sti>:

static inline void
sti(void)
{
80104f0b:	55                   	push   %ebp
80104f0c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104f0e:	fb                   	sti    
}
80104f0f:	5d                   	pop    %ebp
80104f10:	c3                   	ret    

80104f11 <xchg>:
  asm volatile("hlt");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104f11:	55                   	push   %ebp
80104f12:	89 e5                	mov    %esp,%ebp
80104f14:	53                   	push   %ebx
80104f15:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104f18:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104f1e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104f21:	89 c3                	mov    %eax,%ebx
80104f23:	89 d8                	mov    %ebx,%eax
80104f25:	f0 87 02             	lock xchg %eax,(%edx)
80104f28:	89 c3                	mov    %eax,%ebx
80104f2a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104f2d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104f30:	83 c4 10             	add    $0x10,%esp
80104f33:	5b                   	pop    %ebx
80104f34:	5d                   	pop    %ebp
80104f35:	c3                   	ret    

80104f36 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104f36:	55                   	push   %ebp
80104f37:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104f39:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3c:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f3f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104f42:	8b 45 08             	mov    0x8(%ebp),%eax
80104f45:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104f55:	5d                   	pop    %ebp
80104f56:	c3                   	ret    

80104f57 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104f57:	55                   	push   %ebp
80104f58:	89 e5                	mov    %esp,%ebp
80104f5a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104f5d:	e8 3d 01 00 00       	call   8010509f <pushcli>
  if(holding(lk))
80104f62:	8b 45 08             	mov    0x8(%ebp),%eax
80104f65:	89 04 24             	mov    %eax,(%esp)
80104f68:	e8 08 01 00 00       	call   80105075 <holding>
80104f6d:	85 c0                	test   %eax,%eax
80104f6f:	74 0c                	je     80104f7d <acquire+0x26>
    panic("acquire");
80104f71:	c7 04 24 dd 89 10 80 	movl   $0x801089dd,(%esp)
80104f78:	e8 c0 b5 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104f7d:	90                   	nop
80104f7e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f81:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104f88:	00 
80104f89:	89 04 24             	mov    %eax,(%esp)
80104f8c:	e8 80 ff ff ff       	call   80104f11 <xchg>
80104f91:	85 c0                	test   %eax,%eax
80104f93:	75 e9                	jne    80104f7e <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104f95:	8b 45 08             	mov    0x8(%ebp),%eax
80104f98:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104f9f:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104fa2:	8b 45 08             	mov    0x8(%ebp),%eax
80104fa5:	83 c0 0c             	add    $0xc,%eax
80104fa8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fac:	8d 45 08             	lea    0x8(%ebp),%eax
80104faf:	89 04 24             	mov    %eax,(%esp)
80104fb2:	e8 51 00 00 00       	call   80105008 <getcallerpcs>
}
80104fb7:	c9                   	leave  
80104fb8:	c3                   	ret    

80104fb9 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104fb9:	55                   	push   %ebp
80104fba:	89 e5                	mov    %esp,%ebp
80104fbc:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104fbf:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc2:	89 04 24             	mov    %eax,(%esp)
80104fc5:	e8 ab 00 00 00       	call   80105075 <holding>
80104fca:	85 c0                	test   %eax,%eax
80104fcc:	75 0c                	jne    80104fda <release+0x21>
    panic("release");
80104fce:	c7 04 24 e5 89 10 80 	movl   $0x801089e5,(%esp)
80104fd5:	e8 63 b5 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104fda:	8b 45 08             	mov    0x8(%ebp),%eax
80104fdd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104fe4:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104fee:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104ff8:	00 
80104ff9:	89 04 24             	mov    %eax,(%esp)
80104ffc:	e8 10 ff ff ff       	call   80104f11 <xchg>

  popcli();
80105001:	e8 e1 00 00 00       	call   801050e7 <popcli>
}
80105006:	c9                   	leave  
80105007:	c3                   	ret    

80105008 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105008:	55                   	push   %ebp
80105009:	89 e5                	mov    %esp,%ebp
8010500b:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
8010500e:	8b 45 08             	mov    0x8(%ebp),%eax
80105011:	83 e8 08             	sub    $0x8,%eax
80105014:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105017:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010501e:	eb 32                	jmp    80105052 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105020:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105024:	74 47                	je     8010506d <getcallerpcs+0x65>
80105026:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010502d:	76 3e                	jbe    8010506d <getcallerpcs+0x65>
8010502f:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105033:	74 38                	je     8010506d <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105035:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105038:	c1 e0 02             	shl    $0x2,%eax
8010503b:	03 45 0c             	add    0xc(%ebp),%eax
8010503e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105041:	8b 52 04             	mov    0x4(%edx),%edx
80105044:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105046:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105049:	8b 00                	mov    (%eax),%eax
8010504b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010504e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105052:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105056:	7e c8                	jle    80105020 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105058:	eb 13                	jmp    8010506d <getcallerpcs+0x65>
    pcs[i] = 0;
8010505a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010505d:	c1 e0 02             	shl    $0x2,%eax
80105060:	03 45 0c             	add    0xc(%ebp),%eax
80105063:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105069:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010506d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105071:	7e e7                	jle    8010505a <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105073:	c9                   	leave  
80105074:	c3                   	ret    

80105075 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105075:	55                   	push   %ebp
80105076:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105078:	8b 45 08             	mov    0x8(%ebp),%eax
8010507b:	8b 00                	mov    (%eax),%eax
8010507d:	85 c0                	test   %eax,%eax
8010507f:	74 17                	je     80105098 <holding+0x23>
80105081:	8b 45 08             	mov    0x8(%ebp),%eax
80105084:	8b 50 08             	mov    0x8(%eax),%edx
80105087:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010508d:	39 c2                	cmp    %eax,%edx
8010508f:	75 07                	jne    80105098 <holding+0x23>
80105091:	b8 01 00 00 00       	mov    $0x1,%eax
80105096:	eb 05                	jmp    8010509d <holding+0x28>
80105098:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010509d:	5d                   	pop    %ebp
8010509e:	c3                   	ret    

8010509f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010509f:	55                   	push   %ebp
801050a0:	89 e5                	mov    %esp,%ebp
801050a2:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801050a5:	e8 46 fe ff ff       	call   80104ef0 <readeflags>
801050aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801050ad:	e8 53 fe ff ff       	call   80104f05 <cli>
  if(cpu->ncli++ == 0)
801050b2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801050b8:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801050be:	85 d2                	test   %edx,%edx
801050c0:	0f 94 c1             	sete   %cl
801050c3:	83 c2 01             	add    $0x1,%edx
801050c6:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801050cc:	84 c9                	test   %cl,%cl
801050ce:	74 15                	je     801050e5 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
801050d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801050d6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801050d9:	81 e2 00 02 00 00    	and    $0x200,%edx
801050df:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801050e5:	c9                   	leave  
801050e6:	c3                   	ret    

801050e7 <popcli>:

void
popcli(void)
{
801050e7:	55                   	push   %ebp
801050e8:	89 e5                	mov    %esp,%ebp
801050ea:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801050ed:	e8 fe fd ff ff       	call   80104ef0 <readeflags>
801050f2:	25 00 02 00 00       	and    $0x200,%eax
801050f7:	85 c0                	test   %eax,%eax
801050f9:	74 0c                	je     80105107 <popcli+0x20>
    panic("popcli - interruptible");
801050fb:	c7 04 24 ed 89 10 80 	movl   $0x801089ed,(%esp)
80105102:	e8 36 b4 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105107:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010510d:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105113:	83 ea 01             	sub    $0x1,%edx
80105116:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010511c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105122:	85 c0                	test   %eax,%eax
80105124:	79 0c                	jns    80105132 <popcli+0x4b>
    panic("popcli");
80105126:	c7 04 24 04 8a 10 80 	movl   $0x80108a04,(%esp)
8010512d:	e8 0b b4 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105132:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105138:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010513e:	85 c0                	test   %eax,%eax
80105140:	75 15                	jne    80105157 <popcli+0x70>
80105142:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105148:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010514e:	85 c0                	test   %eax,%eax
80105150:	74 05                	je     80105157 <popcli+0x70>
    sti();
80105152:	e8 b4 fd ff ff       	call   80104f0b <sti>
}
80105157:	c9                   	leave  
80105158:	c3                   	ret    
80105159:	00 00                	add    %al,(%eax)
	...

8010515c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010515c:	55                   	push   %ebp
8010515d:	89 e5                	mov    %esp,%ebp
8010515f:	57                   	push   %edi
80105160:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105161:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105164:	8b 55 10             	mov    0x10(%ebp),%edx
80105167:	8b 45 0c             	mov    0xc(%ebp),%eax
8010516a:	89 cb                	mov    %ecx,%ebx
8010516c:	89 df                	mov    %ebx,%edi
8010516e:	89 d1                	mov    %edx,%ecx
80105170:	fc                   	cld    
80105171:	f3 aa                	rep stos %al,%es:(%edi)
80105173:	89 ca                	mov    %ecx,%edx
80105175:	89 fb                	mov    %edi,%ebx
80105177:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010517a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010517d:	5b                   	pop    %ebx
8010517e:	5f                   	pop    %edi
8010517f:	5d                   	pop    %ebp
80105180:	c3                   	ret    

80105181 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105181:	55                   	push   %ebp
80105182:	89 e5                	mov    %esp,%ebp
80105184:	57                   	push   %edi
80105185:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105186:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105189:	8b 55 10             	mov    0x10(%ebp),%edx
8010518c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010518f:	89 cb                	mov    %ecx,%ebx
80105191:	89 df                	mov    %ebx,%edi
80105193:	89 d1                	mov    %edx,%ecx
80105195:	fc                   	cld    
80105196:	f3 ab                	rep stos %eax,%es:(%edi)
80105198:	89 ca                	mov    %ecx,%edx
8010519a:	89 fb                	mov    %edi,%ebx
8010519c:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010519f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801051a2:	5b                   	pop    %ebx
801051a3:	5f                   	pop    %edi
801051a4:	5d                   	pop    %ebp
801051a5:	c3                   	ret    

801051a6 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801051a6:	55                   	push   %ebp
801051a7:	89 e5                	mov    %esp,%ebp
801051a9:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801051ac:	8b 45 08             	mov    0x8(%ebp),%eax
801051af:	83 e0 03             	and    $0x3,%eax
801051b2:	85 c0                	test   %eax,%eax
801051b4:	75 49                	jne    801051ff <memset+0x59>
801051b6:	8b 45 10             	mov    0x10(%ebp),%eax
801051b9:	83 e0 03             	and    $0x3,%eax
801051bc:	85 c0                	test   %eax,%eax
801051be:	75 3f                	jne    801051ff <memset+0x59>
    c &= 0xFF;
801051c0:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801051c7:	8b 45 10             	mov    0x10(%ebp),%eax
801051ca:	c1 e8 02             	shr    $0x2,%eax
801051cd:	89 c2                	mov    %eax,%edx
801051cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801051d2:	89 c1                	mov    %eax,%ecx
801051d4:	c1 e1 18             	shl    $0x18,%ecx
801051d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801051da:	c1 e0 10             	shl    $0x10,%eax
801051dd:	09 c1                	or     %eax,%ecx
801051df:	8b 45 0c             	mov    0xc(%ebp),%eax
801051e2:	c1 e0 08             	shl    $0x8,%eax
801051e5:	09 c8                	or     %ecx,%eax
801051e7:	0b 45 0c             	or     0xc(%ebp),%eax
801051ea:	89 54 24 08          	mov    %edx,0x8(%esp)
801051ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801051f2:	8b 45 08             	mov    0x8(%ebp),%eax
801051f5:	89 04 24             	mov    %eax,(%esp)
801051f8:	e8 84 ff ff ff       	call   80105181 <stosl>
801051fd:	eb 19                	jmp    80105218 <memset+0x72>
  } else
    stosb(dst, c, n);
801051ff:	8b 45 10             	mov    0x10(%ebp),%eax
80105202:	89 44 24 08          	mov    %eax,0x8(%esp)
80105206:	8b 45 0c             	mov    0xc(%ebp),%eax
80105209:	89 44 24 04          	mov    %eax,0x4(%esp)
8010520d:	8b 45 08             	mov    0x8(%ebp),%eax
80105210:	89 04 24             	mov    %eax,(%esp)
80105213:	e8 44 ff ff ff       	call   8010515c <stosb>
  return dst;
80105218:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010521b:	c9                   	leave  
8010521c:	c3                   	ret    

8010521d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010521d:	55                   	push   %ebp
8010521e:	89 e5                	mov    %esp,%ebp
80105220:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105223:	8b 45 08             	mov    0x8(%ebp),%eax
80105226:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105229:	8b 45 0c             	mov    0xc(%ebp),%eax
8010522c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010522f:	eb 32                	jmp    80105263 <memcmp+0x46>
    if(*s1 != *s2)
80105231:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105234:	0f b6 10             	movzbl (%eax),%edx
80105237:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010523a:	0f b6 00             	movzbl (%eax),%eax
8010523d:	38 c2                	cmp    %al,%dl
8010523f:	74 1a                	je     8010525b <memcmp+0x3e>
      return *s1 - *s2;
80105241:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105244:	0f b6 00             	movzbl (%eax),%eax
80105247:	0f b6 d0             	movzbl %al,%edx
8010524a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010524d:	0f b6 00             	movzbl (%eax),%eax
80105250:	0f b6 c0             	movzbl %al,%eax
80105253:	89 d1                	mov    %edx,%ecx
80105255:	29 c1                	sub    %eax,%ecx
80105257:	89 c8                	mov    %ecx,%eax
80105259:	eb 1c                	jmp    80105277 <memcmp+0x5a>
    s1++, s2++;
8010525b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010525f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105263:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105267:	0f 95 c0             	setne  %al
8010526a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010526e:	84 c0                	test   %al,%al
80105270:	75 bf                	jne    80105231 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105272:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105277:	c9                   	leave  
80105278:	c3                   	ret    

80105279 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105279:	55                   	push   %ebp
8010527a:	89 e5                	mov    %esp,%ebp
8010527c:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010527f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105282:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105285:	8b 45 08             	mov    0x8(%ebp),%eax
80105288:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010528b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010528e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105291:	73 54                	jae    801052e7 <memmove+0x6e>
80105293:	8b 45 10             	mov    0x10(%ebp),%eax
80105296:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105299:	01 d0                	add    %edx,%eax
8010529b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010529e:	76 47                	jbe    801052e7 <memmove+0x6e>
    s += n;
801052a0:	8b 45 10             	mov    0x10(%ebp),%eax
801052a3:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801052a6:	8b 45 10             	mov    0x10(%ebp),%eax
801052a9:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801052ac:	eb 13                	jmp    801052c1 <memmove+0x48>
      *--d = *--s;
801052ae:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801052b2:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801052b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052b9:	0f b6 10             	movzbl (%eax),%edx
801052bc:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052bf:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801052c1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801052c5:	0f 95 c0             	setne  %al
801052c8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801052cc:	84 c0                	test   %al,%al
801052ce:	75 de                	jne    801052ae <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801052d0:	eb 25                	jmp    801052f7 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801052d2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052d5:	0f b6 10             	movzbl (%eax),%edx
801052d8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052db:	88 10                	mov    %dl,(%eax)
801052dd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801052e1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801052e5:	eb 01                	jmp    801052e8 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801052e7:	90                   	nop
801052e8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801052ec:	0f 95 c0             	setne  %al
801052ef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801052f3:	84 c0                	test   %al,%al
801052f5:	75 db                	jne    801052d2 <memmove+0x59>
      *d++ = *s++;

  return dst;
801052f7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801052fa:	c9                   	leave  
801052fb:	c3                   	ret    

801052fc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801052fc:	55                   	push   %ebp
801052fd:	89 e5                	mov    %esp,%ebp
801052ff:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105302:	8b 45 10             	mov    0x10(%ebp),%eax
80105305:	89 44 24 08          	mov    %eax,0x8(%esp)
80105309:	8b 45 0c             	mov    0xc(%ebp),%eax
8010530c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105310:	8b 45 08             	mov    0x8(%ebp),%eax
80105313:	89 04 24             	mov    %eax,(%esp)
80105316:	e8 5e ff ff ff       	call   80105279 <memmove>
}
8010531b:	c9                   	leave  
8010531c:	c3                   	ret    

8010531d <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010531d:	55                   	push   %ebp
8010531e:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105320:	eb 0c                	jmp    8010532e <strncmp+0x11>
    n--, p++, q++;
80105322:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105326:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010532a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010532e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105332:	74 1a                	je     8010534e <strncmp+0x31>
80105334:	8b 45 08             	mov    0x8(%ebp),%eax
80105337:	0f b6 00             	movzbl (%eax),%eax
8010533a:	84 c0                	test   %al,%al
8010533c:	74 10                	je     8010534e <strncmp+0x31>
8010533e:	8b 45 08             	mov    0x8(%ebp),%eax
80105341:	0f b6 10             	movzbl (%eax),%edx
80105344:	8b 45 0c             	mov    0xc(%ebp),%eax
80105347:	0f b6 00             	movzbl (%eax),%eax
8010534a:	38 c2                	cmp    %al,%dl
8010534c:	74 d4                	je     80105322 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010534e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105352:	75 07                	jne    8010535b <strncmp+0x3e>
    return 0;
80105354:	b8 00 00 00 00       	mov    $0x0,%eax
80105359:	eb 18                	jmp    80105373 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010535b:	8b 45 08             	mov    0x8(%ebp),%eax
8010535e:	0f b6 00             	movzbl (%eax),%eax
80105361:	0f b6 d0             	movzbl %al,%edx
80105364:	8b 45 0c             	mov    0xc(%ebp),%eax
80105367:	0f b6 00             	movzbl (%eax),%eax
8010536a:	0f b6 c0             	movzbl %al,%eax
8010536d:	89 d1                	mov    %edx,%ecx
8010536f:	29 c1                	sub    %eax,%ecx
80105371:	89 c8                	mov    %ecx,%eax
}
80105373:	5d                   	pop    %ebp
80105374:	c3                   	ret    

80105375 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105375:	55                   	push   %ebp
80105376:	89 e5                	mov    %esp,%ebp
80105378:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010537b:	8b 45 08             	mov    0x8(%ebp),%eax
8010537e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105381:	90                   	nop
80105382:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105386:	0f 9f c0             	setg   %al
80105389:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010538d:	84 c0                	test   %al,%al
8010538f:	74 30                	je     801053c1 <strncpy+0x4c>
80105391:	8b 45 0c             	mov    0xc(%ebp),%eax
80105394:	0f b6 10             	movzbl (%eax),%edx
80105397:	8b 45 08             	mov    0x8(%ebp),%eax
8010539a:	88 10                	mov    %dl,(%eax)
8010539c:	8b 45 08             	mov    0x8(%ebp),%eax
8010539f:	0f b6 00             	movzbl (%eax),%eax
801053a2:	84 c0                	test   %al,%al
801053a4:	0f 95 c0             	setne  %al
801053a7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801053ab:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801053af:	84 c0                	test   %al,%al
801053b1:	75 cf                	jne    80105382 <strncpy+0xd>
    ;
  while(n-- > 0)
801053b3:	eb 0c                	jmp    801053c1 <strncpy+0x4c>
    *s++ = 0;
801053b5:	8b 45 08             	mov    0x8(%ebp),%eax
801053b8:	c6 00 00             	movb   $0x0,(%eax)
801053bb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801053bf:	eb 01                	jmp    801053c2 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801053c1:	90                   	nop
801053c2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053c6:	0f 9f c0             	setg   %al
801053c9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053cd:	84 c0                	test   %al,%al
801053cf:	75 e4                	jne    801053b5 <strncpy+0x40>
    *s++ = 0;
  return os;
801053d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801053d4:	c9                   	leave  
801053d5:	c3                   	ret    

801053d6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801053d6:	55                   	push   %ebp
801053d7:	89 e5                	mov    %esp,%ebp
801053d9:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801053dc:	8b 45 08             	mov    0x8(%ebp),%eax
801053df:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801053e2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053e6:	7f 05                	jg     801053ed <safestrcpy+0x17>
    return os;
801053e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053eb:	eb 35                	jmp    80105422 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801053ed:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053f1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053f5:	7e 22                	jle    80105419 <safestrcpy+0x43>
801053f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801053fa:	0f b6 10             	movzbl (%eax),%edx
801053fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105400:	88 10                	mov    %dl,(%eax)
80105402:	8b 45 08             	mov    0x8(%ebp),%eax
80105405:	0f b6 00             	movzbl (%eax),%eax
80105408:	84 c0                	test   %al,%al
8010540a:	0f 95 c0             	setne  %al
8010540d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105411:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105415:	84 c0                	test   %al,%al
80105417:	75 d4                	jne    801053ed <safestrcpy+0x17>
    ;
  *s = 0;
80105419:	8b 45 08             	mov    0x8(%ebp),%eax
8010541c:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010541f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105422:	c9                   	leave  
80105423:	c3                   	ret    

80105424 <strlen>:

int
strlen(const char *s)
{
80105424:	55                   	push   %ebp
80105425:	89 e5                	mov    %esp,%ebp
80105427:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010542a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105431:	eb 04                	jmp    80105437 <strlen+0x13>
80105433:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105437:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010543a:	03 45 08             	add    0x8(%ebp),%eax
8010543d:	0f b6 00             	movzbl (%eax),%eax
80105440:	84 c0                	test   %al,%al
80105442:	75 ef                	jne    80105433 <strlen+0xf>
    ;
  return n;
80105444:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105447:	c9                   	leave  
80105448:	c3                   	ret    
80105449:	00 00                	add    %al,(%eax)
	...

8010544c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010544c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105450:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105454:	55                   	push   %ebp
  pushl %ebx
80105455:	53                   	push   %ebx
  pushl %esi
80105456:	56                   	push   %esi
  pushl %edi
80105457:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105458:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010545a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010545c:	5f                   	pop    %edi
  popl %esi
8010545d:	5e                   	pop    %esi
  popl %ebx
8010545e:	5b                   	pop    %ebx
  popl %ebp
8010545f:	5d                   	pop    %ebp
  ret
80105460:	c3                   	ret    
80105461:	00 00                	add    %al,(%eax)
	...

80105464 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105464:	55                   	push   %ebp
80105465:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105467:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010546d:	8b 00                	mov    (%eax),%eax
8010546f:	3b 45 08             	cmp    0x8(%ebp),%eax
80105472:	76 12                	jbe    80105486 <fetchint+0x22>
80105474:	8b 45 08             	mov    0x8(%ebp),%eax
80105477:	8d 50 04             	lea    0x4(%eax),%edx
8010547a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105480:	8b 00                	mov    (%eax),%eax
80105482:	39 c2                	cmp    %eax,%edx
80105484:	76 07                	jbe    8010548d <fetchint+0x29>
    return -1;
80105486:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010548b:	eb 0f                	jmp    8010549c <fetchint+0x38>
  *ip = *(int*)(addr);
8010548d:	8b 45 08             	mov    0x8(%ebp),%eax
80105490:	8b 10                	mov    (%eax),%edx
80105492:	8b 45 0c             	mov    0xc(%ebp),%eax
80105495:	89 10                	mov    %edx,(%eax)
  return 0;
80105497:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010549c:	5d                   	pop    %ebp
8010549d:	c3                   	ret    

8010549e <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010549e:	55                   	push   %ebp
8010549f:	89 e5                	mov    %esp,%ebp
801054a1:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
801054a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054aa:	8b 00                	mov    (%eax),%eax
801054ac:	3b 45 08             	cmp    0x8(%ebp),%eax
801054af:	77 07                	ja     801054b8 <fetchstr+0x1a>
    return -1;
801054b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054b6:	eb 48                	jmp    80105500 <fetchstr+0x62>
  *pp = (char*)addr;
801054b8:	8b 55 08             	mov    0x8(%ebp),%edx
801054bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801054be:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
801054c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c6:	8b 00                	mov    (%eax),%eax
801054c8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801054cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ce:	8b 00                	mov    (%eax),%eax
801054d0:	89 45 fc             	mov    %eax,-0x4(%ebp)
801054d3:	eb 1e                	jmp    801054f3 <fetchstr+0x55>
    if(*s == 0)
801054d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054d8:	0f b6 00             	movzbl (%eax),%eax
801054db:	84 c0                	test   %al,%al
801054dd:	75 10                	jne    801054ef <fetchstr+0x51>
      return s - *pp;
801054df:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801054e5:	8b 00                	mov    (%eax),%eax
801054e7:	89 d1                	mov    %edx,%ecx
801054e9:	29 c1                	sub    %eax,%ecx
801054eb:	89 c8                	mov    %ecx,%eax
801054ed:	eb 11                	jmp    80105500 <fetchstr+0x62>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
801054ef:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054f6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801054f9:	72 da                	jb     801054d5 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
801054fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105500:	c9                   	leave  
80105501:	c3                   	ret    

80105502 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105502:	55                   	push   %ebp
80105503:	89 e5                	mov    %esp,%ebp
80105505:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105508:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550e:	8b 40 18             	mov    0x18(%eax),%eax
80105511:	8b 50 44             	mov    0x44(%eax),%edx
80105514:	8b 45 08             	mov    0x8(%ebp),%eax
80105517:	c1 e0 02             	shl    $0x2,%eax
8010551a:	01 d0                	add    %edx,%eax
8010551c:	8d 50 04             	lea    0x4(%eax),%edx
8010551f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105522:	89 44 24 04          	mov    %eax,0x4(%esp)
80105526:	89 14 24             	mov    %edx,(%esp)
80105529:	e8 36 ff ff ff       	call   80105464 <fetchint>
}
8010552e:	c9                   	leave  
8010552f:	c3                   	ret    

80105530 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105530:	55                   	push   %ebp
80105531:	89 e5                	mov    %esp,%ebp
80105533:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105536:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105539:	89 44 24 04          	mov    %eax,0x4(%esp)
8010553d:	8b 45 08             	mov    0x8(%ebp),%eax
80105540:	89 04 24             	mov    %eax,(%esp)
80105543:	e8 ba ff ff ff       	call   80105502 <argint>
80105548:	85 c0                	test   %eax,%eax
8010554a:	79 07                	jns    80105553 <argptr+0x23>
    return -1;
8010554c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105551:	eb 3d                	jmp    80105590 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105553:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105556:	89 c2                	mov    %eax,%edx
80105558:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010555e:	8b 00                	mov    (%eax),%eax
80105560:	39 c2                	cmp    %eax,%edx
80105562:	73 16                	jae    8010557a <argptr+0x4a>
80105564:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105567:	89 c2                	mov    %eax,%edx
80105569:	8b 45 10             	mov    0x10(%ebp),%eax
8010556c:	01 c2                	add    %eax,%edx
8010556e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105574:	8b 00                	mov    (%eax),%eax
80105576:	39 c2                	cmp    %eax,%edx
80105578:	76 07                	jbe    80105581 <argptr+0x51>
    return -1;
8010557a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010557f:	eb 0f                	jmp    80105590 <argptr+0x60>
  *pp = (char*)i;
80105581:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105584:	89 c2                	mov    %eax,%edx
80105586:	8b 45 0c             	mov    0xc(%ebp),%eax
80105589:	89 10                	mov    %edx,(%eax)
  return 0;
8010558b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105590:	c9                   	leave  
80105591:	c3                   	ret    

80105592 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105592:	55                   	push   %ebp
80105593:	89 e5                	mov    %esp,%ebp
80105595:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105598:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010559b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010559f:	8b 45 08             	mov    0x8(%ebp),%eax
801055a2:	89 04 24             	mov    %eax,(%esp)
801055a5:	e8 58 ff ff ff       	call   80105502 <argint>
801055aa:	85 c0                	test   %eax,%eax
801055ac:	79 07                	jns    801055b5 <argstr+0x23>
    return -1;
801055ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055b3:	eb 12                	jmp    801055c7 <argstr+0x35>
  return fetchstr(addr, pp);
801055b5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055b8:	8b 55 0c             	mov    0xc(%ebp),%edx
801055bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801055bf:	89 04 24             	mov    %eax,(%esp)
801055c2:	e8 d7 fe ff ff       	call   8010549e <fetchstr>
}
801055c7:	c9                   	leave  
801055c8:	c3                   	ret    

801055c9 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801055c9:	55                   	push   %ebp
801055ca:	89 e5                	mov    %esp,%ebp
801055cc:	53                   	push   %ebx
801055cd:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801055d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055d6:	8b 40 18             	mov    0x18(%eax),%eax
801055d9:	8b 40 1c             	mov    0x1c(%eax),%eax
801055dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801055df:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801055e3:	7e 30                	jle    80105615 <syscall+0x4c>
801055e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e8:	83 f8 15             	cmp    $0x15,%eax
801055eb:	77 28                	ja     80105615 <syscall+0x4c>
801055ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055f0:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801055f7:	85 c0                	test   %eax,%eax
801055f9:	74 1a                	je     80105615 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801055fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105601:	8b 58 18             	mov    0x18(%eax),%ebx
80105604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105607:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010560e:	ff d0                	call   *%eax
80105610:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105613:	eb 3d                	jmp    80105652 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105615:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010561b:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010561e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105624:	8b 40 10             	mov    0x10(%eax),%eax
80105627:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010562a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010562e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105632:	89 44 24 04          	mov    %eax,0x4(%esp)
80105636:	c7 04 24 0b 8a 10 80 	movl   $0x80108a0b,(%esp)
8010563d:	e8 5f ad ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105642:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105648:	8b 40 18             	mov    0x18(%eax),%eax
8010564b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105652:	83 c4 24             	add    $0x24,%esp
80105655:	5b                   	pop    %ebx
80105656:	5d                   	pop    %ebp
80105657:	c3                   	ret    

80105658 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105658:	55                   	push   %ebp
80105659:	89 e5                	mov    %esp,%ebp
8010565b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010565e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105661:	89 44 24 04          	mov    %eax,0x4(%esp)
80105665:	8b 45 08             	mov    0x8(%ebp),%eax
80105668:	89 04 24             	mov    %eax,(%esp)
8010566b:	e8 92 fe ff ff       	call   80105502 <argint>
80105670:	85 c0                	test   %eax,%eax
80105672:	79 07                	jns    8010567b <argfd+0x23>
    return -1;
80105674:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105679:	eb 50                	jmp    801056cb <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010567b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010567e:	85 c0                	test   %eax,%eax
80105680:	78 21                	js     801056a3 <argfd+0x4b>
80105682:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105685:	83 f8 0f             	cmp    $0xf,%eax
80105688:	7f 19                	jg     801056a3 <argfd+0x4b>
8010568a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105690:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105693:	83 c2 08             	add    $0x8,%edx
80105696:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010569a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010569d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056a1:	75 07                	jne    801056aa <argfd+0x52>
    return -1;
801056a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056a8:	eb 21                	jmp    801056cb <argfd+0x73>
  if(pfd)
801056aa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801056ae:	74 08                	je     801056b8 <argfd+0x60>
    *pfd = fd;
801056b0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801056b6:	89 10                	mov    %edx,(%eax)
  if(pf)
801056b8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056bc:	74 08                	je     801056c6 <argfd+0x6e>
    *pf = f;
801056be:	8b 45 10             	mov    0x10(%ebp),%eax
801056c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056c4:	89 10                	mov    %edx,(%eax)
  return 0;
801056c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056cb:	c9                   	leave  
801056cc:	c3                   	ret    

801056cd <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801056cd:	55                   	push   %ebp
801056ce:	89 e5                	mov    %esp,%ebp
801056d0:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801056d3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801056da:	eb 30                	jmp    8010570c <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801056dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056e2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056e5:	83 c2 08             	add    $0x8,%edx
801056e8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801056ec:	85 c0                	test   %eax,%eax
801056ee:	75 18                	jne    80105708 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801056f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056f9:	8d 4a 08             	lea    0x8(%edx),%ecx
801056fc:	8b 55 08             	mov    0x8(%ebp),%edx
801056ff:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105703:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105706:	eb 0f                	jmp    80105717 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105708:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010570c:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105710:	7e ca                	jle    801056dc <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105712:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105717:	c9                   	leave  
80105718:	c3                   	ret    

80105719 <sys_dup>:

int
sys_dup(void)
{
80105719:	55                   	push   %ebp
8010571a:	89 e5                	mov    %esp,%ebp
8010571c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010571f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105722:	89 44 24 08          	mov    %eax,0x8(%esp)
80105726:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010572d:	00 
8010572e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105735:	e8 1e ff ff ff       	call   80105658 <argfd>
8010573a:	85 c0                	test   %eax,%eax
8010573c:	79 07                	jns    80105745 <sys_dup+0x2c>
    return -1;
8010573e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105743:	eb 29                	jmp    8010576e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105745:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105748:	89 04 24             	mov    %eax,(%esp)
8010574b:	e8 7d ff ff ff       	call   801056cd <fdalloc>
80105750:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105753:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105757:	79 07                	jns    80105760 <sys_dup+0x47>
    return -1;
80105759:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010575e:	eb 0e                	jmp    8010576e <sys_dup+0x55>
  filedup(f);
80105760:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105763:	89 04 24             	mov    %eax,(%esp)
80105766:	e8 39 b8 ff ff       	call   80100fa4 <filedup>
  return fd;
8010576b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010576e:	c9                   	leave  
8010576f:	c3                   	ret    

80105770 <sys_read>:

int
sys_read(void)
{
80105770:	55                   	push   %ebp
80105771:	89 e5                	mov    %esp,%ebp
80105773:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105776:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105779:	89 44 24 08          	mov    %eax,0x8(%esp)
8010577d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105784:	00 
80105785:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010578c:	e8 c7 fe ff ff       	call   80105658 <argfd>
80105791:	85 c0                	test   %eax,%eax
80105793:	78 35                	js     801057ca <sys_read+0x5a>
80105795:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105798:	89 44 24 04          	mov    %eax,0x4(%esp)
8010579c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801057a3:	e8 5a fd ff ff       	call   80105502 <argint>
801057a8:	85 c0                	test   %eax,%eax
801057aa:	78 1e                	js     801057ca <sys_read+0x5a>
801057ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057af:	89 44 24 08          	mov    %eax,0x8(%esp)
801057b3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801057b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801057ba:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801057c1:	e8 6a fd ff ff       	call   80105530 <argptr>
801057c6:	85 c0                	test   %eax,%eax
801057c8:	79 07                	jns    801057d1 <sys_read+0x61>
    return -1;
801057ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057cf:	eb 19                	jmp    801057ea <sys_read+0x7a>
  return fileread(f, p, n);
801057d1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801057d4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801057d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057da:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801057de:	89 54 24 04          	mov    %edx,0x4(%esp)
801057e2:	89 04 24             	mov    %eax,(%esp)
801057e5:	e8 27 b9 ff ff       	call   80101111 <fileread>
}
801057ea:	c9                   	leave  
801057eb:	c3                   	ret    

801057ec <sys_write>:

int
sys_write(void)
{
801057ec:	55                   	push   %ebp
801057ed:	89 e5                	mov    %esp,%ebp
801057ef:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801057f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057f5:	89 44 24 08          	mov    %eax,0x8(%esp)
801057f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105800:	00 
80105801:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105808:	e8 4b fe ff ff       	call   80105658 <argfd>
8010580d:	85 c0                	test   %eax,%eax
8010580f:	78 35                	js     80105846 <sys_write+0x5a>
80105811:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105814:	89 44 24 04          	mov    %eax,0x4(%esp)
80105818:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010581f:	e8 de fc ff ff       	call   80105502 <argint>
80105824:	85 c0                	test   %eax,%eax
80105826:	78 1e                	js     80105846 <sys_write+0x5a>
80105828:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010582b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010582f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105832:	89 44 24 04          	mov    %eax,0x4(%esp)
80105836:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010583d:	e8 ee fc ff ff       	call   80105530 <argptr>
80105842:	85 c0                	test   %eax,%eax
80105844:	79 07                	jns    8010584d <sys_write+0x61>
    return -1;
80105846:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010584b:	eb 19                	jmp    80105866 <sys_write+0x7a>
  return filewrite(f, p, n);
8010584d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105850:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105856:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010585a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010585e:	89 04 24             	mov    %eax,(%esp)
80105861:	e8 67 b9 ff ff       	call   801011cd <filewrite>
}
80105866:	c9                   	leave  
80105867:	c3                   	ret    

80105868 <sys_close>:

int
sys_close(void)
{
80105868:	55                   	push   %ebp
80105869:	89 e5                	mov    %esp,%ebp
8010586b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010586e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105871:	89 44 24 08          	mov    %eax,0x8(%esp)
80105875:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105878:	89 44 24 04          	mov    %eax,0x4(%esp)
8010587c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105883:	e8 d0 fd ff ff       	call   80105658 <argfd>
80105888:	85 c0                	test   %eax,%eax
8010588a:	79 07                	jns    80105893 <sys_close+0x2b>
    return -1;
8010588c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105891:	eb 24                	jmp    801058b7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105893:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105899:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010589c:	83 c2 08             	add    $0x8,%edx
8010589f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801058a6:	00 
  fileclose(f);
801058a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058aa:	89 04 24             	mov    %eax,(%esp)
801058ad:	e8 3a b7 ff ff       	call   80100fec <fileclose>
  return 0;
801058b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058b7:	c9                   	leave  
801058b8:	c3                   	ret    

801058b9 <sys_fstat>:

int
sys_fstat(void)
{
801058b9:	55                   	push   %ebp
801058ba:	89 e5                	mov    %esp,%ebp
801058bc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801058bf:	8d 45 f4             	lea    -0xc(%ebp),%eax
801058c2:	89 44 24 08          	mov    %eax,0x8(%esp)
801058c6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801058cd:	00 
801058ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058d5:	e8 7e fd ff ff       	call   80105658 <argfd>
801058da:	85 c0                	test   %eax,%eax
801058dc:	78 1f                	js     801058fd <sys_fstat+0x44>
801058de:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801058e5:	00 
801058e6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801058ed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058f4:	e8 37 fc ff ff       	call   80105530 <argptr>
801058f9:	85 c0                	test   %eax,%eax
801058fb:	79 07                	jns    80105904 <sys_fstat+0x4b>
    return -1;
801058fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105902:	eb 12                	jmp    80105916 <sys_fstat+0x5d>
  return filestat(f, st);
80105904:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010590a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010590e:	89 04 24             	mov    %eax,(%esp)
80105911:	e8 ac b7 ff ff       	call   801010c2 <filestat>
}
80105916:	c9                   	leave  
80105917:	c3                   	ret    

80105918 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105918:	55                   	push   %ebp
80105919:	89 e5                	mov    %esp,%ebp
8010591b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010591e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105921:	89 44 24 04          	mov    %eax,0x4(%esp)
80105925:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010592c:	e8 61 fc ff ff       	call   80105592 <argstr>
80105931:	85 c0                	test   %eax,%eax
80105933:	78 17                	js     8010594c <sys_link+0x34>
80105935:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105938:	89 44 24 04          	mov    %eax,0x4(%esp)
8010593c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105943:	e8 4a fc ff ff       	call   80105592 <argstr>
80105948:	85 c0                	test   %eax,%eax
8010594a:	79 0a                	jns    80105956 <sys_link+0x3e>
    return -1;
8010594c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105951:	e9 41 01 00 00       	jmp    80105a97 <sys_link+0x17f>

  begin_op();
80105956:	e8 b2 db ff ff       	call   8010350d <begin_op>
  if((ip = namei(old)) == 0){
8010595b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010595e:	89 04 24             	mov    %eax,(%esp)
80105961:	e8 33 cb ff ff       	call   80102499 <namei>
80105966:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105969:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010596d:	75 0f                	jne    8010597e <sys_link+0x66>
    end_op();
8010596f:	e8 1a dc ff ff       	call   8010358e <end_op>
    return -1;
80105974:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105979:	e9 19 01 00 00       	jmp    80105a97 <sys_link+0x17f>
  }

  ilock(ip);
8010597e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105981:	89 04 24             	mov    %eax,(%esp)
80105984:	e8 68 bf ff ff       	call   801018f1 <ilock>
  if(ip->type == T_DIR){
80105989:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010598c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105990:	66 83 f8 01          	cmp    $0x1,%ax
80105994:	75 1a                	jne    801059b0 <sys_link+0x98>
    iunlockput(ip);
80105996:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105999:	89 04 24             	mov    %eax,(%esp)
8010599c:	e8 da c1 ff ff       	call   80101b7b <iunlockput>
    end_op();
801059a1:	e8 e8 db ff ff       	call   8010358e <end_op>
    return -1;
801059a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059ab:	e9 e7 00 00 00       	jmp    80105a97 <sys_link+0x17f>
  }

  ip->nlink++;
801059b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059b7:	8d 50 01             	lea    0x1(%eax),%edx
801059ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059bd:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801059c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059c4:	89 04 24             	mov    %eax,(%esp)
801059c7:	e8 63 bd ff ff       	call   8010172f <iupdate>
  iunlock(ip);
801059cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059cf:	89 04 24             	mov    %eax,(%esp)
801059d2:	e8 6e c0 ff ff       	call   80101a45 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801059d7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801059da:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801059dd:	89 54 24 04          	mov    %edx,0x4(%esp)
801059e1:	89 04 24             	mov    %eax,(%esp)
801059e4:	e8 d2 ca ff ff       	call   801024bb <nameiparent>
801059e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801059ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801059f0:	74 68                	je     80105a5a <sys_link+0x142>
    goto bad;
  ilock(dp);
801059f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059f5:	89 04 24             	mov    %eax,(%esp)
801059f8:	e8 f4 be ff ff       	call   801018f1 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801059fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a00:	8b 10                	mov    (%eax),%edx
80105a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a05:	8b 00                	mov    (%eax),%eax
80105a07:	39 c2                	cmp    %eax,%edx
80105a09:	75 20                	jne    80105a2b <sys_link+0x113>
80105a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a0e:	8b 40 04             	mov    0x4(%eax),%eax
80105a11:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a15:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105a18:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a1f:	89 04 24             	mov    %eax,(%esp)
80105a22:	e8 b1 c7 ff ff       	call   801021d8 <dirlink>
80105a27:	85 c0                	test   %eax,%eax
80105a29:	79 0d                	jns    80105a38 <sys_link+0x120>
    iunlockput(dp);
80105a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a2e:	89 04 24             	mov    %eax,(%esp)
80105a31:	e8 45 c1 ff ff       	call   80101b7b <iunlockput>
    goto bad;
80105a36:	eb 23                	jmp    80105a5b <sys_link+0x143>
  }
  iunlockput(dp);
80105a38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a3b:	89 04 24             	mov    %eax,(%esp)
80105a3e:	e8 38 c1 ff ff       	call   80101b7b <iunlockput>
  iput(ip);
80105a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a46:	89 04 24             	mov    %eax,(%esp)
80105a49:	e8 5c c0 ff ff       	call   80101aaa <iput>

  end_op();
80105a4e:	e8 3b db ff ff       	call   8010358e <end_op>

  return 0;
80105a53:	b8 00 00 00 00       	mov    $0x0,%eax
80105a58:	eb 3d                	jmp    80105a97 <sys_link+0x17f>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105a5a:	90                   	nop
  end_op();

  return 0;

bad:
  ilock(ip);
80105a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5e:	89 04 24             	mov    %eax,(%esp)
80105a61:	e8 8b be ff ff       	call   801018f1 <ilock>
  ip->nlink--;
80105a66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a69:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a6d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a73:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a7a:	89 04 24             	mov    %eax,(%esp)
80105a7d:	e8 ad bc ff ff       	call   8010172f <iupdate>
  iunlockput(ip);
80105a82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a85:	89 04 24             	mov    %eax,(%esp)
80105a88:	e8 ee c0 ff ff       	call   80101b7b <iunlockput>
  end_op();
80105a8d:	e8 fc da ff ff       	call   8010358e <end_op>
  return -1;
80105a92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a97:	c9                   	leave  
80105a98:	c3                   	ret    

80105a99 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105a99:	55                   	push   %ebp
80105a9a:	89 e5                	mov    %esp,%ebp
80105a9c:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105a9f:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105aa6:	eb 4b                	jmp    80105af3 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aab:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105ab2:	00 
80105ab3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ab7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105aba:	89 44 24 04          	mov    %eax,0x4(%esp)
80105abe:	8b 45 08             	mov    0x8(%ebp),%eax
80105ac1:	89 04 24             	mov    %eax,(%esp)
80105ac4:	e8 24 c3 ff ff       	call   80101ded <readi>
80105ac9:	83 f8 10             	cmp    $0x10,%eax
80105acc:	74 0c                	je     80105ada <isdirempty+0x41>
      panic("isdirempty: readi");
80105ace:	c7 04 24 27 8a 10 80 	movl   $0x80108a27,(%esp)
80105ad5:	e8 63 aa ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105ada:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ade:	66 85 c0             	test   %ax,%ax
80105ae1:	74 07                	je     80105aea <isdirempty+0x51>
      return 0;
80105ae3:	b8 00 00 00 00       	mov    $0x0,%eax
80105ae8:	eb 1b                	jmp    80105b05 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aed:	83 c0 10             	add    $0x10,%eax
80105af0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105af3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105af6:	8b 45 08             	mov    0x8(%ebp),%eax
80105af9:	8b 40 18             	mov    0x18(%eax),%eax
80105afc:	39 c2                	cmp    %eax,%edx
80105afe:	72 a8                	jb     80105aa8 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105b00:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b05:	c9                   	leave  
80105b06:	c3                   	ret    

80105b07 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105b07:	55                   	push   %ebp
80105b08:	89 e5                	mov    %esp,%ebp
80105b0a:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105b0d:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105b10:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b14:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b1b:	e8 72 fa ff ff       	call   80105592 <argstr>
80105b20:	85 c0                	test   %eax,%eax
80105b22:	79 0a                	jns    80105b2e <sys_unlink+0x27>
    return -1;
80105b24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b29:	e9 af 01 00 00       	jmp    80105cdd <sys_unlink+0x1d6>

  begin_op();
80105b2e:	e8 da d9 ff ff       	call   8010350d <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105b33:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105b36:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105b39:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b3d:	89 04 24             	mov    %eax,(%esp)
80105b40:	e8 76 c9 ff ff       	call   801024bb <nameiparent>
80105b45:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b48:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b4c:	75 0f                	jne    80105b5d <sys_unlink+0x56>
    end_op();
80105b4e:	e8 3b da ff ff       	call   8010358e <end_op>
    return -1;
80105b53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b58:	e9 80 01 00 00       	jmp    80105cdd <sys_unlink+0x1d6>
  }

  ilock(dp);
80105b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b60:	89 04 24             	mov    %eax,(%esp)
80105b63:	e8 89 bd ff ff       	call   801018f1 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105b68:	c7 44 24 04 39 8a 10 	movl   $0x80108a39,0x4(%esp)
80105b6f:	80 
80105b70:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b73:	89 04 24             	mov    %eax,(%esp)
80105b76:	e8 73 c5 ff ff       	call   801020ee <namecmp>
80105b7b:	85 c0                	test   %eax,%eax
80105b7d:	0f 84 45 01 00 00    	je     80105cc8 <sys_unlink+0x1c1>
80105b83:	c7 44 24 04 3b 8a 10 	movl   $0x80108a3b,0x4(%esp)
80105b8a:	80 
80105b8b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b8e:	89 04 24             	mov    %eax,(%esp)
80105b91:	e8 58 c5 ff ff       	call   801020ee <namecmp>
80105b96:	85 c0                	test   %eax,%eax
80105b98:	0f 84 2a 01 00 00    	je     80105cc8 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105b9e:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105ba1:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ba5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ba8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105baf:	89 04 24             	mov    %eax,(%esp)
80105bb2:	e8 59 c5 ff ff       	call   80102110 <dirlookup>
80105bb7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bbe:	0f 84 03 01 00 00    	je     80105cc7 <sys_unlink+0x1c0>
    goto bad;
  ilock(ip);
80105bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc7:	89 04 24             	mov    %eax,(%esp)
80105bca:	e8 22 bd ff ff       	call   801018f1 <ilock>

  if(ip->nlink < 1)
80105bcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105bd6:	66 85 c0             	test   %ax,%ax
80105bd9:	7f 0c                	jg     80105be7 <sys_unlink+0xe0>
    panic("unlink: nlink < 1");
80105bdb:	c7 04 24 3e 8a 10 80 	movl   $0x80108a3e,(%esp)
80105be2:	e8 56 a9 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105be7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bea:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105bee:	66 83 f8 01          	cmp    $0x1,%ax
80105bf2:	75 1f                	jne    80105c13 <sys_unlink+0x10c>
80105bf4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bf7:	89 04 24             	mov    %eax,(%esp)
80105bfa:	e8 9a fe ff ff       	call   80105a99 <isdirempty>
80105bff:	85 c0                	test   %eax,%eax
80105c01:	75 10                	jne    80105c13 <sys_unlink+0x10c>
    iunlockput(ip);
80105c03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c06:	89 04 24             	mov    %eax,(%esp)
80105c09:	e8 6d bf ff ff       	call   80101b7b <iunlockput>
    goto bad;
80105c0e:	e9 b5 00 00 00       	jmp    80105cc8 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105c13:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105c1a:	00 
80105c1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c22:	00 
80105c23:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c26:	89 04 24             	mov    %eax,(%esp)
80105c29:	e8 78 f5 ff ff       	call   801051a6 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c2e:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105c31:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105c38:	00 
80105c39:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c3d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c40:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c47:	89 04 24             	mov    %eax,(%esp)
80105c4a:	e8 09 c3 ff ff       	call   80101f58 <writei>
80105c4f:	83 f8 10             	cmp    $0x10,%eax
80105c52:	74 0c                	je     80105c60 <sys_unlink+0x159>
    panic("unlink: writei");
80105c54:	c7 04 24 50 8a 10 80 	movl   $0x80108a50,(%esp)
80105c5b:	e8 dd a8 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105c60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c63:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c67:	66 83 f8 01          	cmp    $0x1,%ax
80105c6b:	75 1c                	jne    80105c89 <sys_unlink+0x182>
    dp->nlink--;
80105c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c70:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c74:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7a:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105c7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c81:	89 04 24             	mov    %eax,(%esp)
80105c84:	e8 a6 ba ff ff       	call   8010172f <iupdate>
  }
  iunlockput(dp);
80105c89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c8c:	89 04 24             	mov    %eax,(%esp)
80105c8f:	e8 e7 be ff ff       	call   80101b7b <iunlockput>

  ip->nlink--;
80105c94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c97:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c9b:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca1:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105ca5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca8:	89 04 24             	mov    %eax,(%esp)
80105cab:	e8 7f ba ff ff       	call   8010172f <iupdate>
  iunlockput(ip);
80105cb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cb3:	89 04 24             	mov    %eax,(%esp)
80105cb6:	e8 c0 be ff ff       	call   80101b7b <iunlockput>

  end_op();
80105cbb:	e8 ce d8 ff ff       	call   8010358e <end_op>

  return 0;
80105cc0:	b8 00 00 00 00       	mov    $0x0,%eax
80105cc5:	eb 16                	jmp    80105cdd <sys_unlink+0x1d6>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105cc7:	90                   	nop
  end_op();

  return 0;

bad:
  iunlockput(dp);
80105cc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ccb:	89 04 24             	mov    %eax,(%esp)
80105cce:	e8 a8 be ff ff       	call   80101b7b <iunlockput>
  end_op();
80105cd3:	e8 b6 d8 ff ff       	call   8010358e <end_op>
  return -1;
80105cd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105cdd:	c9                   	leave  
80105cde:	c3                   	ret    

80105cdf <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105cdf:	55                   	push   %ebp
80105ce0:	89 e5                	mov    %esp,%ebp
80105ce2:	83 ec 48             	sub    $0x48,%esp
80105ce5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105ce8:	8b 55 10             	mov    0x10(%ebp),%edx
80105ceb:	8b 45 14             	mov    0x14(%ebp),%eax
80105cee:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105cf2:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105cf6:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105cfa:	8d 45 de             	lea    -0x22(%ebp),%eax
80105cfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d01:	8b 45 08             	mov    0x8(%ebp),%eax
80105d04:	89 04 24             	mov    %eax,(%esp)
80105d07:	e8 af c7 ff ff       	call   801024bb <nameiparent>
80105d0c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d0f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d13:	75 0a                	jne    80105d1f <create+0x40>
    return 0;
80105d15:	b8 00 00 00 00       	mov    $0x0,%eax
80105d1a:	e9 7e 01 00 00       	jmp    80105e9d <create+0x1be>
  ilock(dp);
80105d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d22:	89 04 24             	mov    %eax,(%esp)
80105d25:	e8 c7 bb ff ff       	call   801018f1 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105d2a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d2d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d31:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d34:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d3b:	89 04 24             	mov    %eax,(%esp)
80105d3e:	e8 cd c3 ff ff       	call   80102110 <dirlookup>
80105d43:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d4a:	74 47                	je     80105d93 <create+0xb4>
    iunlockput(dp);
80105d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d4f:	89 04 24             	mov    %eax,(%esp)
80105d52:	e8 24 be ff ff       	call   80101b7b <iunlockput>
    ilock(ip);
80105d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d5a:	89 04 24             	mov    %eax,(%esp)
80105d5d:	e8 8f bb ff ff       	call   801018f1 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105d62:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105d67:	75 15                	jne    80105d7e <create+0x9f>
80105d69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d6c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d70:	66 83 f8 02          	cmp    $0x2,%ax
80105d74:	75 08                	jne    80105d7e <create+0x9f>
      return ip;
80105d76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d79:	e9 1f 01 00 00       	jmp    80105e9d <create+0x1be>
    iunlockput(ip);
80105d7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d81:	89 04 24             	mov    %eax,(%esp)
80105d84:	e8 f2 bd ff ff       	call   80101b7b <iunlockput>
    return 0;
80105d89:	b8 00 00 00 00       	mov    $0x0,%eax
80105d8e:	e9 0a 01 00 00       	jmp    80105e9d <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105d93:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105d97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d9a:	8b 00                	mov    (%eax),%eax
80105d9c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105da0:	89 04 24             	mov    %eax,(%esp)
80105da3:	e8 b4 b8 ff ff       	call   8010165c <ialloc>
80105da8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105dab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105daf:	75 0c                	jne    80105dbd <create+0xde>
    panic("create: ialloc");
80105db1:	c7 04 24 5f 8a 10 80 	movl   $0x80108a5f,(%esp)
80105db8:	e8 80 a7 ff ff       	call   8010053d <panic>

  ilock(ip);
80105dbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc0:	89 04 24             	mov    %eax,(%esp)
80105dc3:	e8 29 bb ff ff       	call   801018f1 <ilock>
  ip->major = major;
80105dc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dcb:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105dcf:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105dd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd6:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105dda:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105dde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de1:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105de7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dea:	89 04 24             	mov    %eax,(%esp)
80105ded:	e8 3d b9 ff ff       	call   8010172f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105df2:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105df7:	75 6a                	jne    80105e63 <create+0x184>
    dp->nlink++;  // for ".."
80105df9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dfc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e00:	8d 50 01             	lea    0x1(%eax),%edx
80105e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e06:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0d:	89 04 24             	mov    %eax,(%esp)
80105e10:	e8 1a b9 ff ff       	call   8010172f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105e15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e18:	8b 40 04             	mov    0x4(%eax),%eax
80105e1b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e1f:	c7 44 24 04 39 8a 10 	movl   $0x80108a39,0x4(%esp)
80105e26:	80 
80105e27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e2a:	89 04 24             	mov    %eax,(%esp)
80105e2d:	e8 a6 c3 ff ff       	call   801021d8 <dirlink>
80105e32:	85 c0                	test   %eax,%eax
80105e34:	78 21                	js     80105e57 <create+0x178>
80105e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e39:	8b 40 04             	mov    0x4(%eax),%eax
80105e3c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e40:	c7 44 24 04 3b 8a 10 	movl   $0x80108a3b,0x4(%esp)
80105e47:	80 
80105e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e4b:	89 04 24             	mov    %eax,(%esp)
80105e4e:	e8 85 c3 ff ff       	call   801021d8 <dirlink>
80105e53:	85 c0                	test   %eax,%eax
80105e55:	79 0c                	jns    80105e63 <create+0x184>
      panic("create dots");
80105e57:	c7 04 24 6e 8a 10 80 	movl   $0x80108a6e,(%esp)
80105e5e:	e8 da a6 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105e63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e66:	8b 40 04             	mov    0x4(%eax),%eax
80105e69:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e6d:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e70:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e77:	89 04 24             	mov    %eax,(%esp)
80105e7a:	e8 59 c3 ff ff       	call   801021d8 <dirlink>
80105e7f:	85 c0                	test   %eax,%eax
80105e81:	79 0c                	jns    80105e8f <create+0x1b0>
    panic("create: dirlink");
80105e83:	c7 04 24 7a 8a 10 80 	movl   $0x80108a7a,(%esp)
80105e8a:	e8 ae a6 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105e8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e92:	89 04 24             	mov    %eax,(%esp)
80105e95:	e8 e1 bc ff ff       	call   80101b7b <iunlockput>

  return ip;
80105e9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105e9d:	c9                   	leave  
80105e9e:	c3                   	ret    

80105e9f <sys_open>:

int
sys_open(void)
{
80105e9f:	55                   	push   %ebp
80105ea0:	89 e5                	mov    %esp,%ebp
80105ea2:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105ea5:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ea8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105eb3:	e8 da f6 ff ff       	call   80105592 <argstr>
80105eb8:	85 c0                	test   %eax,%eax
80105eba:	78 17                	js     80105ed3 <sys_open+0x34>
80105ebc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ebf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ec3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105eca:	e8 33 f6 ff ff       	call   80105502 <argint>
80105ecf:	85 c0                	test   %eax,%eax
80105ed1:	79 0a                	jns    80105edd <sys_open+0x3e>
    return -1;
80105ed3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed8:	e9 5a 01 00 00       	jmp    80106037 <sys_open+0x198>

  begin_op();
80105edd:	e8 2b d6 ff ff       	call   8010350d <begin_op>

  if(omode & O_CREATE){
80105ee2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ee5:	25 00 02 00 00       	and    $0x200,%eax
80105eea:	85 c0                	test   %eax,%eax
80105eec:	74 3b                	je     80105f29 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105eee:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ef1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105ef8:	00 
80105ef9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105f00:	00 
80105f01:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105f08:	00 
80105f09:	89 04 24             	mov    %eax,(%esp)
80105f0c:	e8 ce fd ff ff       	call   80105cdf <create>
80105f11:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105f14:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f18:	75 6b                	jne    80105f85 <sys_open+0xe6>
      end_op();
80105f1a:	e8 6f d6 ff ff       	call   8010358e <end_op>
      return -1;
80105f1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f24:	e9 0e 01 00 00       	jmp    80106037 <sys_open+0x198>
    }
  } else {
    if((ip = namei(path)) == 0){
80105f29:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f2c:	89 04 24             	mov    %eax,(%esp)
80105f2f:	e8 65 c5 ff ff       	call   80102499 <namei>
80105f34:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f37:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f3b:	75 0f                	jne    80105f4c <sys_open+0xad>
      end_op();
80105f3d:	e8 4c d6 ff ff       	call   8010358e <end_op>
      return -1;
80105f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f47:	e9 eb 00 00 00       	jmp    80106037 <sys_open+0x198>
    }
    ilock(ip);
80105f4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f4f:	89 04 24             	mov    %eax,(%esp)
80105f52:	e8 9a b9 ff ff       	call   801018f1 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f5a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f5e:	66 83 f8 01          	cmp    $0x1,%ax
80105f62:	75 21                	jne    80105f85 <sys_open+0xe6>
80105f64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f67:	85 c0                	test   %eax,%eax
80105f69:	74 1a                	je     80105f85 <sys_open+0xe6>
      iunlockput(ip);
80105f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f6e:	89 04 24             	mov    %eax,(%esp)
80105f71:	e8 05 bc ff ff       	call   80101b7b <iunlockput>
      end_op();
80105f76:	e8 13 d6 ff ff       	call   8010358e <end_op>
      return -1;
80105f7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f80:	e9 b2 00 00 00       	jmp    80106037 <sys_open+0x198>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105f85:	e8 ba af ff ff       	call   80100f44 <filealloc>
80105f8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f8d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f91:	74 14                	je     80105fa7 <sys_open+0x108>
80105f93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f96:	89 04 24             	mov    %eax,(%esp)
80105f99:	e8 2f f7 ff ff       	call   801056cd <fdalloc>
80105f9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105fa1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105fa5:	79 28                	jns    80105fcf <sys_open+0x130>
    if(f)
80105fa7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fab:	74 0b                	je     80105fb8 <sys_open+0x119>
      fileclose(f);
80105fad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb0:	89 04 24             	mov    %eax,(%esp)
80105fb3:	e8 34 b0 ff ff       	call   80100fec <fileclose>
    iunlockput(ip);
80105fb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fbb:	89 04 24             	mov    %eax,(%esp)
80105fbe:	e8 b8 bb ff ff       	call   80101b7b <iunlockput>
    end_op();
80105fc3:	e8 c6 d5 ff ff       	call   8010358e <end_op>
    return -1;
80105fc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fcd:	eb 68                	jmp    80106037 <sys_open+0x198>
  }
  iunlock(ip);
80105fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd2:	89 04 24             	mov    %eax,(%esp)
80105fd5:	e8 6b ba ff ff       	call   80101a45 <iunlock>
  end_op();
80105fda:	e8 af d5 ff ff       	call   8010358e <end_op>

  f->type = FD_INODE;
80105fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fe2:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105fe8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105feb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105fee:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105ff1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff4:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105ffb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ffe:	83 e0 01             	and    $0x1,%eax
80106001:	85 c0                	test   %eax,%eax
80106003:	0f 94 c2             	sete   %dl
80106006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106009:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010600c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010600f:	83 e0 01             	and    $0x1,%eax
80106012:	84 c0                	test   %al,%al
80106014:	75 0a                	jne    80106020 <sys_open+0x181>
80106016:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106019:	83 e0 02             	and    $0x2,%eax
8010601c:	85 c0                	test   %eax,%eax
8010601e:	74 07                	je     80106027 <sys_open+0x188>
80106020:	b8 01 00 00 00       	mov    $0x1,%eax
80106025:	eb 05                	jmp    8010602c <sys_open+0x18d>
80106027:	b8 00 00 00 00       	mov    $0x0,%eax
8010602c:	89 c2                	mov    %eax,%edx
8010602e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106031:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106034:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106037:	c9                   	leave  
80106038:	c3                   	ret    

80106039 <sys_mkdir>:

int
sys_mkdir(void)
{
80106039:	55                   	push   %ebp
8010603a:	89 e5                	mov    %esp,%ebp
8010603c:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010603f:	e8 c9 d4 ff ff       	call   8010350d <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106044:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106047:	89 44 24 04          	mov    %eax,0x4(%esp)
8010604b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106052:	e8 3b f5 ff ff       	call   80105592 <argstr>
80106057:	85 c0                	test   %eax,%eax
80106059:	78 2c                	js     80106087 <sys_mkdir+0x4e>
8010605b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010605e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106065:	00 
80106066:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010606d:	00 
8010606e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106075:	00 
80106076:	89 04 24             	mov    %eax,(%esp)
80106079:	e8 61 fc ff ff       	call   80105cdf <create>
8010607e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106081:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106085:	75 0c                	jne    80106093 <sys_mkdir+0x5a>
    end_op();
80106087:	e8 02 d5 ff ff       	call   8010358e <end_op>
    return -1;
8010608c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106091:	eb 15                	jmp    801060a8 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106093:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106096:	89 04 24             	mov    %eax,(%esp)
80106099:	e8 dd ba ff ff       	call   80101b7b <iunlockput>
  end_op();
8010609e:	e8 eb d4 ff ff       	call   8010358e <end_op>
  return 0;
801060a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060a8:	c9                   	leave  
801060a9:	c3                   	ret    

801060aa <sys_mknod>:

int
sys_mknod(void)
{
801060aa:	55                   	push   %ebp
801060ab:	89 e5                	mov    %esp,%ebp
801060ad:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801060b0:	e8 58 d4 ff ff       	call   8010350d <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801060b5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801060bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060c3:	e8 ca f4 ff ff       	call   80105592 <argstr>
801060c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060cf:	78 5e                	js     8010612f <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801060d1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801060d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060df:	e8 1e f4 ff ff       	call   80105502 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801060e4:	85 c0                	test   %eax,%eax
801060e6:	78 47                	js     8010612f <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060e8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ef:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801060f6:	e8 07 f4 ff ff       	call   80105502 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801060fb:	85 c0                	test   %eax,%eax
801060fd:	78 30                	js     8010612f <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801060ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106102:	0f bf c8             	movswl %ax,%ecx
80106105:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106108:	0f bf d0             	movswl %ax,%edx
8010610b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010610e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106112:	89 54 24 08          	mov    %edx,0x8(%esp)
80106116:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010611d:	00 
8010611e:	89 04 24             	mov    %eax,(%esp)
80106121:	e8 b9 fb ff ff       	call   80105cdf <create>
80106126:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106129:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010612d:	75 0c                	jne    8010613b <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010612f:	e8 5a d4 ff ff       	call   8010358e <end_op>
    return -1;
80106134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106139:	eb 15                	jmp    80106150 <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010613b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010613e:	89 04 24             	mov    %eax,(%esp)
80106141:	e8 35 ba ff ff       	call   80101b7b <iunlockput>
  end_op();
80106146:	e8 43 d4 ff ff       	call   8010358e <end_op>
  return 0;
8010614b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106150:	c9                   	leave  
80106151:	c3                   	ret    

80106152 <sys_chdir>:

int
sys_chdir(void)
{
80106152:	55                   	push   %ebp
80106153:	89 e5                	mov    %esp,%ebp
80106155:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106158:	e8 b0 d3 ff ff       	call   8010350d <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
8010615d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106160:	89 44 24 04          	mov    %eax,0x4(%esp)
80106164:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010616b:	e8 22 f4 ff ff       	call   80105592 <argstr>
80106170:	85 c0                	test   %eax,%eax
80106172:	78 14                	js     80106188 <sys_chdir+0x36>
80106174:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106177:	89 04 24             	mov    %eax,(%esp)
8010617a:	e8 1a c3 ff ff       	call   80102499 <namei>
8010617f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106182:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106186:	75 0c                	jne    80106194 <sys_chdir+0x42>
    end_op();
80106188:	e8 01 d4 ff ff       	call   8010358e <end_op>
    return -1;
8010618d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106192:	eb 61                	jmp    801061f5 <sys_chdir+0xa3>
  }
  ilock(ip);
80106194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106197:	89 04 24             	mov    %eax,(%esp)
8010619a:	e8 52 b7 ff ff       	call   801018f1 <ilock>
  if(ip->type != T_DIR){
8010619f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061a6:	66 83 f8 01          	cmp    $0x1,%ax
801061aa:	74 17                	je     801061c3 <sys_chdir+0x71>
    iunlockput(ip);
801061ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061af:	89 04 24             	mov    %eax,(%esp)
801061b2:	e8 c4 b9 ff ff       	call   80101b7b <iunlockput>
    end_op();
801061b7:	e8 d2 d3 ff ff       	call   8010358e <end_op>
    return -1;
801061bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c1:	eb 32                	jmp    801061f5 <sys_chdir+0xa3>
  }
  iunlock(ip);
801061c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c6:	89 04 24             	mov    %eax,(%esp)
801061c9:	e8 77 b8 ff ff       	call   80101a45 <iunlock>
  iput(proc->cwd);
801061ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061d4:	8b 40 68             	mov    0x68(%eax),%eax
801061d7:	89 04 24             	mov    %eax,(%esp)
801061da:	e8 cb b8 ff ff       	call   80101aaa <iput>
  end_op();
801061df:	e8 aa d3 ff ff       	call   8010358e <end_op>
  proc->cwd = ip;
801061e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061ed:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801061f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061f5:	c9                   	leave  
801061f6:	c3                   	ret    

801061f7 <sys_exec>:

int
sys_exec(void)
{
801061f7:	55                   	push   %ebp
801061f8:	89 e5                	mov    %esp,%ebp
801061fa:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106200:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106203:	89 44 24 04          	mov    %eax,0x4(%esp)
80106207:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010620e:	e8 7f f3 ff ff       	call   80105592 <argstr>
80106213:	85 c0                	test   %eax,%eax
80106215:	78 1a                	js     80106231 <sys_exec+0x3a>
80106217:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010621d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106221:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106228:	e8 d5 f2 ff ff       	call   80105502 <argint>
8010622d:	85 c0                	test   %eax,%eax
8010622f:	79 0a                	jns    8010623b <sys_exec+0x44>
    return -1;
80106231:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106236:	e9 cc 00 00 00       	jmp    80106307 <sys_exec+0x110>
  }
  memset(argv, 0, sizeof(argv));
8010623b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106242:	00 
80106243:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010624a:	00 
8010624b:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106251:	89 04 24             	mov    %eax,(%esp)
80106254:	e8 4d ef ff ff       	call   801051a6 <memset>
  for(i=0;; i++){
80106259:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106263:	83 f8 1f             	cmp    $0x1f,%eax
80106266:	76 0a                	jbe    80106272 <sys_exec+0x7b>
      return -1;
80106268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010626d:	e9 95 00 00 00       	jmp    80106307 <sys_exec+0x110>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106272:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106275:	c1 e0 02             	shl    $0x2,%eax
80106278:	89 c2                	mov    %eax,%edx
8010627a:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106280:	01 c2                	add    %eax,%edx
80106282:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106288:	89 44 24 04          	mov    %eax,0x4(%esp)
8010628c:	89 14 24             	mov    %edx,(%esp)
8010628f:	e8 d0 f1 ff ff       	call   80105464 <fetchint>
80106294:	85 c0                	test   %eax,%eax
80106296:	79 07                	jns    8010629f <sys_exec+0xa8>
      return -1;
80106298:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010629d:	eb 68                	jmp    80106307 <sys_exec+0x110>
    if(uarg == 0){
8010629f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062a5:	85 c0                	test   %eax,%eax
801062a7:	75 26                	jne    801062cf <sys_exec+0xd8>
      argv[i] = 0;
801062a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ac:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801062b3:	00 00 00 00 
      break;
801062b7:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801062b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062bb:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801062c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801062c5:	89 04 24             	mov    %eax,(%esp)
801062c8:	e8 4b a8 ff ff       	call   80100b18 <exec>
801062cd:	eb 38                	jmp    80106307 <sys_exec+0x110>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
801062cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801062d9:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062df:	01 c2                	add    %eax,%edx
801062e1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062e7:	89 54 24 04          	mov    %edx,0x4(%esp)
801062eb:	89 04 24             	mov    %eax,(%esp)
801062ee:	e8 ab f1 ff ff       	call   8010549e <fetchstr>
801062f3:	85 c0                	test   %eax,%eax
801062f5:	79 07                	jns    801062fe <sys_exec+0x107>
      return -1;
801062f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062fc:	eb 09                	jmp    80106307 <sys_exec+0x110>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801062fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106302:	e9 59 ff ff ff       	jmp    80106260 <sys_exec+0x69>
  return exec(path, argv);
}
80106307:	c9                   	leave  
80106308:	c3                   	ret    

80106309 <sys_pipe>:

int
sys_pipe(void)
{
80106309:	55                   	push   %ebp
8010630a:	89 e5                	mov    %esp,%ebp
8010630c:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010630f:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106316:	00 
80106317:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010631a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010631e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106325:	e8 06 f2 ff ff       	call   80105530 <argptr>
8010632a:	85 c0                	test   %eax,%eax
8010632c:	79 0a                	jns    80106338 <sys_pipe+0x2f>
    return -1;
8010632e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106333:	e9 9b 00 00 00       	jmp    801063d3 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106338:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010633b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010633f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106342:	89 04 24             	mov    %eax,(%esp)
80106345:	e8 ee dc ff ff       	call   80104038 <pipealloc>
8010634a:	85 c0                	test   %eax,%eax
8010634c:	79 07                	jns    80106355 <sys_pipe+0x4c>
    return -1;
8010634e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106353:	eb 7e                	jmp    801063d3 <sys_pipe+0xca>
  fd0 = -1;
80106355:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010635c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010635f:	89 04 24             	mov    %eax,(%esp)
80106362:	e8 66 f3 ff ff       	call   801056cd <fdalloc>
80106367:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010636a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010636e:	78 14                	js     80106384 <sys_pipe+0x7b>
80106370:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106373:	89 04 24             	mov    %eax,(%esp)
80106376:	e8 52 f3 ff ff       	call   801056cd <fdalloc>
8010637b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010637e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106382:	79 37                	jns    801063bb <sys_pipe+0xb2>
    if(fd0 >= 0)
80106384:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106388:	78 14                	js     8010639e <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010638a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106390:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106393:	83 c2 08             	add    $0x8,%edx
80106396:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010639d:	00 
    fileclose(rf);
8010639e:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063a1:	89 04 24             	mov    %eax,(%esp)
801063a4:	e8 43 ac ff ff       	call   80100fec <fileclose>
    fileclose(wf);
801063a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063ac:	89 04 24             	mov    %eax,(%esp)
801063af:	e8 38 ac ff ff       	call   80100fec <fileclose>
    return -1;
801063b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063b9:	eb 18                	jmp    801063d3 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801063bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063c1:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801063c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063c6:	8d 50 04             	lea    0x4(%eax),%edx
801063c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063cc:	89 02                	mov    %eax,(%edx)
  return 0;
801063ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063d3:	c9                   	leave  
801063d4:	c3                   	ret    
801063d5:	00 00                	add    %al,(%eax)
	...

801063d8 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801063d8:	55                   	push   %ebp
801063d9:	89 e5                	mov    %esp,%ebp
801063db:	83 ec 08             	sub    $0x8,%esp
  return fork();
801063de:	e8 0e e3 ff ff       	call   801046f1 <fork>
}
801063e3:	c9                   	leave  
801063e4:	c3                   	ret    

801063e5 <sys_exit>:

int
sys_exit(void)
{
801063e5:	55                   	push   %ebp
801063e6:	89 e5                	mov    %esp,%ebp
801063e8:	83 ec 08             	sub    $0x8,%esp
  exit();
801063eb:	e8 7c e4 ff ff       	call   8010486c <exit>
  return 0;  // not reached
801063f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063f5:	c9                   	leave  
801063f6:	c3                   	ret    

801063f7 <sys_wait>:

int
sys_wait(void)
{
801063f7:	55                   	push   %ebp
801063f8:	89 e5                	mov    %esp,%ebp
801063fa:	83 ec 08             	sub    $0x8,%esp
  return wait();
801063fd:	e8 8c e5 ff ff       	call   8010498e <wait>
}
80106402:	c9                   	leave  
80106403:	c3                   	ret    

80106404 <sys_kill>:

int
sys_kill(void)
{
80106404:	55                   	push   %ebp
80106405:	89 e5                	mov    %esp,%ebp
80106407:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010640a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010640d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106411:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106418:	e8 e5 f0 ff ff       	call   80105502 <argint>
8010641d:	85 c0                	test   %eax,%eax
8010641f:	79 07                	jns    80106428 <sys_kill+0x24>
    return -1;
80106421:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106426:	eb 0b                	jmp    80106433 <sys_kill+0x2f>
  return kill(pid);
80106428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010642b:	89 04 24             	mov    %eax,(%esp)
8010642e:	e8 4a e9 ff ff       	call   80104d7d <kill>
}
80106433:	c9                   	leave  
80106434:	c3                   	ret    

80106435 <sys_getpid>:

int
sys_getpid(void)
{
80106435:	55                   	push   %ebp
80106436:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106438:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010643e:	8b 40 10             	mov    0x10(%eax),%eax
}
80106441:	5d                   	pop    %ebp
80106442:	c3                   	ret    

80106443 <sys_sbrk>:

int
sys_sbrk(void)
{
80106443:	55                   	push   %ebp
80106444:	89 e5                	mov    %esp,%ebp
80106446:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;
  if(argint(0, &n) < 0)
80106449:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010644c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106450:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106457:	e8 a6 f0 ff ff       	call   80105502 <argint>
8010645c:	85 c0                	test   %eax,%eax
8010645e:	79 07                	jns    80106467 <sys_sbrk+0x24>
    return -1;
80106460:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106465:	eb 1c                	jmp    80106483 <sys_sbrk+0x40>
  addr = proc->sz;
80106467:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010646d:	8b 00                	mov    (%eax),%eax
8010646f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  proc->sz = addr + n;
80106472:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106478:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010647b:	03 55 f4             	add    -0xc(%ebp),%edx
8010647e:	89 10                	mov    %edx,(%eax)
  return addr;
80106480:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106483:	c9                   	leave  
80106484:	c3                   	ret    

80106485 <sys_sleep>:

int
sys_sleep(void)
{
80106485:	55                   	push   %ebp
80106486:	89 e5                	mov    %esp,%ebp
80106488:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010648b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010648e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106492:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106499:	e8 64 f0 ff ff       	call   80105502 <argint>
8010649e:	85 c0                	test   %eax,%eax
801064a0:	79 07                	jns    801064a9 <sys_sleep+0x24>
    return -1;
801064a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a7:	eb 6c                	jmp    80106515 <sys_sleep+0x90>
  acquire(&tickslock);
801064a9:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801064b0:	e8 a2 ea ff ff       	call   80104f57 <acquire>
  ticks0 = ticks;
801064b5:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801064ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801064bd:	eb 34                	jmp    801064f3 <sys_sleep+0x6e>
    if(proc->killed){
801064bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064c5:	8b 40 24             	mov    0x24(%eax),%eax
801064c8:	85 c0                	test   %eax,%eax
801064ca:	74 13                	je     801064df <sys_sleep+0x5a>
      release(&tickslock);
801064cc:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801064d3:	e8 e1 ea ff ff       	call   80104fb9 <release>
      return -1;
801064d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064dd:	eb 36                	jmp    80106515 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801064df:	c7 44 24 04 a0 48 11 	movl   $0x801148a0,0x4(%esp)
801064e6:	80 
801064e7:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
801064ee:	e8 86 e7 ff ff       	call   80104c79 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801064f3:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801064f8:	89 c2                	mov    %eax,%edx
801064fa:	2b 55 f4             	sub    -0xc(%ebp),%edx
801064fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106500:	39 c2                	cmp    %eax,%edx
80106502:	72 bb                	jb     801064bf <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106504:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010650b:	e8 a9 ea ff ff       	call   80104fb9 <release>
  return 0;
80106510:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106515:	c9                   	leave  
80106516:	c3                   	ret    

80106517 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106517:	55                   	push   %ebp
80106518:	89 e5                	mov    %esp,%ebp
8010651a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010651d:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106524:	e8 2e ea ff ff       	call   80104f57 <acquire>
  xticks = ticks;
80106529:	a1 e0 50 11 80       	mov    0x801150e0,%eax
8010652e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106531:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106538:	e8 7c ea ff ff       	call   80104fb9 <release>
  return xticks;
8010653d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106540:	c9                   	leave  
80106541:	c3                   	ret    
	...

80106544 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106544:	55                   	push   %ebp
80106545:	89 e5                	mov    %esp,%ebp
80106547:	83 ec 08             	sub    $0x8,%esp
8010654a:	8b 55 08             	mov    0x8(%ebp),%edx
8010654d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106550:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106554:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106557:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010655b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010655f:	ee                   	out    %al,(%dx)
}
80106560:	c9                   	leave  
80106561:	c3                   	ret    

80106562 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106562:	55                   	push   %ebp
80106563:	89 e5                	mov    %esp,%ebp
80106565:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106568:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010656f:	00 
80106570:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106577:	e8 c8 ff ff ff       	call   80106544 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010657c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106583:	00 
80106584:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010658b:	e8 b4 ff ff ff       	call   80106544 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106590:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106597:	00 
80106598:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010659f:	e8 a0 ff ff ff       	call   80106544 <outb>
  picenable(IRQ_TIMER);
801065a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065ab:	e8 11 d9 ff ff       	call   80103ec1 <picenable>
}
801065b0:	c9                   	leave  
801065b1:	c3                   	ret    
	...

801065b4 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801065b4:	1e                   	push   %ds
  pushl %es
801065b5:	06                   	push   %es
  pushl %fs
801065b6:	0f a0                	push   %fs
  pushl %gs
801065b8:	0f a8                	push   %gs
  pushal
801065ba:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801065bb:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801065bf:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801065c1:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801065c3:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801065c7:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801065c9:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801065cb:	54                   	push   %esp
  call trap
801065cc:	e8 eb 01 00 00       	call   801067bc <trap>
  addl $4, %esp
801065d1:	83 c4 04             	add    $0x4,%esp

801065d4 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801065d4:	61                   	popa   
  popl %gs
801065d5:	0f a9                	pop    %gs
  popl %fs
801065d7:	0f a1                	pop    %fs
  popl %es
801065d9:	07                   	pop    %es
  popl %ds
801065da:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801065db:	83 c4 08             	add    $0x8,%esp
  iret
801065de:	cf                   	iret   
	...

801065e0 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801065e0:	55                   	push   %ebp
801065e1:	89 e5                	mov    %esp,%ebp
801065e3:	8b 45 08             	mov    0x8(%ebp),%eax
801065e6:	05 00 00 00 80       	add    $0x80000000,%eax
801065eb:	5d                   	pop    %ebp
801065ec:	c3                   	ret    

801065ed <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801065ed:	55                   	push   %ebp
801065ee:	89 e5                	mov    %esp,%ebp
801065f0:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801065f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801065f6:	83 e8 01             	sub    $0x1,%eax
801065f9:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801065fd:	8b 45 08             	mov    0x8(%ebp),%eax
80106600:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106604:	8b 45 08             	mov    0x8(%ebp),%eax
80106607:	c1 e8 10             	shr    $0x10,%eax
8010660a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010660e:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106611:	0f 01 18             	lidtl  (%eax)
}
80106614:	c9                   	leave  
80106615:	c3                   	ret    

80106616 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106616:	55                   	push   %ebp
80106617:	89 e5                	mov    %esp,%ebp
80106619:	53                   	push   %ebx
8010661a:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010661d:	0f 20 d3             	mov    %cr2,%ebx
80106620:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106623:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106626:	83 c4 10             	add    $0x10,%esp
80106629:	5b                   	pop    %ebx
8010662a:	5d                   	pop    %ebp
8010662b:	c3                   	ret    

8010662c <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010662c:	55                   	push   %ebp
8010662d:	89 e5                	mov    %esp,%ebp
8010662f:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106632:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106639:	e9 c3 00 00 00       	jmp    80106701 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010663e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106641:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106648:	89 c2                	mov    %eax,%edx
8010664a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664d:	66 89 14 c5 e0 48 11 	mov    %dx,-0x7feeb720(,%eax,8)
80106654:	80 
80106655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106658:	66 c7 04 c5 e2 48 11 	movw   $0x8,-0x7feeb71e(,%eax,8)
8010665f:	80 08 00 
80106662:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106665:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
8010666c:	80 
8010666d:	83 e2 e0             	and    $0xffffffe0,%edx
80106670:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
80106677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667a:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
80106681:	80 
80106682:	83 e2 1f             	and    $0x1f,%edx
80106685:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
8010668c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668f:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
80106696:	80 
80106697:	83 e2 f0             	and    $0xfffffff0,%edx
8010669a:	83 ca 0e             	or     $0xe,%edx
8010669d:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801066a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a7:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801066ae:	80 
801066af:	83 e2 ef             	and    $0xffffffef,%edx
801066b2:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801066b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bc:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801066c3:	80 
801066c4:	83 e2 9f             	and    $0xffffff9f,%edx
801066c7:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801066ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d1:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801066d8:	80 
801066d9:	83 ca 80             	or     $0xffffff80,%edx
801066dc:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801066e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e6:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801066ed:	c1 e8 10             	shr    $0x10,%eax
801066f0:	89 c2                	mov    %eax,%edx
801066f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f5:	66 89 14 c5 e6 48 11 	mov    %dx,-0x7feeb71a(,%eax,8)
801066fc:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801066fd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106701:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106708:	0f 8e 30 ff ff ff    	jle    8010663e <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010670e:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106713:	66 a3 e0 4a 11 80    	mov    %ax,0x80114ae0
80106719:	66 c7 05 e2 4a 11 80 	movw   $0x8,0x80114ae2
80106720:	08 00 
80106722:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
80106729:	83 e0 e0             	and    $0xffffffe0,%eax
8010672c:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
80106731:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
80106738:	83 e0 1f             	and    $0x1f,%eax
8010673b:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
80106740:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106747:	83 c8 0f             	or     $0xf,%eax
8010674a:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010674f:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106756:	83 e0 ef             	and    $0xffffffef,%eax
80106759:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010675e:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106765:	83 c8 60             	or     $0x60,%eax
80106768:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010676d:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106774:	83 c8 80             	or     $0xffffff80,%eax
80106777:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010677c:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106781:	c1 e8 10             	shr    $0x10,%eax
80106784:	66 a3 e6 4a 11 80    	mov    %ax,0x80114ae6
  
  initlock(&tickslock, "time");
8010678a:	c7 44 24 04 8c 8a 10 	movl   $0x80108a8c,0x4(%esp)
80106791:	80 
80106792:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106799:	e8 98 e7 ff ff       	call   80104f36 <initlock>
}
8010679e:	c9                   	leave  
8010679f:	c3                   	ret    

801067a0 <idtinit>:

void
idtinit(void)
{
801067a0:	55                   	push   %ebp
801067a1:	89 e5                	mov    %esp,%ebp
801067a3:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801067a6:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801067ad:	00 
801067ae:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
801067b5:	e8 33 fe ff ff       	call   801065ed <lidt>
}
801067ba:	c9                   	leave  
801067bb:	c3                   	ret    

801067bc <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801067bc:	55                   	push   %ebp
801067bd:	89 e5                	mov    %esp,%ebp
801067bf:	57                   	push   %edi
801067c0:	56                   	push   %esi
801067c1:	53                   	push   %ebx
801067c2:	83 ec 4c             	sub    $0x4c,%esp
  if(tf->trapno == T_SYSCALL){
801067c5:	8b 45 08             	mov    0x8(%ebp),%eax
801067c8:	8b 40 30             	mov    0x30(%eax),%eax
801067cb:	83 f8 40             	cmp    $0x40,%eax
801067ce:	75 3e                	jne    8010680e <trap+0x52>
    if(proc->killed)
801067d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067d6:	8b 40 24             	mov    0x24(%eax),%eax
801067d9:	85 c0                	test   %eax,%eax
801067db:	74 05                	je     801067e2 <trap+0x26>
      exit();
801067dd:	e8 8a e0 ff ff       	call   8010486c <exit>
    proc->tf = tf;
801067e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067e8:	8b 55 08             	mov    0x8(%ebp),%edx
801067eb:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801067ee:	e8 d6 ed ff ff       	call   801055c9 <syscall>
    if(proc->killed)
801067f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067f9:	8b 40 24             	mov    0x24(%eax),%eax
801067fc:	85 c0                	test   %eax,%eax
801067fe:	0f 84 ac 02 00 00    	je     80106ab0 <trap+0x2f4>
      exit();
80106804:	e8 63 e0 ff ff       	call   8010486c <exit>
    return;
80106809:	e9 a2 02 00 00       	jmp    80106ab0 <trap+0x2f4>
  }

  if(tf->trapno == T_PGFLT){
8010680e:	8b 45 08             	mov    0x8(%ebp),%eax
80106811:	8b 40 30             	mov    0x30(%eax),%eax
80106814:	83 f8 0e             	cmp    $0xe,%eax
80106817:	75 6d                	jne    80106886 <trap+0xca>
    char* mem;
    uint pg;
    pg = PGROUNDDOWN(rcr2());
80106819:	e8 f8 fd ff ff       	call   80106616 <rcr2>
8010681e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106823:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    mem = kalloc();
80106826:	e8 98 c3 ff ff       	call   80102bc3 <kalloc>
8010682b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    memset(mem, 0, PGSIZE);
8010682e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80106835:	00 
80106836:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010683d:	00 
8010683e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80106841:	89 04 24             	mov    %eax,(%esp)
80106844:	e8 5d e9 ff ff       	call   801051a6 <memset>
    mappages(proc->pgdir, (char*)pg, PGSIZE, v2p(mem), PTE_W|PTE_U);
80106849:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010684c:	89 04 24             	mov    %eax,(%esp)
8010684f:	e8 8c fd ff ff       	call   801065e0 <v2p>
80106854:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80106857:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010685e:	8b 52 04             	mov    0x4(%edx),%edx
80106861:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80106868:	00 
80106869:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010686d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80106874:	00 
80106875:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106879:	89 14 24             	mov    %edx,(%esp)
8010687c:	e8 44 14 00 00       	call   80107cc5 <mappages>
    return;
80106881:	e9 2b 02 00 00       	jmp    80106ab1 <trap+0x2f5>
  }
  
  switch(tf->trapno){
80106886:	8b 45 08             	mov    0x8(%ebp),%eax
80106889:	8b 40 30             	mov    0x30(%eax),%eax
8010688c:	83 e8 20             	sub    $0x20,%eax
8010688f:	83 f8 1f             	cmp    $0x1f,%eax
80106892:	0f 87 bc 00 00 00    	ja     80106954 <trap+0x198>
80106898:	8b 04 85 34 8b 10 80 	mov    -0x7fef74cc(,%eax,4),%eax
8010689f:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801068a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801068a7:	0f b6 00             	movzbl (%eax),%eax
801068aa:	84 c0                	test   %al,%al
801068ac:	75 31                	jne    801068df <trap+0x123>
      acquire(&tickslock);
801068ae:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801068b5:	e8 9d e6 ff ff       	call   80104f57 <acquire>
      ticks++;
801068ba:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801068bf:	83 c0 01             	add    $0x1,%eax
801068c2:	a3 e0 50 11 80       	mov    %eax,0x801150e0
      wakeup(&ticks);
801068c7:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
801068ce:	e8 7f e4 ff ff       	call   80104d52 <wakeup>
      release(&tickslock);
801068d3:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801068da:	e8 da e6 ff ff       	call   80104fb9 <release>
    }
    lapiceoi();
801068df:	e8 f3 c6 ff ff       	call   80102fd7 <lapiceoi>
    break;
801068e4:	e9 41 01 00 00       	jmp    80106a2a <trap+0x26e>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801068e9:	e8 ca be ff ff       	call   801027b8 <ideintr>
    lapiceoi();
801068ee:	e8 e4 c6 ff ff       	call   80102fd7 <lapiceoi>
    break;
801068f3:	e9 32 01 00 00       	jmp    80106a2a <trap+0x26e>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801068f8:	e8 8e c4 ff ff       	call   80102d8b <kbdintr>
    lapiceoi();
801068fd:	e8 d5 c6 ff ff       	call   80102fd7 <lapiceoi>
    break;
80106902:	e9 23 01 00 00       	jmp    80106a2a <trap+0x26e>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106907:	e8 ac 03 00 00       	call   80106cb8 <uartintr>
    lapiceoi();
8010690c:	e8 c6 c6 ff ff       	call   80102fd7 <lapiceoi>
    break;
80106911:	e9 14 01 00 00       	jmp    80106a2a <trap+0x26e>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106916:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106919:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010691c:	8b 45 08             	mov    0x8(%ebp),%eax
8010691f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106923:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106926:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010692c:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010692f:	0f b6 c0             	movzbl %al,%eax
80106932:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106936:	89 54 24 08          	mov    %edx,0x8(%esp)
8010693a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010693e:	c7 04 24 94 8a 10 80 	movl   $0x80108a94,(%esp)
80106945:	e8 57 9a ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010694a:	e8 88 c6 ff ff       	call   80102fd7 <lapiceoi>
    break;
8010694f:	e9 d6 00 00 00       	jmp    80106a2a <trap+0x26e>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106954:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010695a:	85 c0                	test   %eax,%eax
8010695c:	74 11                	je     8010696f <trap+0x1b3>
8010695e:	8b 45 08             	mov    0x8(%ebp),%eax
80106961:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106965:	0f b7 c0             	movzwl %ax,%eax
80106968:	83 e0 03             	and    $0x3,%eax
8010696b:	85 c0                	test   %eax,%eax
8010696d:	75 46                	jne    801069b5 <trap+0x1f9>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010696f:	e8 a2 fc ff ff       	call   80106616 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106974:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106977:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010697a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106981:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106984:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106987:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010698a:	8b 52 30             	mov    0x30(%edx),%edx
8010698d:	89 44 24 10          	mov    %eax,0x10(%esp)
80106991:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106995:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106999:	89 54 24 04          	mov    %edx,0x4(%esp)
8010699d:	c7 04 24 b8 8a 10 80 	movl   $0x80108ab8,(%esp)
801069a4:	e8 f8 99 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801069a9:	c7 04 24 ea 8a 10 80 	movl   $0x80108aea,(%esp)
801069b0:	e8 88 9b ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069b5:	e8 5c fc ff ff       	call   80106616 <rcr2>
801069ba:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069bc:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069bf:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069c2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801069c8:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069cb:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069ce:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069d1:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069d4:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069d7:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069e0:	83 c0 6c             	add    $0x6c,%eax
801069e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
801069e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069ec:	8b 40 10             	mov    0x10(%eax),%eax
801069ef:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801069f3:	89 7c 24 18          	mov    %edi,0x18(%esp)
801069f7:	89 74 24 14          	mov    %esi,0x14(%esp)
801069fb:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801069ff:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a03:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80106a06:	89 54 24 08          	mov    %edx,0x8(%esp)
80106a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a0e:	c7 04 24 f0 8a 10 80 	movl   $0x80108af0,(%esp)
80106a15:	e8 87 99 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106a1a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a20:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106a27:	eb 01                	jmp    80106a2a <trap+0x26e>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106a29:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a2a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a30:	85 c0                	test   %eax,%eax
80106a32:	74 24                	je     80106a58 <trap+0x29c>
80106a34:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a3a:	8b 40 24             	mov    0x24(%eax),%eax
80106a3d:	85 c0                	test   %eax,%eax
80106a3f:	74 17                	je     80106a58 <trap+0x29c>
80106a41:	8b 45 08             	mov    0x8(%ebp),%eax
80106a44:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a48:	0f b7 c0             	movzwl %ax,%eax
80106a4b:	83 e0 03             	and    $0x3,%eax
80106a4e:	83 f8 03             	cmp    $0x3,%eax
80106a51:	75 05                	jne    80106a58 <trap+0x29c>
    exit();
80106a53:	e8 14 de ff ff       	call   8010486c <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106a58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a5e:	85 c0                	test   %eax,%eax
80106a60:	74 1e                	je     80106a80 <trap+0x2c4>
80106a62:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a68:	8b 40 0c             	mov    0xc(%eax),%eax
80106a6b:	83 f8 04             	cmp    $0x4,%eax
80106a6e:	75 10                	jne    80106a80 <trap+0x2c4>
80106a70:	8b 45 08             	mov    0x8(%ebp),%eax
80106a73:	8b 40 30             	mov    0x30(%eax),%eax
80106a76:	83 f8 20             	cmp    $0x20,%eax
80106a79:	75 05                	jne    80106a80 <trap+0x2c4>
    yield();
80106a7b:	e8 88 e1 ff ff       	call   80104c08 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a86:	85 c0                	test   %eax,%eax
80106a88:	74 27                	je     80106ab1 <trap+0x2f5>
80106a8a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a90:	8b 40 24             	mov    0x24(%eax),%eax
80106a93:	85 c0                	test   %eax,%eax
80106a95:	74 1a                	je     80106ab1 <trap+0x2f5>
80106a97:	8b 45 08             	mov    0x8(%ebp),%eax
80106a9a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a9e:	0f b7 c0             	movzwl %ax,%eax
80106aa1:	83 e0 03             	and    $0x3,%eax
80106aa4:	83 f8 03             	cmp    $0x3,%eax
80106aa7:	75 08                	jne    80106ab1 <trap+0x2f5>
    exit();
80106aa9:	e8 be dd ff ff       	call   8010486c <exit>
80106aae:	eb 01                	jmp    80106ab1 <trap+0x2f5>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106ab0:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106ab1:	83 c4 4c             	add    $0x4c,%esp
80106ab4:	5b                   	pop    %ebx
80106ab5:	5e                   	pop    %esi
80106ab6:	5f                   	pop    %edi
80106ab7:	5d                   	pop    %ebp
80106ab8:	c3                   	ret    
80106ab9:	00 00                	add    %al,(%eax)
	...

80106abc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106abc:	55                   	push   %ebp
80106abd:	89 e5                	mov    %esp,%ebp
80106abf:	53                   	push   %ebx
80106ac0:	83 ec 14             	sub    $0x14,%esp
80106ac3:	8b 45 08             	mov    0x8(%ebp),%eax
80106ac6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106aca:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106ace:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106ad2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106ad6:	ec                   	in     (%dx),%al
80106ad7:	89 c3                	mov    %eax,%ebx
80106ad9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106adc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106ae0:	83 c4 14             	add    $0x14,%esp
80106ae3:	5b                   	pop    %ebx
80106ae4:	5d                   	pop    %ebp
80106ae5:	c3                   	ret    

80106ae6 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106ae6:	55                   	push   %ebp
80106ae7:	89 e5                	mov    %esp,%ebp
80106ae9:	83 ec 08             	sub    $0x8,%esp
80106aec:	8b 55 08             	mov    0x8(%ebp),%edx
80106aef:	8b 45 0c             	mov    0xc(%ebp),%eax
80106af2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106af6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106af9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106afd:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106b01:	ee                   	out    %al,(%dx)
}
80106b02:	c9                   	leave  
80106b03:	c3                   	ret    

80106b04 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106b04:	55                   	push   %ebp
80106b05:	89 e5                	mov    %esp,%ebp
80106b07:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106b0a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b11:	00 
80106b12:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106b19:	e8 c8 ff ff ff       	call   80106ae6 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106b1e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106b25:	00 
80106b26:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b2d:	e8 b4 ff ff ff       	call   80106ae6 <outb>
  outb(COM1+0, 115200/9600);
80106b32:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106b39:	00 
80106b3a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b41:	e8 a0 ff ff ff       	call   80106ae6 <outb>
  outb(COM1+1, 0);
80106b46:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b4d:	00 
80106b4e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b55:	e8 8c ff ff ff       	call   80106ae6 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106b5a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106b61:	00 
80106b62:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b69:	e8 78 ff ff ff       	call   80106ae6 <outb>
  outb(COM1+4, 0);
80106b6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b75:	00 
80106b76:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106b7d:	e8 64 ff ff ff       	call   80106ae6 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106b82:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b89:	00 
80106b8a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b91:	e8 50 ff ff ff       	call   80106ae6 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106b96:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b9d:	e8 1a ff ff ff       	call   80106abc <inb>
80106ba2:	3c ff                	cmp    $0xff,%al
80106ba4:	74 6c                	je     80106c12 <uartinit+0x10e>
    return;
  uart = 1;
80106ba6:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106bad:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106bb0:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106bb7:	e8 00 ff ff ff       	call   80106abc <inb>
  inb(COM1+0);
80106bbc:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106bc3:	e8 f4 fe ff ff       	call   80106abc <inb>
  picenable(IRQ_COM1);
80106bc8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106bcf:	e8 ed d2 ff ff       	call   80103ec1 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106bd4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106bdb:	00 
80106bdc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106be3:	e8 52 be ff ff       	call   80102a3a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106be8:	c7 45 f4 b4 8b 10 80 	movl   $0x80108bb4,-0xc(%ebp)
80106bef:	eb 15                	jmp    80106c06 <uartinit+0x102>
    uartputc(*p);
80106bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bf4:	0f b6 00             	movzbl (%eax),%eax
80106bf7:	0f be c0             	movsbl %al,%eax
80106bfa:	89 04 24             	mov    %eax,(%esp)
80106bfd:	e8 13 00 00 00       	call   80106c15 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106c02:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c09:	0f b6 00             	movzbl (%eax),%eax
80106c0c:	84 c0                	test   %al,%al
80106c0e:	75 e1                	jne    80106bf1 <uartinit+0xed>
80106c10:	eb 01                	jmp    80106c13 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106c12:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106c13:	c9                   	leave  
80106c14:	c3                   	ret    

80106c15 <uartputc>:

void
uartputc(int c)
{
80106c15:	55                   	push   %ebp
80106c16:	89 e5                	mov    %esp,%ebp
80106c18:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106c1b:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106c20:	85 c0                	test   %eax,%eax
80106c22:	74 4d                	je     80106c71 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106c2b:	eb 10                	jmp    80106c3d <uartputc+0x28>
    microdelay(10);
80106c2d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106c34:	e8 c3 c3 ff ff       	call   80102ffc <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c39:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c3d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106c41:	7f 16                	jg     80106c59 <uartputc+0x44>
80106c43:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c4a:	e8 6d fe ff ff       	call   80106abc <inb>
80106c4f:	0f b6 c0             	movzbl %al,%eax
80106c52:	83 e0 20             	and    $0x20,%eax
80106c55:	85 c0                	test   %eax,%eax
80106c57:	74 d4                	je     80106c2d <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106c59:	8b 45 08             	mov    0x8(%ebp),%eax
80106c5c:	0f b6 c0             	movzbl %al,%eax
80106c5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c63:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c6a:	e8 77 fe ff ff       	call   80106ae6 <outb>
80106c6f:	eb 01                	jmp    80106c72 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106c71:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106c72:	c9                   	leave  
80106c73:	c3                   	ret    

80106c74 <uartgetc>:

static int
uartgetc(void)
{
80106c74:	55                   	push   %ebp
80106c75:	89 e5                	mov    %esp,%ebp
80106c77:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106c7a:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106c7f:	85 c0                	test   %eax,%eax
80106c81:	75 07                	jne    80106c8a <uartgetc+0x16>
    return -1;
80106c83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c88:	eb 2c                	jmp    80106cb6 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106c8a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c91:	e8 26 fe ff ff       	call   80106abc <inb>
80106c96:	0f b6 c0             	movzbl %al,%eax
80106c99:	83 e0 01             	and    $0x1,%eax
80106c9c:	85 c0                	test   %eax,%eax
80106c9e:	75 07                	jne    80106ca7 <uartgetc+0x33>
    return -1;
80106ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ca5:	eb 0f                	jmp    80106cb6 <uartgetc+0x42>
  return inb(COM1+0);
80106ca7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106cae:	e8 09 fe ff ff       	call   80106abc <inb>
80106cb3:	0f b6 c0             	movzbl %al,%eax
}
80106cb6:	c9                   	leave  
80106cb7:	c3                   	ret    

80106cb8 <uartintr>:

void
uartintr(void)
{
80106cb8:	55                   	push   %ebp
80106cb9:	89 e5                	mov    %esp,%ebp
80106cbb:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106cbe:	c7 04 24 74 6c 10 80 	movl   $0x80106c74,(%esp)
80106cc5:	e8 fe 9a ff ff       	call   801007c8 <consoleintr>
}
80106cca:	c9                   	leave  
80106ccb:	c3                   	ret    

80106ccc <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106ccc:	6a 00                	push   $0x0
  pushl $0
80106cce:	6a 00                	push   $0x0
  jmp alltraps
80106cd0:	e9 df f8 ff ff       	jmp    801065b4 <alltraps>

80106cd5 <vector1>:
.globl vector1
vector1:
  pushl $0
80106cd5:	6a 00                	push   $0x0
  pushl $1
80106cd7:	6a 01                	push   $0x1
  jmp alltraps
80106cd9:	e9 d6 f8 ff ff       	jmp    801065b4 <alltraps>

80106cde <vector2>:
.globl vector2
vector2:
  pushl $0
80106cde:	6a 00                	push   $0x0
  pushl $2
80106ce0:	6a 02                	push   $0x2
  jmp alltraps
80106ce2:	e9 cd f8 ff ff       	jmp    801065b4 <alltraps>

80106ce7 <vector3>:
.globl vector3
vector3:
  pushl $0
80106ce7:	6a 00                	push   $0x0
  pushl $3
80106ce9:	6a 03                	push   $0x3
  jmp alltraps
80106ceb:	e9 c4 f8 ff ff       	jmp    801065b4 <alltraps>

80106cf0 <vector4>:
.globl vector4
vector4:
  pushl $0
80106cf0:	6a 00                	push   $0x0
  pushl $4
80106cf2:	6a 04                	push   $0x4
  jmp alltraps
80106cf4:	e9 bb f8 ff ff       	jmp    801065b4 <alltraps>

80106cf9 <vector5>:
.globl vector5
vector5:
  pushl $0
80106cf9:	6a 00                	push   $0x0
  pushl $5
80106cfb:	6a 05                	push   $0x5
  jmp alltraps
80106cfd:	e9 b2 f8 ff ff       	jmp    801065b4 <alltraps>

80106d02 <vector6>:
.globl vector6
vector6:
  pushl $0
80106d02:	6a 00                	push   $0x0
  pushl $6
80106d04:	6a 06                	push   $0x6
  jmp alltraps
80106d06:	e9 a9 f8 ff ff       	jmp    801065b4 <alltraps>

80106d0b <vector7>:
.globl vector7
vector7:
  pushl $0
80106d0b:	6a 00                	push   $0x0
  pushl $7
80106d0d:	6a 07                	push   $0x7
  jmp alltraps
80106d0f:	e9 a0 f8 ff ff       	jmp    801065b4 <alltraps>

80106d14 <vector8>:
.globl vector8
vector8:
  pushl $8
80106d14:	6a 08                	push   $0x8
  jmp alltraps
80106d16:	e9 99 f8 ff ff       	jmp    801065b4 <alltraps>

80106d1b <vector9>:
.globl vector9
vector9:
  pushl $0
80106d1b:	6a 00                	push   $0x0
  pushl $9
80106d1d:	6a 09                	push   $0x9
  jmp alltraps
80106d1f:	e9 90 f8 ff ff       	jmp    801065b4 <alltraps>

80106d24 <vector10>:
.globl vector10
vector10:
  pushl $10
80106d24:	6a 0a                	push   $0xa
  jmp alltraps
80106d26:	e9 89 f8 ff ff       	jmp    801065b4 <alltraps>

80106d2b <vector11>:
.globl vector11
vector11:
  pushl $11
80106d2b:	6a 0b                	push   $0xb
  jmp alltraps
80106d2d:	e9 82 f8 ff ff       	jmp    801065b4 <alltraps>

80106d32 <vector12>:
.globl vector12
vector12:
  pushl $12
80106d32:	6a 0c                	push   $0xc
  jmp alltraps
80106d34:	e9 7b f8 ff ff       	jmp    801065b4 <alltraps>

80106d39 <vector13>:
.globl vector13
vector13:
  pushl $13
80106d39:	6a 0d                	push   $0xd
  jmp alltraps
80106d3b:	e9 74 f8 ff ff       	jmp    801065b4 <alltraps>

80106d40 <vector14>:
.globl vector14
vector14:
  pushl $14
80106d40:	6a 0e                	push   $0xe
  jmp alltraps
80106d42:	e9 6d f8 ff ff       	jmp    801065b4 <alltraps>

80106d47 <vector15>:
.globl vector15
vector15:
  pushl $0
80106d47:	6a 00                	push   $0x0
  pushl $15
80106d49:	6a 0f                	push   $0xf
  jmp alltraps
80106d4b:	e9 64 f8 ff ff       	jmp    801065b4 <alltraps>

80106d50 <vector16>:
.globl vector16
vector16:
  pushl $0
80106d50:	6a 00                	push   $0x0
  pushl $16
80106d52:	6a 10                	push   $0x10
  jmp alltraps
80106d54:	e9 5b f8 ff ff       	jmp    801065b4 <alltraps>

80106d59 <vector17>:
.globl vector17
vector17:
  pushl $17
80106d59:	6a 11                	push   $0x11
  jmp alltraps
80106d5b:	e9 54 f8 ff ff       	jmp    801065b4 <alltraps>

80106d60 <vector18>:
.globl vector18
vector18:
  pushl $0
80106d60:	6a 00                	push   $0x0
  pushl $18
80106d62:	6a 12                	push   $0x12
  jmp alltraps
80106d64:	e9 4b f8 ff ff       	jmp    801065b4 <alltraps>

80106d69 <vector19>:
.globl vector19
vector19:
  pushl $0
80106d69:	6a 00                	push   $0x0
  pushl $19
80106d6b:	6a 13                	push   $0x13
  jmp alltraps
80106d6d:	e9 42 f8 ff ff       	jmp    801065b4 <alltraps>

80106d72 <vector20>:
.globl vector20
vector20:
  pushl $0
80106d72:	6a 00                	push   $0x0
  pushl $20
80106d74:	6a 14                	push   $0x14
  jmp alltraps
80106d76:	e9 39 f8 ff ff       	jmp    801065b4 <alltraps>

80106d7b <vector21>:
.globl vector21
vector21:
  pushl $0
80106d7b:	6a 00                	push   $0x0
  pushl $21
80106d7d:	6a 15                	push   $0x15
  jmp alltraps
80106d7f:	e9 30 f8 ff ff       	jmp    801065b4 <alltraps>

80106d84 <vector22>:
.globl vector22
vector22:
  pushl $0
80106d84:	6a 00                	push   $0x0
  pushl $22
80106d86:	6a 16                	push   $0x16
  jmp alltraps
80106d88:	e9 27 f8 ff ff       	jmp    801065b4 <alltraps>

80106d8d <vector23>:
.globl vector23
vector23:
  pushl $0
80106d8d:	6a 00                	push   $0x0
  pushl $23
80106d8f:	6a 17                	push   $0x17
  jmp alltraps
80106d91:	e9 1e f8 ff ff       	jmp    801065b4 <alltraps>

80106d96 <vector24>:
.globl vector24
vector24:
  pushl $0
80106d96:	6a 00                	push   $0x0
  pushl $24
80106d98:	6a 18                	push   $0x18
  jmp alltraps
80106d9a:	e9 15 f8 ff ff       	jmp    801065b4 <alltraps>

80106d9f <vector25>:
.globl vector25
vector25:
  pushl $0
80106d9f:	6a 00                	push   $0x0
  pushl $25
80106da1:	6a 19                	push   $0x19
  jmp alltraps
80106da3:	e9 0c f8 ff ff       	jmp    801065b4 <alltraps>

80106da8 <vector26>:
.globl vector26
vector26:
  pushl $0
80106da8:	6a 00                	push   $0x0
  pushl $26
80106daa:	6a 1a                	push   $0x1a
  jmp alltraps
80106dac:	e9 03 f8 ff ff       	jmp    801065b4 <alltraps>

80106db1 <vector27>:
.globl vector27
vector27:
  pushl $0
80106db1:	6a 00                	push   $0x0
  pushl $27
80106db3:	6a 1b                	push   $0x1b
  jmp alltraps
80106db5:	e9 fa f7 ff ff       	jmp    801065b4 <alltraps>

80106dba <vector28>:
.globl vector28
vector28:
  pushl $0
80106dba:	6a 00                	push   $0x0
  pushl $28
80106dbc:	6a 1c                	push   $0x1c
  jmp alltraps
80106dbe:	e9 f1 f7 ff ff       	jmp    801065b4 <alltraps>

80106dc3 <vector29>:
.globl vector29
vector29:
  pushl $0
80106dc3:	6a 00                	push   $0x0
  pushl $29
80106dc5:	6a 1d                	push   $0x1d
  jmp alltraps
80106dc7:	e9 e8 f7 ff ff       	jmp    801065b4 <alltraps>

80106dcc <vector30>:
.globl vector30
vector30:
  pushl $0
80106dcc:	6a 00                	push   $0x0
  pushl $30
80106dce:	6a 1e                	push   $0x1e
  jmp alltraps
80106dd0:	e9 df f7 ff ff       	jmp    801065b4 <alltraps>

80106dd5 <vector31>:
.globl vector31
vector31:
  pushl $0
80106dd5:	6a 00                	push   $0x0
  pushl $31
80106dd7:	6a 1f                	push   $0x1f
  jmp alltraps
80106dd9:	e9 d6 f7 ff ff       	jmp    801065b4 <alltraps>

80106dde <vector32>:
.globl vector32
vector32:
  pushl $0
80106dde:	6a 00                	push   $0x0
  pushl $32
80106de0:	6a 20                	push   $0x20
  jmp alltraps
80106de2:	e9 cd f7 ff ff       	jmp    801065b4 <alltraps>

80106de7 <vector33>:
.globl vector33
vector33:
  pushl $0
80106de7:	6a 00                	push   $0x0
  pushl $33
80106de9:	6a 21                	push   $0x21
  jmp alltraps
80106deb:	e9 c4 f7 ff ff       	jmp    801065b4 <alltraps>

80106df0 <vector34>:
.globl vector34
vector34:
  pushl $0
80106df0:	6a 00                	push   $0x0
  pushl $34
80106df2:	6a 22                	push   $0x22
  jmp alltraps
80106df4:	e9 bb f7 ff ff       	jmp    801065b4 <alltraps>

80106df9 <vector35>:
.globl vector35
vector35:
  pushl $0
80106df9:	6a 00                	push   $0x0
  pushl $35
80106dfb:	6a 23                	push   $0x23
  jmp alltraps
80106dfd:	e9 b2 f7 ff ff       	jmp    801065b4 <alltraps>

80106e02 <vector36>:
.globl vector36
vector36:
  pushl $0
80106e02:	6a 00                	push   $0x0
  pushl $36
80106e04:	6a 24                	push   $0x24
  jmp alltraps
80106e06:	e9 a9 f7 ff ff       	jmp    801065b4 <alltraps>

80106e0b <vector37>:
.globl vector37
vector37:
  pushl $0
80106e0b:	6a 00                	push   $0x0
  pushl $37
80106e0d:	6a 25                	push   $0x25
  jmp alltraps
80106e0f:	e9 a0 f7 ff ff       	jmp    801065b4 <alltraps>

80106e14 <vector38>:
.globl vector38
vector38:
  pushl $0
80106e14:	6a 00                	push   $0x0
  pushl $38
80106e16:	6a 26                	push   $0x26
  jmp alltraps
80106e18:	e9 97 f7 ff ff       	jmp    801065b4 <alltraps>

80106e1d <vector39>:
.globl vector39
vector39:
  pushl $0
80106e1d:	6a 00                	push   $0x0
  pushl $39
80106e1f:	6a 27                	push   $0x27
  jmp alltraps
80106e21:	e9 8e f7 ff ff       	jmp    801065b4 <alltraps>

80106e26 <vector40>:
.globl vector40
vector40:
  pushl $0
80106e26:	6a 00                	push   $0x0
  pushl $40
80106e28:	6a 28                	push   $0x28
  jmp alltraps
80106e2a:	e9 85 f7 ff ff       	jmp    801065b4 <alltraps>

80106e2f <vector41>:
.globl vector41
vector41:
  pushl $0
80106e2f:	6a 00                	push   $0x0
  pushl $41
80106e31:	6a 29                	push   $0x29
  jmp alltraps
80106e33:	e9 7c f7 ff ff       	jmp    801065b4 <alltraps>

80106e38 <vector42>:
.globl vector42
vector42:
  pushl $0
80106e38:	6a 00                	push   $0x0
  pushl $42
80106e3a:	6a 2a                	push   $0x2a
  jmp alltraps
80106e3c:	e9 73 f7 ff ff       	jmp    801065b4 <alltraps>

80106e41 <vector43>:
.globl vector43
vector43:
  pushl $0
80106e41:	6a 00                	push   $0x0
  pushl $43
80106e43:	6a 2b                	push   $0x2b
  jmp alltraps
80106e45:	e9 6a f7 ff ff       	jmp    801065b4 <alltraps>

80106e4a <vector44>:
.globl vector44
vector44:
  pushl $0
80106e4a:	6a 00                	push   $0x0
  pushl $44
80106e4c:	6a 2c                	push   $0x2c
  jmp alltraps
80106e4e:	e9 61 f7 ff ff       	jmp    801065b4 <alltraps>

80106e53 <vector45>:
.globl vector45
vector45:
  pushl $0
80106e53:	6a 00                	push   $0x0
  pushl $45
80106e55:	6a 2d                	push   $0x2d
  jmp alltraps
80106e57:	e9 58 f7 ff ff       	jmp    801065b4 <alltraps>

80106e5c <vector46>:
.globl vector46
vector46:
  pushl $0
80106e5c:	6a 00                	push   $0x0
  pushl $46
80106e5e:	6a 2e                	push   $0x2e
  jmp alltraps
80106e60:	e9 4f f7 ff ff       	jmp    801065b4 <alltraps>

80106e65 <vector47>:
.globl vector47
vector47:
  pushl $0
80106e65:	6a 00                	push   $0x0
  pushl $47
80106e67:	6a 2f                	push   $0x2f
  jmp alltraps
80106e69:	e9 46 f7 ff ff       	jmp    801065b4 <alltraps>

80106e6e <vector48>:
.globl vector48
vector48:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $48
80106e70:	6a 30                	push   $0x30
  jmp alltraps
80106e72:	e9 3d f7 ff ff       	jmp    801065b4 <alltraps>

80106e77 <vector49>:
.globl vector49
vector49:
  pushl $0
80106e77:	6a 00                	push   $0x0
  pushl $49
80106e79:	6a 31                	push   $0x31
  jmp alltraps
80106e7b:	e9 34 f7 ff ff       	jmp    801065b4 <alltraps>

80106e80 <vector50>:
.globl vector50
vector50:
  pushl $0
80106e80:	6a 00                	push   $0x0
  pushl $50
80106e82:	6a 32                	push   $0x32
  jmp alltraps
80106e84:	e9 2b f7 ff ff       	jmp    801065b4 <alltraps>

80106e89 <vector51>:
.globl vector51
vector51:
  pushl $0
80106e89:	6a 00                	push   $0x0
  pushl $51
80106e8b:	6a 33                	push   $0x33
  jmp alltraps
80106e8d:	e9 22 f7 ff ff       	jmp    801065b4 <alltraps>

80106e92 <vector52>:
.globl vector52
vector52:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $52
80106e94:	6a 34                	push   $0x34
  jmp alltraps
80106e96:	e9 19 f7 ff ff       	jmp    801065b4 <alltraps>

80106e9b <vector53>:
.globl vector53
vector53:
  pushl $0
80106e9b:	6a 00                	push   $0x0
  pushl $53
80106e9d:	6a 35                	push   $0x35
  jmp alltraps
80106e9f:	e9 10 f7 ff ff       	jmp    801065b4 <alltraps>

80106ea4 <vector54>:
.globl vector54
vector54:
  pushl $0
80106ea4:	6a 00                	push   $0x0
  pushl $54
80106ea6:	6a 36                	push   $0x36
  jmp alltraps
80106ea8:	e9 07 f7 ff ff       	jmp    801065b4 <alltraps>

80106ead <vector55>:
.globl vector55
vector55:
  pushl $0
80106ead:	6a 00                	push   $0x0
  pushl $55
80106eaf:	6a 37                	push   $0x37
  jmp alltraps
80106eb1:	e9 fe f6 ff ff       	jmp    801065b4 <alltraps>

80106eb6 <vector56>:
.globl vector56
vector56:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $56
80106eb8:	6a 38                	push   $0x38
  jmp alltraps
80106eba:	e9 f5 f6 ff ff       	jmp    801065b4 <alltraps>

80106ebf <vector57>:
.globl vector57
vector57:
  pushl $0
80106ebf:	6a 00                	push   $0x0
  pushl $57
80106ec1:	6a 39                	push   $0x39
  jmp alltraps
80106ec3:	e9 ec f6 ff ff       	jmp    801065b4 <alltraps>

80106ec8 <vector58>:
.globl vector58
vector58:
  pushl $0
80106ec8:	6a 00                	push   $0x0
  pushl $58
80106eca:	6a 3a                	push   $0x3a
  jmp alltraps
80106ecc:	e9 e3 f6 ff ff       	jmp    801065b4 <alltraps>

80106ed1 <vector59>:
.globl vector59
vector59:
  pushl $0
80106ed1:	6a 00                	push   $0x0
  pushl $59
80106ed3:	6a 3b                	push   $0x3b
  jmp alltraps
80106ed5:	e9 da f6 ff ff       	jmp    801065b4 <alltraps>

80106eda <vector60>:
.globl vector60
vector60:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $60
80106edc:	6a 3c                	push   $0x3c
  jmp alltraps
80106ede:	e9 d1 f6 ff ff       	jmp    801065b4 <alltraps>

80106ee3 <vector61>:
.globl vector61
vector61:
  pushl $0
80106ee3:	6a 00                	push   $0x0
  pushl $61
80106ee5:	6a 3d                	push   $0x3d
  jmp alltraps
80106ee7:	e9 c8 f6 ff ff       	jmp    801065b4 <alltraps>

80106eec <vector62>:
.globl vector62
vector62:
  pushl $0
80106eec:	6a 00                	push   $0x0
  pushl $62
80106eee:	6a 3e                	push   $0x3e
  jmp alltraps
80106ef0:	e9 bf f6 ff ff       	jmp    801065b4 <alltraps>

80106ef5 <vector63>:
.globl vector63
vector63:
  pushl $0
80106ef5:	6a 00                	push   $0x0
  pushl $63
80106ef7:	6a 3f                	push   $0x3f
  jmp alltraps
80106ef9:	e9 b6 f6 ff ff       	jmp    801065b4 <alltraps>

80106efe <vector64>:
.globl vector64
vector64:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $64
80106f00:	6a 40                	push   $0x40
  jmp alltraps
80106f02:	e9 ad f6 ff ff       	jmp    801065b4 <alltraps>

80106f07 <vector65>:
.globl vector65
vector65:
  pushl $0
80106f07:	6a 00                	push   $0x0
  pushl $65
80106f09:	6a 41                	push   $0x41
  jmp alltraps
80106f0b:	e9 a4 f6 ff ff       	jmp    801065b4 <alltraps>

80106f10 <vector66>:
.globl vector66
vector66:
  pushl $0
80106f10:	6a 00                	push   $0x0
  pushl $66
80106f12:	6a 42                	push   $0x42
  jmp alltraps
80106f14:	e9 9b f6 ff ff       	jmp    801065b4 <alltraps>

80106f19 <vector67>:
.globl vector67
vector67:
  pushl $0
80106f19:	6a 00                	push   $0x0
  pushl $67
80106f1b:	6a 43                	push   $0x43
  jmp alltraps
80106f1d:	e9 92 f6 ff ff       	jmp    801065b4 <alltraps>

80106f22 <vector68>:
.globl vector68
vector68:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $68
80106f24:	6a 44                	push   $0x44
  jmp alltraps
80106f26:	e9 89 f6 ff ff       	jmp    801065b4 <alltraps>

80106f2b <vector69>:
.globl vector69
vector69:
  pushl $0
80106f2b:	6a 00                	push   $0x0
  pushl $69
80106f2d:	6a 45                	push   $0x45
  jmp alltraps
80106f2f:	e9 80 f6 ff ff       	jmp    801065b4 <alltraps>

80106f34 <vector70>:
.globl vector70
vector70:
  pushl $0
80106f34:	6a 00                	push   $0x0
  pushl $70
80106f36:	6a 46                	push   $0x46
  jmp alltraps
80106f38:	e9 77 f6 ff ff       	jmp    801065b4 <alltraps>

80106f3d <vector71>:
.globl vector71
vector71:
  pushl $0
80106f3d:	6a 00                	push   $0x0
  pushl $71
80106f3f:	6a 47                	push   $0x47
  jmp alltraps
80106f41:	e9 6e f6 ff ff       	jmp    801065b4 <alltraps>

80106f46 <vector72>:
.globl vector72
vector72:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $72
80106f48:	6a 48                	push   $0x48
  jmp alltraps
80106f4a:	e9 65 f6 ff ff       	jmp    801065b4 <alltraps>

80106f4f <vector73>:
.globl vector73
vector73:
  pushl $0
80106f4f:	6a 00                	push   $0x0
  pushl $73
80106f51:	6a 49                	push   $0x49
  jmp alltraps
80106f53:	e9 5c f6 ff ff       	jmp    801065b4 <alltraps>

80106f58 <vector74>:
.globl vector74
vector74:
  pushl $0
80106f58:	6a 00                	push   $0x0
  pushl $74
80106f5a:	6a 4a                	push   $0x4a
  jmp alltraps
80106f5c:	e9 53 f6 ff ff       	jmp    801065b4 <alltraps>

80106f61 <vector75>:
.globl vector75
vector75:
  pushl $0
80106f61:	6a 00                	push   $0x0
  pushl $75
80106f63:	6a 4b                	push   $0x4b
  jmp alltraps
80106f65:	e9 4a f6 ff ff       	jmp    801065b4 <alltraps>

80106f6a <vector76>:
.globl vector76
vector76:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $76
80106f6c:	6a 4c                	push   $0x4c
  jmp alltraps
80106f6e:	e9 41 f6 ff ff       	jmp    801065b4 <alltraps>

80106f73 <vector77>:
.globl vector77
vector77:
  pushl $0
80106f73:	6a 00                	push   $0x0
  pushl $77
80106f75:	6a 4d                	push   $0x4d
  jmp alltraps
80106f77:	e9 38 f6 ff ff       	jmp    801065b4 <alltraps>

80106f7c <vector78>:
.globl vector78
vector78:
  pushl $0
80106f7c:	6a 00                	push   $0x0
  pushl $78
80106f7e:	6a 4e                	push   $0x4e
  jmp alltraps
80106f80:	e9 2f f6 ff ff       	jmp    801065b4 <alltraps>

80106f85 <vector79>:
.globl vector79
vector79:
  pushl $0
80106f85:	6a 00                	push   $0x0
  pushl $79
80106f87:	6a 4f                	push   $0x4f
  jmp alltraps
80106f89:	e9 26 f6 ff ff       	jmp    801065b4 <alltraps>

80106f8e <vector80>:
.globl vector80
vector80:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $80
80106f90:	6a 50                	push   $0x50
  jmp alltraps
80106f92:	e9 1d f6 ff ff       	jmp    801065b4 <alltraps>

80106f97 <vector81>:
.globl vector81
vector81:
  pushl $0
80106f97:	6a 00                	push   $0x0
  pushl $81
80106f99:	6a 51                	push   $0x51
  jmp alltraps
80106f9b:	e9 14 f6 ff ff       	jmp    801065b4 <alltraps>

80106fa0 <vector82>:
.globl vector82
vector82:
  pushl $0
80106fa0:	6a 00                	push   $0x0
  pushl $82
80106fa2:	6a 52                	push   $0x52
  jmp alltraps
80106fa4:	e9 0b f6 ff ff       	jmp    801065b4 <alltraps>

80106fa9 <vector83>:
.globl vector83
vector83:
  pushl $0
80106fa9:	6a 00                	push   $0x0
  pushl $83
80106fab:	6a 53                	push   $0x53
  jmp alltraps
80106fad:	e9 02 f6 ff ff       	jmp    801065b4 <alltraps>

80106fb2 <vector84>:
.globl vector84
vector84:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $84
80106fb4:	6a 54                	push   $0x54
  jmp alltraps
80106fb6:	e9 f9 f5 ff ff       	jmp    801065b4 <alltraps>

80106fbb <vector85>:
.globl vector85
vector85:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $85
80106fbd:	6a 55                	push   $0x55
  jmp alltraps
80106fbf:	e9 f0 f5 ff ff       	jmp    801065b4 <alltraps>

80106fc4 <vector86>:
.globl vector86
vector86:
  pushl $0
80106fc4:	6a 00                	push   $0x0
  pushl $86
80106fc6:	6a 56                	push   $0x56
  jmp alltraps
80106fc8:	e9 e7 f5 ff ff       	jmp    801065b4 <alltraps>

80106fcd <vector87>:
.globl vector87
vector87:
  pushl $0
80106fcd:	6a 00                	push   $0x0
  pushl $87
80106fcf:	6a 57                	push   $0x57
  jmp alltraps
80106fd1:	e9 de f5 ff ff       	jmp    801065b4 <alltraps>

80106fd6 <vector88>:
.globl vector88
vector88:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $88
80106fd8:	6a 58                	push   $0x58
  jmp alltraps
80106fda:	e9 d5 f5 ff ff       	jmp    801065b4 <alltraps>

80106fdf <vector89>:
.globl vector89
vector89:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $89
80106fe1:	6a 59                	push   $0x59
  jmp alltraps
80106fe3:	e9 cc f5 ff ff       	jmp    801065b4 <alltraps>

80106fe8 <vector90>:
.globl vector90
vector90:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $90
80106fea:	6a 5a                	push   $0x5a
  jmp alltraps
80106fec:	e9 c3 f5 ff ff       	jmp    801065b4 <alltraps>

80106ff1 <vector91>:
.globl vector91
vector91:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $91
80106ff3:	6a 5b                	push   $0x5b
  jmp alltraps
80106ff5:	e9 ba f5 ff ff       	jmp    801065b4 <alltraps>

80106ffa <vector92>:
.globl vector92
vector92:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $92
80106ffc:	6a 5c                	push   $0x5c
  jmp alltraps
80106ffe:	e9 b1 f5 ff ff       	jmp    801065b4 <alltraps>

80107003 <vector93>:
.globl vector93
vector93:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $93
80107005:	6a 5d                	push   $0x5d
  jmp alltraps
80107007:	e9 a8 f5 ff ff       	jmp    801065b4 <alltraps>

8010700c <vector94>:
.globl vector94
vector94:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $94
8010700e:	6a 5e                	push   $0x5e
  jmp alltraps
80107010:	e9 9f f5 ff ff       	jmp    801065b4 <alltraps>

80107015 <vector95>:
.globl vector95
vector95:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $95
80107017:	6a 5f                	push   $0x5f
  jmp alltraps
80107019:	e9 96 f5 ff ff       	jmp    801065b4 <alltraps>

8010701e <vector96>:
.globl vector96
vector96:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $96
80107020:	6a 60                	push   $0x60
  jmp alltraps
80107022:	e9 8d f5 ff ff       	jmp    801065b4 <alltraps>

80107027 <vector97>:
.globl vector97
vector97:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $97
80107029:	6a 61                	push   $0x61
  jmp alltraps
8010702b:	e9 84 f5 ff ff       	jmp    801065b4 <alltraps>

80107030 <vector98>:
.globl vector98
vector98:
  pushl $0
80107030:	6a 00                	push   $0x0
  pushl $98
80107032:	6a 62                	push   $0x62
  jmp alltraps
80107034:	e9 7b f5 ff ff       	jmp    801065b4 <alltraps>

80107039 <vector99>:
.globl vector99
vector99:
  pushl $0
80107039:	6a 00                	push   $0x0
  pushl $99
8010703b:	6a 63                	push   $0x63
  jmp alltraps
8010703d:	e9 72 f5 ff ff       	jmp    801065b4 <alltraps>

80107042 <vector100>:
.globl vector100
vector100:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $100
80107044:	6a 64                	push   $0x64
  jmp alltraps
80107046:	e9 69 f5 ff ff       	jmp    801065b4 <alltraps>

8010704b <vector101>:
.globl vector101
vector101:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $101
8010704d:	6a 65                	push   $0x65
  jmp alltraps
8010704f:	e9 60 f5 ff ff       	jmp    801065b4 <alltraps>

80107054 <vector102>:
.globl vector102
vector102:
  pushl $0
80107054:	6a 00                	push   $0x0
  pushl $102
80107056:	6a 66                	push   $0x66
  jmp alltraps
80107058:	e9 57 f5 ff ff       	jmp    801065b4 <alltraps>

8010705d <vector103>:
.globl vector103
vector103:
  pushl $0
8010705d:	6a 00                	push   $0x0
  pushl $103
8010705f:	6a 67                	push   $0x67
  jmp alltraps
80107061:	e9 4e f5 ff ff       	jmp    801065b4 <alltraps>

80107066 <vector104>:
.globl vector104
vector104:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $104
80107068:	6a 68                	push   $0x68
  jmp alltraps
8010706a:	e9 45 f5 ff ff       	jmp    801065b4 <alltraps>

8010706f <vector105>:
.globl vector105
vector105:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $105
80107071:	6a 69                	push   $0x69
  jmp alltraps
80107073:	e9 3c f5 ff ff       	jmp    801065b4 <alltraps>

80107078 <vector106>:
.globl vector106
vector106:
  pushl $0
80107078:	6a 00                	push   $0x0
  pushl $106
8010707a:	6a 6a                	push   $0x6a
  jmp alltraps
8010707c:	e9 33 f5 ff ff       	jmp    801065b4 <alltraps>

80107081 <vector107>:
.globl vector107
vector107:
  pushl $0
80107081:	6a 00                	push   $0x0
  pushl $107
80107083:	6a 6b                	push   $0x6b
  jmp alltraps
80107085:	e9 2a f5 ff ff       	jmp    801065b4 <alltraps>

8010708a <vector108>:
.globl vector108
vector108:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $108
8010708c:	6a 6c                	push   $0x6c
  jmp alltraps
8010708e:	e9 21 f5 ff ff       	jmp    801065b4 <alltraps>

80107093 <vector109>:
.globl vector109
vector109:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $109
80107095:	6a 6d                	push   $0x6d
  jmp alltraps
80107097:	e9 18 f5 ff ff       	jmp    801065b4 <alltraps>

8010709c <vector110>:
.globl vector110
vector110:
  pushl $0
8010709c:	6a 00                	push   $0x0
  pushl $110
8010709e:	6a 6e                	push   $0x6e
  jmp alltraps
801070a0:	e9 0f f5 ff ff       	jmp    801065b4 <alltraps>

801070a5 <vector111>:
.globl vector111
vector111:
  pushl $0
801070a5:	6a 00                	push   $0x0
  pushl $111
801070a7:	6a 6f                	push   $0x6f
  jmp alltraps
801070a9:	e9 06 f5 ff ff       	jmp    801065b4 <alltraps>

801070ae <vector112>:
.globl vector112
vector112:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $112
801070b0:	6a 70                	push   $0x70
  jmp alltraps
801070b2:	e9 fd f4 ff ff       	jmp    801065b4 <alltraps>

801070b7 <vector113>:
.globl vector113
vector113:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $113
801070b9:	6a 71                	push   $0x71
  jmp alltraps
801070bb:	e9 f4 f4 ff ff       	jmp    801065b4 <alltraps>

801070c0 <vector114>:
.globl vector114
vector114:
  pushl $0
801070c0:	6a 00                	push   $0x0
  pushl $114
801070c2:	6a 72                	push   $0x72
  jmp alltraps
801070c4:	e9 eb f4 ff ff       	jmp    801065b4 <alltraps>

801070c9 <vector115>:
.globl vector115
vector115:
  pushl $0
801070c9:	6a 00                	push   $0x0
  pushl $115
801070cb:	6a 73                	push   $0x73
  jmp alltraps
801070cd:	e9 e2 f4 ff ff       	jmp    801065b4 <alltraps>

801070d2 <vector116>:
.globl vector116
vector116:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $116
801070d4:	6a 74                	push   $0x74
  jmp alltraps
801070d6:	e9 d9 f4 ff ff       	jmp    801065b4 <alltraps>

801070db <vector117>:
.globl vector117
vector117:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $117
801070dd:	6a 75                	push   $0x75
  jmp alltraps
801070df:	e9 d0 f4 ff ff       	jmp    801065b4 <alltraps>

801070e4 <vector118>:
.globl vector118
vector118:
  pushl $0
801070e4:	6a 00                	push   $0x0
  pushl $118
801070e6:	6a 76                	push   $0x76
  jmp alltraps
801070e8:	e9 c7 f4 ff ff       	jmp    801065b4 <alltraps>

801070ed <vector119>:
.globl vector119
vector119:
  pushl $0
801070ed:	6a 00                	push   $0x0
  pushl $119
801070ef:	6a 77                	push   $0x77
  jmp alltraps
801070f1:	e9 be f4 ff ff       	jmp    801065b4 <alltraps>

801070f6 <vector120>:
.globl vector120
vector120:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $120
801070f8:	6a 78                	push   $0x78
  jmp alltraps
801070fa:	e9 b5 f4 ff ff       	jmp    801065b4 <alltraps>

801070ff <vector121>:
.globl vector121
vector121:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $121
80107101:	6a 79                	push   $0x79
  jmp alltraps
80107103:	e9 ac f4 ff ff       	jmp    801065b4 <alltraps>

80107108 <vector122>:
.globl vector122
vector122:
  pushl $0
80107108:	6a 00                	push   $0x0
  pushl $122
8010710a:	6a 7a                	push   $0x7a
  jmp alltraps
8010710c:	e9 a3 f4 ff ff       	jmp    801065b4 <alltraps>

80107111 <vector123>:
.globl vector123
vector123:
  pushl $0
80107111:	6a 00                	push   $0x0
  pushl $123
80107113:	6a 7b                	push   $0x7b
  jmp alltraps
80107115:	e9 9a f4 ff ff       	jmp    801065b4 <alltraps>

8010711a <vector124>:
.globl vector124
vector124:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $124
8010711c:	6a 7c                	push   $0x7c
  jmp alltraps
8010711e:	e9 91 f4 ff ff       	jmp    801065b4 <alltraps>

80107123 <vector125>:
.globl vector125
vector125:
  pushl $0
80107123:	6a 00                	push   $0x0
  pushl $125
80107125:	6a 7d                	push   $0x7d
  jmp alltraps
80107127:	e9 88 f4 ff ff       	jmp    801065b4 <alltraps>

8010712c <vector126>:
.globl vector126
vector126:
  pushl $0
8010712c:	6a 00                	push   $0x0
  pushl $126
8010712e:	6a 7e                	push   $0x7e
  jmp alltraps
80107130:	e9 7f f4 ff ff       	jmp    801065b4 <alltraps>

80107135 <vector127>:
.globl vector127
vector127:
  pushl $0
80107135:	6a 00                	push   $0x0
  pushl $127
80107137:	6a 7f                	push   $0x7f
  jmp alltraps
80107139:	e9 76 f4 ff ff       	jmp    801065b4 <alltraps>

8010713e <vector128>:
.globl vector128
vector128:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $128
80107140:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107145:	e9 6a f4 ff ff       	jmp    801065b4 <alltraps>

8010714a <vector129>:
.globl vector129
vector129:
  pushl $0
8010714a:	6a 00                	push   $0x0
  pushl $129
8010714c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107151:	e9 5e f4 ff ff       	jmp    801065b4 <alltraps>

80107156 <vector130>:
.globl vector130
vector130:
  pushl $0
80107156:	6a 00                	push   $0x0
  pushl $130
80107158:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010715d:	e9 52 f4 ff ff       	jmp    801065b4 <alltraps>

80107162 <vector131>:
.globl vector131
vector131:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $131
80107164:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107169:	e9 46 f4 ff ff       	jmp    801065b4 <alltraps>

8010716e <vector132>:
.globl vector132
vector132:
  pushl $0
8010716e:	6a 00                	push   $0x0
  pushl $132
80107170:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107175:	e9 3a f4 ff ff       	jmp    801065b4 <alltraps>

8010717a <vector133>:
.globl vector133
vector133:
  pushl $0
8010717a:	6a 00                	push   $0x0
  pushl $133
8010717c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107181:	e9 2e f4 ff ff       	jmp    801065b4 <alltraps>

80107186 <vector134>:
.globl vector134
vector134:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $134
80107188:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010718d:	e9 22 f4 ff ff       	jmp    801065b4 <alltraps>

80107192 <vector135>:
.globl vector135
vector135:
  pushl $0
80107192:	6a 00                	push   $0x0
  pushl $135
80107194:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107199:	e9 16 f4 ff ff       	jmp    801065b4 <alltraps>

8010719e <vector136>:
.globl vector136
vector136:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $136
801071a0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801071a5:	e9 0a f4 ff ff       	jmp    801065b4 <alltraps>

801071aa <vector137>:
.globl vector137
vector137:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $137
801071ac:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801071b1:	e9 fe f3 ff ff       	jmp    801065b4 <alltraps>

801071b6 <vector138>:
.globl vector138
vector138:
  pushl $0
801071b6:	6a 00                	push   $0x0
  pushl $138
801071b8:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801071bd:	e9 f2 f3 ff ff       	jmp    801065b4 <alltraps>

801071c2 <vector139>:
.globl vector139
vector139:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $139
801071c4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801071c9:	e9 e6 f3 ff ff       	jmp    801065b4 <alltraps>

801071ce <vector140>:
.globl vector140
vector140:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $140
801071d0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801071d5:	e9 da f3 ff ff       	jmp    801065b4 <alltraps>

801071da <vector141>:
.globl vector141
vector141:
  pushl $0
801071da:	6a 00                	push   $0x0
  pushl $141
801071dc:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801071e1:	e9 ce f3 ff ff       	jmp    801065b4 <alltraps>

801071e6 <vector142>:
.globl vector142
vector142:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $142
801071e8:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801071ed:	e9 c2 f3 ff ff       	jmp    801065b4 <alltraps>

801071f2 <vector143>:
.globl vector143
vector143:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $143
801071f4:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801071f9:	e9 b6 f3 ff ff       	jmp    801065b4 <alltraps>

801071fe <vector144>:
.globl vector144
vector144:
  pushl $0
801071fe:	6a 00                	push   $0x0
  pushl $144
80107200:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107205:	e9 aa f3 ff ff       	jmp    801065b4 <alltraps>

8010720a <vector145>:
.globl vector145
vector145:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $145
8010720c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107211:	e9 9e f3 ff ff       	jmp    801065b4 <alltraps>

80107216 <vector146>:
.globl vector146
vector146:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $146
80107218:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010721d:	e9 92 f3 ff ff       	jmp    801065b4 <alltraps>

80107222 <vector147>:
.globl vector147
vector147:
  pushl $0
80107222:	6a 00                	push   $0x0
  pushl $147
80107224:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107229:	e9 86 f3 ff ff       	jmp    801065b4 <alltraps>

8010722e <vector148>:
.globl vector148
vector148:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $148
80107230:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107235:	e9 7a f3 ff ff       	jmp    801065b4 <alltraps>

8010723a <vector149>:
.globl vector149
vector149:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $149
8010723c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107241:	e9 6e f3 ff ff       	jmp    801065b4 <alltraps>

80107246 <vector150>:
.globl vector150
vector150:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $150
80107248:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010724d:	e9 62 f3 ff ff       	jmp    801065b4 <alltraps>

80107252 <vector151>:
.globl vector151
vector151:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $151
80107254:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107259:	e9 56 f3 ff ff       	jmp    801065b4 <alltraps>

8010725e <vector152>:
.globl vector152
vector152:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $152
80107260:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107265:	e9 4a f3 ff ff       	jmp    801065b4 <alltraps>

8010726a <vector153>:
.globl vector153
vector153:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $153
8010726c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107271:	e9 3e f3 ff ff       	jmp    801065b4 <alltraps>

80107276 <vector154>:
.globl vector154
vector154:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $154
80107278:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010727d:	e9 32 f3 ff ff       	jmp    801065b4 <alltraps>

80107282 <vector155>:
.globl vector155
vector155:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $155
80107284:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107289:	e9 26 f3 ff ff       	jmp    801065b4 <alltraps>

8010728e <vector156>:
.globl vector156
vector156:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $156
80107290:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107295:	e9 1a f3 ff ff       	jmp    801065b4 <alltraps>

8010729a <vector157>:
.globl vector157
vector157:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $157
8010729c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801072a1:	e9 0e f3 ff ff       	jmp    801065b4 <alltraps>

801072a6 <vector158>:
.globl vector158
vector158:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $158
801072a8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801072ad:	e9 02 f3 ff ff       	jmp    801065b4 <alltraps>

801072b2 <vector159>:
.globl vector159
vector159:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $159
801072b4:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801072b9:	e9 f6 f2 ff ff       	jmp    801065b4 <alltraps>

801072be <vector160>:
.globl vector160
vector160:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $160
801072c0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801072c5:	e9 ea f2 ff ff       	jmp    801065b4 <alltraps>

801072ca <vector161>:
.globl vector161
vector161:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $161
801072cc:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801072d1:	e9 de f2 ff ff       	jmp    801065b4 <alltraps>

801072d6 <vector162>:
.globl vector162
vector162:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $162
801072d8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801072dd:	e9 d2 f2 ff ff       	jmp    801065b4 <alltraps>

801072e2 <vector163>:
.globl vector163
vector163:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $163
801072e4:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801072e9:	e9 c6 f2 ff ff       	jmp    801065b4 <alltraps>

801072ee <vector164>:
.globl vector164
vector164:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $164
801072f0:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801072f5:	e9 ba f2 ff ff       	jmp    801065b4 <alltraps>

801072fa <vector165>:
.globl vector165
vector165:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $165
801072fc:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107301:	e9 ae f2 ff ff       	jmp    801065b4 <alltraps>

80107306 <vector166>:
.globl vector166
vector166:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $166
80107308:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010730d:	e9 a2 f2 ff ff       	jmp    801065b4 <alltraps>

80107312 <vector167>:
.globl vector167
vector167:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $167
80107314:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107319:	e9 96 f2 ff ff       	jmp    801065b4 <alltraps>

8010731e <vector168>:
.globl vector168
vector168:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $168
80107320:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107325:	e9 8a f2 ff ff       	jmp    801065b4 <alltraps>

8010732a <vector169>:
.globl vector169
vector169:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $169
8010732c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107331:	e9 7e f2 ff ff       	jmp    801065b4 <alltraps>

80107336 <vector170>:
.globl vector170
vector170:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $170
80107338:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010733d:	e9 72 f2 ff ff       	jmp    801065b4 <alltraps>

80107342 <vector171>:
.globl vector171
vector171:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $171
80107344:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107349:	e9 66 f2 ff ff       	jmp    801065b4 <alltraps>

8010734e <vector172>:
.globl vector172
vector172:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $172
80107350:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107355:	e9 5a f2 ff ff       	jmp    801065b4 <alltraps>

8010735a <vector173>:
.globl vector173
vector173:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $173
8010735c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107361:	e9 4e f2 ff ff       	jmp    801065b4 <alltraps>

80107366 <vector174>:
.globl vector174
vector174:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $174
80107368:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010736d:	e9 42 f2 ff ff       	jmp    801065b4 <alltraps>

80107372 <vector175>:
.globl vector175
vector175:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $175
80107374:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107379:	e9 36 f2 ff ff       	jmp    801065b4 <alltraps>

8010737e <vector176>:
.globl vector176
vector176:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $176
80107380:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107385:	e9 2a f2 ff ff       	jmp    801065b4 <alltraps>

8010738a <vector177>:
.globl vector177
vector177:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $177
8010738c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107391:	e9 1e f2 ff ff       	jmp    801065b4 <alltraps>

80107396 <vector178>:
.globl vector178
vector178:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $178
80107398:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010739d:	e9 12 f2 ff ff       	jmp    801065b4 <alltraps>

801073a2 <vector179>:
.globl vector179
vector179:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $179
801073a4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801073a9:	e9 06 f2 ff ff       	jmp    801065b4 <alltraps>

801073ae <vector180>:
.globl vector180
vector180:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $180
801073b0:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801073b5:	e9 fa f1 ff ff       	jmp    801065b4 <alltraps>

801073ba <vector181>:
.globl vector181
vector181:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $181
801073bc:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801073c1:	e9 ee f1 ff ff       	jmp    801065b4 <alltraps>

801073c6 <vector182>:
.globl vector182
vector182:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $182
801073c8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801073cd:	e9 e2 f1 ff ff       	jmp    801065b4 <alltraps>

801073d2 <vector183>:
.globl vector183
vector183:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $183
801073d4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801073d9:	e9 d6 f1 ff ff       	jmp    801065b4 <alltraps>

801073de <vector184>:
.globl vector184
vector184:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $184
801073e0:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801073e5:	e9 ca f1 ff ff       	jmp    801065b4 <alltraps>

801073ea <vector185>:
.globl vector185
vector185:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $185
801073ec:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801073f1:	e9 be f1 ff ff       	jmp    801065b4 <alltraps>

801073f6 <vector186>:
.globl vector186
vector186:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $186
801073f8:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801073fd:	e9 b2 f1 ff ff       	jmp    801065b4 <alltraps>

80107402 <vector187>:
.globl vector187
vector187:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $187
80107404:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107409:	e9 a6 f1 ff ff       	jmp    801065b4 <alltraps>

8010740e <vector188>:
.globl vector188
vector188:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $188
80107410:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107415:	e9 9a f1 ff ff       	jmp    801065b4 <alltraps>

8010741a <vector189>:
.globl vector189
vector189:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $189
8010741c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107421:	e9 8e f1 ff ff       	jmp    801065b4 <alltraps>

80107426 <vector190>:
.globl vector190
vector190:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $190
80107428:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010742d:	e9 82 f1 ff ff       	jmp    801065b4 <alltraps>

80107432 <vector191>:
.globl vector191
vector191:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $191
80107434:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107439:	e9 76 f1 ff ff       	jmp    801065b4 <alltraps>

8010743e <vector192>:
.globl vector192
vector192:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $192
80107440:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107445:	e9 6a f1 ff ff       	jmp    801065b4 <alltraps>

8010744a <vector193>:
.globl vector193
vector193:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $193
8010744c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107451:	e9 5e f1 ff ff       	jmp    801065b4 <alltraps>

80107456 <vector194>:
.globl vector194
vector194:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $194
80107458:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010745d:	e9 52 f1 ff ff       	jmp    801065b4 <alltraps>

80107462 <vector195>:
.globl vector195
vector195:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $195
80107464:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107469:	e9 46 f1 ff ff       	jmp    801065b4 <alltraps>

8010746e <vector196>:
.globl vector196
vector196:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $196
80107470:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107475:	e9 3a f1 ff ff       	jmp    801065b4 <alltraps>

8010747a <vector197>:
.globl vector197
vector197:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $197
8010747c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107481:	e9 2e f1 ff ff       	jmp    801065b4 <alltraps>

80107486 <vector198>:
.globl vector198
vector198:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $198
80107488:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010748d:	e9 22 f1 ff ff       	jmp    801065b4 <alltraps>

80107492 <vector199>:
.globl vector199
vector199:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $199
80107494:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107499:	e9 16 f1 ff ff       	jmp    801065b4 <alltraps>

8010749e <vector200>:
.globl vector200
vector200:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $200
801074a0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801074a5:	e9 0a f1 ff ff       	jmp    801065b4 <alltraps>

801074aa <vector201>:
.globl vector201
vector201:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $201
801074ac:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801074b1:	e9 fe f0 ff ff       	jmp    801065b4 <alltraps>

801074b6 <vector202>:
.globl vector202
vector202:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $202
801074b8:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801074bd:	e9 f2 f0 ff ff       	jmp    801065b4 <alltraps>

801074c2 <vector203>:
.globl vector203
vector203:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $203
801074c4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801074c9:	e9 e6 f0 ff ff       	jmp    801065b4 <alltraps>

801074ce <vector204>:
.globl vector204
vector204:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $204
801074d0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801074d5:	e9 da f0 ff ff       	jmp    801065b4 <alltraps>

801074da <vector205>:
.globl vector205
vector205:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $205
801074dc:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801074e1:	e9 ce f0 ff ff       	jmp    801065b4 <alltraps>

801074e6 <vector206>:
.globl vector206
vector206:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $206
801074e8:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801074ed:	e9 c2 f0 ff ff       	jmp    801065b4 <alltraps>

801074f2 <vector207>:
.globl vector207
vector207:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $207
801074f4:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801074f9:	e9 b6 f0 ff ff       	jmp    801065b4 <alltraps>

801074fe <vector208>:
.globl vector208
vector208:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $208
80107500:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107505:	e9 aa f0 ff ff       	jmp    801065b4 <alltraps>

8010750a <vector209>:
.globl vector209
vector209:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $209
8010750c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107511:	e9 9e f0 ff ff       	jmp    801065b4 <alltraps>

80107516 <vector210>:
.globl vector210
vector210:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $210
80107518:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010751d:	e9 92 f0 ff ff       	jmp    801065b4 <alltraps>

80107522 <vector211>:
.globl vector211
vector211:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $211
80107524:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107529:	e9 86 f0 ff ff       	jmp    801065b4 <alltraps>

8010752e <vector212>:
.globl vector212
vector212:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $212
80107530:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107535:	e9 7a f0 ff ff       	jmp    801065b4 <alltraps>

8010753a <vector213>:
.globl vector213
vector213:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $213
8010753c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107541:	e9 6e f0 ff ff       	jmp    801065b4 <alltraps>

80107546 <vector214>:
.globl vector214
vector214:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $214
80107548:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010754d:	e9 62 f0 ff ff       	jmp    801065b4 <alltraps>

80107552 <vector215>:
.globl vector215
vector215:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $215
80107554:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107559:	e9 56 f0 ff ff       	jmp    801065b4 <alltraps>

8010755e <vector216>:
.globl vector216
vector216:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $216
80107560:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107565:	e9 4a f0 ff ff       	jmp    801065b4 <alltraps>

8010756a <vector217>:
.globl vector217
vector217:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $217
8010756c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107571:	e9 3e f0 ff ff       	jmp    801065b4 <alltraps>

80107576 <vector218>:
.globl vector218
vector218:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $218
80107578:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010757d:	e9 32 f0 ff ff       	jmp    801065b4 <alltraps>

80107582 <vector219>:
.globl vector219
vector219:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $219
80107584:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107589:	e9 26 f0 ff ff       	jmp    801065b4 <alltraps>

8010758e <vector220>:
.globl vector220
vector220:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $220
80107590:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107595:	e9 1a f0 ff ff       	jmp    801065b4 <alltraps>

8010759a <vector221>:
.globl vector221
vector221:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $221
8010759c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801075a1:	e9 0e f0 ff ff       	jmp    801065b4 <alltraps>

801075a6 <vector222>:
.globl vector222
vector222:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $222
801075a8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801075ad:	e9 02 f0 ff ff       	jmp    801065b4 <alltraps>

801075b2 <vector223>:
.globl vector223
vector223:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $223
801075b4:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801075b9:	e9 f6 ef ff ff       	jmp    801065b4 <alltraps>

801075be <vector224>:
.globl vector224
vector224:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $224
801075c0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801075c5:	e9 ea ef ff ff       	jmp    801065b4 <alltraps>

801075ca <vector225>:
.globl vector225
vector225:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $225
801075cc:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801075d1:	e9 de ef ff ff       	jmp    801065b4 <alltraps>

801075d6 <vector226>:
.globl vector226
vector226:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $226
801075d8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801075dd:	e9 d2 ef ff ff       	jmp    801065b4 <alltraps>

801075e2 <vector227>:
.globl vector227
vector227:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $227
801075e4:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801075e9:	e9 c6 ef ff ff       	jmp    801065b4 <alltraps>

801075ee <vector228>:
.globl vector228
vector228:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $228
801075f0:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801075f5:	e9 ba ef ff ff       	jmp    801065b4 <alltraps>

801075fa <vector229>:
.globl vector229
vector229:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $229
801075fc:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107601:	e9 ae ef ff ff       	jmp    801065b4 <alltraps>

80107606 <vector230>:
.globl vector230
vector230:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $230
80107608:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010760d:	e9 a2 ef ff ff       	jmp    801065b4 <alltraps>

80107612 <vector231>:
.globl vector231
vector231:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $231
80107614:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107619:	e9 96 ef ff ff       	jmp    801065b4 <alltraps>

8010761e <vector232>:
.globl vector232
vector232:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $232
80107620:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107625:	e9 8a ef ff ff       	jmp    801065b4 <alltraps>

8010762a <vector233>:
.globl vector233
vector233:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $233
8010762c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107631:	e9 7e ef ff ff       	jmp    801065b4 <alltraps>

80107636 <vector234>:
.globl vector234
vector234:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $234
80107638:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010763d:	e9 72 ef ff ff       	jmp    801065b4 <alltraps>

80107642 <vector235>:
.globl vector235
vector235:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $235
80107644:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107649:	e9 66 ef ff ff       	jmp    801065b4 <alltraps>

8010764e <vector236>:
.globl vector236
vector236:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $236
80107650:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107655:	e9 5a ef ff ff       	jmp    801065b4 <alltraps>

8010765a <vector237>:
.globl vector237
vector237:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $237
8010765c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107661:	e9 4e ef ff ff       	jmp    801065b4 <alltraps>

80107666 <vector238>:
.globl vector238
vector238:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $238
80107668:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010766d:	e9 42 ef ff ff       	jmp    801065b4 <alltraps>

80107672 <vector239>:
.globl vector239
vector239:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $239
80107674:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107679:	e9 36 ef ff ff       	jmp    801065b4 <alltraps>

8010767e <vector240>:
.globl vector240
vector240:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $240
80107680:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107685:	e9 2a ef ff ff       	jmp    801065b4 <alltraps>

8010768a <vector241>:
.globl vector241
vector241:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $241
8010768c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107691:	e9 1e ef ff ff       	jmp    801065b4 <alltraps>

80107696 <vector242>:
.globl vector242
vector242:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $242
80107698:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010769d:	e9 12 ef ff ff       	jmp    801065b4 <alltraps>

801076a2 <vector243>:
.globl vector243
vector243:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $243
801076a4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801076a9:	e9 06 ef ff ff       	jmp    801065b4 <alltraps>

801076ae <vector244>:
.globl vector244
vector244:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $244
801076b0:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801076b5:	e9 fa ee ff ff       	jmp    801065b4 <alltraps>

801076ba <vector245>:
.globl vector245
vector245:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $245
801076bc:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801076c1:	e9 ee ee ff ff       	jmp    801065b4 <alltraps>

801076c6 <vector246>:
.globl vector246
vector246:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $246
801076c8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801076cd:	e9 e2 ee ff ff       	jmp    801065b4 <alltraps>

801076d2 <vector247>:
.globl vector247
vector247:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $247
801076d4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801076d9:	e9 d6 ee ff ff       	jmp    801065b4 <alltraps>

801076de <vector248>:
.globl vector248
vector248:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $248
801076e0:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801076e5:	e9 ca ee ff ff       	jmp    801065b4 <alltraps>

801076ea <vector249>:
.globl vector249
vector249:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $249
801076ec:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801076f1:	e9 be ee ff ff       	jmp    801065b4 <alltraps>

801076f6 <vector250>:
.globl vector250
vector250:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $250
801076f8:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801076fd:	e9 b2 ee ff ff       	jmp    801065b4 <alltraps>

80107702 <vector251>:
.globl vector251
vector251:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $251
80107704:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107709:	e9 a6 ee ff ff       	jmp    801065b4 <alltraps>

8010770e <vector252>:
.globl vector252
vector252:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $252
80107710:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107715:	e9 9a ee ff ff       	jmp    801065b4 <alltraps>

8010771a <vector253>:
.globl vector253
vector253:
  pushl $0
8010771a:	6a 00                	push   $0x0
  pushl $253
8010771c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107721:	e9 8e ee ff ff       	jmp    801065b4 <alltraps>

80107726 <vector254>:
.globl vector254
vector254:
  pushl $0
80107726:	6a 00                	push   $0x0
  pushl $254
80107728:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010772d:	e9 82 ee ff ff       	jmp    801065b4 <alltraps>

80107732 <vector255>:
.globl vector255
vector255:
  pushl $0
80107732:	6a 00                	push   $0x0
  pushl $255
80107734:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107739:	e9 76 ee ff ff       	jmp    801065b4 <alltraps>
	...

80107740 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107740:	55                   	push   %ebp
80107741:	89 e5                	mov    %esp,%ebp
80107743:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107746:	8b 45 0c             	mov    0xc(%ebp),%eax
80107749:	83 e8 01             	sub    $0x1,%eax
8010774c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107750:	8b 45 08             	mov    0x8(%ebp),%eax
80107753:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107757:	8b 45 08             	mov    0x8(%ebp),%eax
8010775a:	c1 e8 10             	shr    $0x10,%eax
8010775d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107761:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107764:	0f 01 10             	lgdtl  (%eax)
}
80107767:	c9                   	leave  
80107768:	c3                   	ret    

80107769 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107769:	55                   	push   %ebp
8010776a:	89 e5                	mov    %esp,%ebp
8010776c:	83 ec 04             	sub    $0x4,%esp
8010776f:	8b 45 08             	mov    0x8(%ebp),%eax
80107772:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107776:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010777a:	0f 00 d8             	ltr    %ax
}
8010777d:	c9                   	leave  
8010777e:	c3                   	ret    

8010777f <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010777f:	55                   	push   %ebp
80107780:	89 e5                	mov    %esp,%ebp
80107782:	83 ec 04             	sub    $0x4,%esp
80107785:	8b 45 08             	mov    0x8(%ebp),%eax
80107788:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
8010778c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107790:	8e e8                	mov    %eax,%gs
}
80107792:	c9                   	leave  
80107793:	c3                   	ret    

80107794 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107794:	55                   	push   %ebp
80107795:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107797:	8b 45 08             	mov    0x8(%ebp),%eax
8010779a:	0f 22 d8             	mov    %eax,%cr3
}
8010779d:	5d                   	pop    %ebp
8010779e:	c3                   	ret    

8010779f <v2p>:
8010779f:	55                   	push   %ebp
801077a0:	89 e5                	mov    %esp,%ebp
801077a2:	8b 45 08             	mov    0x8(%ebp),%eax
801077a5:	05 00 00 00 80       	add    $0x80000000,%eax
801077aa:	5d                   	pop    %ebp
801077ab:	c3                   	ret    

801077ac <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801077ac:	55                   	push   %ebp
801077ad:	89 e5                	mov    %esp,%ebp
801077af:	8b 45 08             	mov    0x8(%ebp),%eax
801077b2:	05 00 00 00 80       	add    $0x80000000,%eax
801077b7:	5d                   	pop    %ebp
801077b8:	c3                   	ret    

801077b9 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801077b9:	55                   	push   %ebp
801077ba:	89 e5                	mov    %esp,%ebp
801077bc:	53                   	push   %ebx
801077bd:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801077c0:	e8 b6 b7 ff ff       	call   80102f7b <cpunum>
801077c5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801077cb:	05 60 23 11 80       	add    $0x80112360,%eax
801077d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801077d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d6:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801077dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077df:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801077e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e8:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801077ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ef:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077f3:	83 e2 f0             	and    $0xfffffff0,%edx
801077f6:	83 ca 0a             	or     $0xa,%edx
801077f9:	88 50 7d             	mov    %dl,0x7d(%eax)
801077fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ff:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107803:	83 ca 10             	or     $0x10,%edx
80107806:	88 50 7d             	mov    %dl,0x7d(%eax)
80107809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107810:	83 e2 9f             	and    $0xffffff9f,%edx
80107813:	88 50 7d             	mov    %dl,0x7d(%eax)
80107816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107819:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010781d:	83 ca 80             	or     $0xffffff80,%edx
80107820:	88 50 7d             	mov    %dl,0x7d(%eax)
80107823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107826:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010782a:	83 ca 0f             	or     $0xf,%edx
8010782d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107830:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107833:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107837:	83 e2 ef             	and    $0xffffffef,%edx
8010783a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010783d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107840:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107844:	83 e2 df             	and    $0xffffffdf,%edx
80107847:	88 50 7e             	mov    %dl,0x7e(%eax)
8010784a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107851:	83 ca 40             	or     $0x40,%edx
80107854:	88 50 7e             	mov    %dl,0x7e(%eax)
80107857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010785e:	83 ca 80             	or     $0xffffff80,%edx
80107861:	88 50 7e             	mov    %dl,0x7e(%eax)
80107864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107867:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010786b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107875:	ff ff 
80107877:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010787a:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107881:	00 00 
80107883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107886:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010788d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107890:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107897:	83 e2 f0             	and    $0xfffffff0,%edx
8010789a:	83 ca 02             	or     $0x2,%edx
8010789d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078ad:	83 ca 10             	or     $0x10,%edx
801078b0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078c0:	83 e2 9f             	and    $0xffffff9f,%edx
801078c3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078cc:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078d3:	83 ca 80             	or     $0xffffff80,%edx
801078d6:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078df:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078e6:	83 ca 0f             	or     $0xf,%edx
801078e9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f2:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078f9:	83 e2 ef             	and    $0xffffffef,%edx
801078fc:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107902:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107905:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010790c:	83 e2 df             	and    $0xffffffdf,%edx
8010790f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107915:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107918:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010791f:	83 ca 40             	or     $0x40,%edx
80107922:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010792b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107932:	83 ca 80             	or     $0xffffff80,%edx
80107935:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010793b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107948:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010794f:	ff ff 
80107951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107954:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010795b:	00 00 
8010795d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107960:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107971:	83 e2 f0             	and    $0xfffffff0,%edx
80107974:	83 ca 0a             	or     $0xa,%edx
80107977:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010797d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107980:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107987:	83 ca 10             	or     $0x10,%edx
8010798a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107993:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010799a:	83 ca 60             	or     $0x60,%edx
8010799d:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079ad:	83 ca 80             	or     $0xffffff80,%edx
801079b0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079c0:	83 ca 0f             	or     $0xf,%edx
801079c3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079cc:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079d3:	83 e2 ef             	and    $0xffffffef,%edx
801079d6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079df:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079e6:	83 e2 df             	and    $0xffffffdf,%edx
801079e9:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079f2:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079f9:	83 ca 40             	or     $0x40,%edx
801079fc:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a05:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a0c:	83 ca 80             	or     $0xffffff80,%edx
80107a0f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a18:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a22:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107a29:	ff ff 
80107a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a2e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107a35:	00 00 
80107a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a44:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a4b:	83 e2 f0             	and    $0xfffffff0,%edx
80107a4e:	83 ca 02             	or     $0x2,%edx
80107a51:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a61:	83 ca 10             	or     $0x10,%edx
80107a64:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a6d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a74:	83 ca 60             	or     $0x60,%edx
80107a77:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a80:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a87:	83 ca 80             	or     $0xffffff80,%edx
80107a8a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a93:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a9a:	83 ca 0f             	or     $0xf,%edx
80107a9d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107aad:	83 e2 ef             	and    $0xffffffef,%edx
80107ab0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ac0:	83 e2 df             	and    $0xffffffdf,%edx
80107ac3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107ac9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107acc:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ad3:	83 ca 40             	or     $0x40,%edx
80107ad6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107adf:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ae6:	83 ca 80             	or     $0xffffff80,%edx
80107ae9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107af2:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afc:	05 b4 00 00 00       	add    $0xb4,%eax
80107b01:	89 c3                	mov    %eax,%ebx
80107b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b06:	05 b4 00 00 00       	add    $0xb4,%eax
80107b0b:	c1 e8 10             	shr    $0x10,%eax
80107b0e:	89 c1                	mov    %eax,%ecx
80107b10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b13:	05 b4 00 00 00       	add    $0xb4,%eax
80107b18:	c1 e8 18             	shr    $0x18,%eax
80107b1b:	89 c2                	mov    %eax,%edx
80107b1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b20:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107b27:	00 00 
80107b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b2c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b36:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107b3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b3f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b46:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b49:	83 c9 02             	or     $0x2,%ecx
80107b4c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b55:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b5c:	83 c9 10             	or     $0x10,%ecx
80107b5f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b68:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b6f:	83 e1 9f             	and    $0xffffff9f,%ecx
80107b72:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b82:	83 c9 80             	or     $0xffffff80,%ecx
80107b85:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b95:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b98:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ba8:	83 e1 ef             	and    $0xffffffef,%ecx
80107bab:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107bbb:	83 e1 df             	and    $0xffffffdf,%ecx
80107bbe:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107bce:	83 c9 40             	or     $0x40,%ecx
80107bd1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bda:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107be1:	83 c9 80             	or     $0xffffff80,%ecx
80107be4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bed:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf6:	83 c0 70             	add    $0x70,%eax
80107bf9:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107c00:	00 
80107c01:	89 04 24             	mov    %eax,(%esp)
80107c04:	e8 37 fb ff ff       	call   80107740 <lgdt>
  loadgs(SEG_KCPU << 3);
80107c09:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107c10:	e8 6a fb ff ff       	call   8010777f <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c18:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107c1e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107c25:	00 00 00 00 
}
80107c29:	83 c4 24             	add    $0x24,%esp
80107c2c:	5b                   	pop    %ebx
80107c2d:	5d                   	pop    %ebp
80107c2e:	c3                   	ret    

80107c2f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107c2f:	55                   	push   %ebp
80107c30:	89 e5                	mov    %esp,%ebp
80107c32:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107c35:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c38:	c1 e8 16             	shr    $0x16,%eax
80107c3b:	c1 e0 02             	shl    $0x2,%eax
80107c3e:	03 45 08             	add    0x8(%ebp),%eax
80107c41:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107c44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c47:	8b 00                	mov    (%eax),%eax
80107c49:	83 e0 01             	and    $0x1,%eax
80107c4c:	84 c0                	test   %al,%al
80107c4e:	74 17                	je     80107c67 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107c50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c53:	8b 00                	mov    (%eax),%eax
80107c55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107c5a:	89 04 24             	mov    %eax,(%esp)
80107c5d:	e8 4a fb ff ff       	call   801077ac <p2v>
80107c62:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c65:	eb 4b                	jmp    80107cb2 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107c67:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107c6b:	74 0e                	je     80107c7b <walkpgdir+0x4c>
80107c6d:	e8 51 af ff ff       	call   80102bc3 <kalloc>
80107c72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c75:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107c79:	75 07                	jne    80107c82 <walkpgdir+0x53>
      return 0;
80107c7b:	b8 00 00 00 00       	mov    $0x0,%eax
80107c80:	eb 41                	jmp    80107cc3 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107c82:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c89:	00 
80107c8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c91:	00 
80107c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c95:	89 04 24             	mov    %eax,(%esp)
80107c98:	e8 09 d5 ff ff       	call   801051a6 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107c9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca0:	89 04 24             	mov    %eax,(%esp)
80107ca3:	e8 f7 fa ff ff       	call   8010779f <v2p>
80107ca8:	89 c2                	mov    %eax,%edx
80107caa:	83 ca 07             	or     $0x7,%edx
80107cad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107cb0:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107cb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cb5:	c1 e8 0c             	shr    $0xc,%eax
80107cb8:	25 ff 03 00 00       	and    $0x3ff,%eax
80107cbd:	c1 e0 02             	shl    $0x2,%eax
80107cc0:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107cc3:	c9                   	leave  
80107cc4:	c3                   	ret    

80107cc5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107cc5:	55                   	push   %ebp
80107cc6:	89 e5                	mov    %esp,%ebp
80107cc8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107cd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107cd6:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cd9:	03 45 10             	add    0x10(%ebp),%eax
80107cdc:	83 e8 01             	sub    $0x1,%eax
80107cdf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ce4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107ce7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107cee:	00 
80107cef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf2:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80107cf9:	89 04 24             	mov    %eax,(%esp)
80107cfc:	e8 2e ff ff ff       	call   80107c2f <walkpgdir>
80107d01:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d04:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d08:	75 07                	jne    80107d11 <mappages+0x4c>
      return -1;
80107d0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d0f:	eb 46                	jmp    80107d57 <mappages+0x92>
    if(*pte & PTE_P)
80107d11:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d14:	8b 00                	mov    (%eax),%eax
80107d16:	83 e0 01             	and    $0x1,%eax
80107d19:	84 c0                	test   %al,%al
80107d1b:	74 0c                	je     80107d29 <mappages+0x64>
      panic("remap");
80107d1d:	c7 04 24 bc 8b 10 80 	movl   $0x80108bbc,(%esp)
80107d24:	e8 14 88 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107d29:	8b 45 18             	mov    0x18(%ebp),%eax
80107d2c:	0b 45 14             	or     0x14(%ebp),%eax
80107d2f:	89 c2                	mov    %eax,%edx
80107d31:	83 ca 01             	or     $0x1,%edx
80107d34:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d37:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107d39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d3c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d3f:	74 10                	je     80107d51 <mappages+0x8c>
      break;
    a += PGSIZE;
80107d41:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107d48:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107d4f:	eb 96                	jmp    80107ce7 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107d51:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107d52:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107d57:	c9                   	leave  
80107d58:	c3                   	ret    

80107d59 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107d59:	55                   	push   %ebp
80107d5a:	89 e5                	mov    %esp,%ebp
80107d5c:	53                   	push   %ebx
80107d5d:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107d60:	e8 5e ae ff ff       	call   80102bc3 <kalloc>
80107d65:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107d68:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107d6c:	75 0a                	jne    80107d78 <setupkvm+0x1f>
    return 0;
80107d6e:	b8 00 00 00 00       	mov    $0x0,%eax
80107d73:	e9 98 00 00 00       	jmp    80107e10 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107d78:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d7f:	00 
80107d80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d87:	00 
80107d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d8b:	89 04 24             	mov    %eax,(%esp)
80107d8e:	e8 13 d4 ff ff       	call   801051a6 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107d93:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107d9a:	e8 0d fa ff ff       	call   801077ac <p2v>
80107d9f:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107da4:	76 0c                	jbe    80107db2 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107da6:	c7 04 24 c2 8b 10 80 	movl   $0x80108bc2,(%esp)
80107dad:	e8 8b 87 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107db2:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107db9:	eb 49                	jmp    80107e04 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107dbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107dbe:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107dc4:	8b 50 04             	mov    0x4(%eax),%edx
80107dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dca:	8b 58 08             	mov    0x8(%eax),%ebx
80107dcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd0:	8b 40 04             	mov    0x4(%eax),%eax
80107dd3:	29 c3                	sub    %eax,%ebx
80107dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd8:	8b 00                	mov    (%eax),%eax
80107dda:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107dde:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107de2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107de6:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ded:	89 04 24             	mov    %eax,(%esp)
80107df0:	e8 d0 fe ff ff       	call   80107cc5 <mappages>
80107df5:	85 c0                	test   %eax,%eax
80107df7:	79 07                	jns    80107e00 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107df9:	b8 00 00 00 00       	mov    $0x0,%eax
80107dfe:	eb 10                	jmp    80107e10 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107e00:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107e04:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107e0b:	72 ae                	jb     80107dbb <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107e0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107e10:	83 c4 34             	add    $0x34,%esp
80107e13:	5b                   	pop    %ebx
80107e14:	5d                   	pop    %ebp
80107e15:	c3                   	ret    

80107e16 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107e16:	55                   	push   %ebp
80107e17:	89 e5                	mov    %esp,%ebp
80107e19:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107e1c:	e8 38 ff ff ff       	call   80107d59 <setupkvm>
80107e21:	a3 38 51 11 80       	mov    %eax,0x80115138
  switchkvm();
80107e26:	e8 02 00 00 00       	call   80107e2d <switchkvm>
}
80107e2b:	c9                   	leave  
80107e2c:	c3                   	ret    

80107e2d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107e2d:	55                   	push   %ebp
80107e2e:	89 e5                	mov    %esp,%ebp
80107e30:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107e33:	a1 38 51 11 80       	mov    0x80115138,%eax
80107e38:	89 04 24             	mov    %eax,(%esp)
80107e3b:	e8 5f f9 ff ff       	call   8010779f <v2p>
80107e40:	89 04 24             	mov    %eax,(%esp)
80107e43:	e8 4c f9 ff ff       	call   80107794 <lcr3>
}
80107e48:	c9                   	leave  
80107e49:	c3                   	ret    

80107e4a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107e4a:	55                   	push   %ebp
80107e4b:	89 e5                	mov    %esp,%ebp
80107e4d:	53                   	push   %ebx
80107e4e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107e51:	e8 49 d2 ff ff       	call   8010509f <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107e56:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e5c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e63:	83 c2 08             	add    $0x8,%edx
80107e66:	89 d3                	mov    %edx,%ebx
80107e68:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e6f:	83 c2 08             	add    $0x8,%edx
80107e72:	c1 ea 10             	shr    $0x10,%edx
80107e75:	89 d1                	mov    %edx,%ecx
80107e77:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e7e:	83 c2 08             	add    $0x8,%edx
80107e81:	c1 ea 18             	shr    $0x18,%edx
80107e84:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107e8b:	67 00 
80107e8d:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107e94:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107e9a:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ea1:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ea4:	83 c9 09             	or     $0x9,%ecx
80107ea7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ead:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107eb4:	83 c9 10             	or     $0x10,%ecx
80107eb7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ebd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ec4:	83 e1 9f             	and    $0xffffff9f,%ecx
80107ec7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ecd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ed4:	83 c9 80             	or     $0xffffff80,%ecx
80107ed7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107edd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ee4:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ee7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107eed:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ef4:	83 e1 ef             	and    $0xffffffef,%ecx
80107ef7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107efd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f04:	83 e1 df             	and    $0xffffffdf,%ecx
80107f07:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f0d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f14:	83 c9 40             	or     $0x40,%ecx
80107f17:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f1d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f24:	83 e1 7f             	and    $0x7f,%ecx
80107f27:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f2d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107f33:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f39:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107f40:	83 e2 ef             	and    $0xffffffef,%edx
80107f43:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107f49:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f4f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107f55:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f5b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107f62:	8b 52 08             	mov    0x8(%edx),%edx
80107f65:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107f6b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107f6e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107f75:	e8 ef f7 ff ff       	call   80107769 <ltr>
  if(p->pgdir == 0)
80107f7a:	8b 45 08             	mov    0x8(%ebp),%eax
80107f7d:	8b 40 04             	mov    0x4(%eax),%eax
80107f80:	85 c0                	test   %eax,%eax
80107f82:	75 0c                	jne    80107f90 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107f84:	c7 04 24 d3 8b 10 80 	movl   $0x80108bd3,(%esp)
80107f8b:	e8 ad 85 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107f90:	8b 45 08             	mov    0x8(%ebp),%eax
80107f93:	8b 40 04             	mov    0x4(%eax),%eax
80107f96:	89 04 24             	mov    %eax,(%esp)
80107f99:	e8 01 f8 ff ff       	call   8010779f <v2p>
80107f9e:	89 04 24             	mov    %eax,(%esp)
80107fa1:	e8 ee f7 ff ff       	call   80107794 <lcr3>
  popcli();
80107fa6:	e8 3c d1 ff ff       	call   801050e7 <popcli>
}
80107fab:	83 c4 14             	add    $0x14,%esp
80107fae:	5b                   	pop    %ebx
80107faf:	5d                   	pop    %ebp
80107fb0:	c3                   	ret    

80107fb1 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107fb1:	55                   	push   %ebp
80107fb2:	89 e5                	mov    %esp,%ebp
80107fb4:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107fb7:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107fbe:	76 0c                	jbe    80107fcc <inituvm+0x1b>
    panic("inituvm: more than a page");
80107fc0:	c7 04 24 e7 8b 10 80 	movl   $0x80108be7,(%esp)
80107fc7:	e8 71 85 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107fcc:	e8 f2 ab ff ff       	call   80102bc3 <kalloc>
80107fd1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107fd4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fdb:	00 
80107fdc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107fe3:	00 
80107fe4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe7:	89 04 24             	mov    %eax,(%esp)
80107fea:	e8 b7 d1 ff ff       	call   801051a6 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107fef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff2:	89 04 24             	mov    %eax,(%esp)
80107ff5:	e8 a5 f7 ff ff       	call   8010779f <v2p>
80107ffa:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108001:	00 
80108002:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108006:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010800d:	00 
8010800e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108015:	00 
80108016:	8b 45 08             	mov    0x8(%ebp),%eax
80108019:	89 04 24             	mov    %eax,(%esp)
8010801c:	e8 a4 fc ff ff       	call   80107cc5 <mappages>
  memmove(mem, init, sz);
80108021:	8b 45 10             	mov    0x10(%ebp),%eax
80108024:	89 44 24 08          	mov    %eax,0x8(%esp)
80108028:	8b 45 0c             	mov    0xc(%ebp),%eax
8010802b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010802f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108032:	89 04 24             	mov    %eax,(%esp)
80108035:	e8 3f d2 ff ff       	call   80105279 <memmove>
}
8010803a:	c9                   	leave  
8010803b:	c3                   	ret    

8010803c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010803c:	55                   	push   %ebp
8010803d:	89 e5                	mov    %esp,%ebp
8010803f:	53                   	push   %ebx
80108040:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108043:	8b 45 0c             	mov    0xc(%ebp),%eax
80108046:	25 ff 0f 00 00       	and    $0xfff,%eax
8010804b:	85 c0                	test   %eax,%eax
8010804d:	74 0c                	je     8010805b <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010804f:	c7 04 24 04 8c 10 80 	movl   $0x80108c04,(%esp)
80108056:	e8 e2 84 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010805b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108062:	e9 ad 00 00 00       	jmp    80108114 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010806d:	01 d0                	add    %edx,%eax
8010806f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108076:	00 
80108077:	89 44 24 04          	mov    %eax,0x4(%esp)
8010807b:	8b 45 08             	mov    0x8(%ebp),%eax
8010807e:	89 04 24             	mov    %eax,(%esp)
80108081:	e8 a9 fb ff ff       	call   80107c2f <walkpgdir>
80108086:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108089:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010808d:	75 0c                	jne    8010809b <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010808f:	c7 04 24 27 8c 10 80 	movl   $0x80108c27,(%esp)
80108096:	e8 a2 84 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010809b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010809e:	8b 00                	mov    (%eax),%eax
801080a0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080a5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801080a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ab:	8b 55 18             	mov    0x18(%ebp),%edx
801080ae:	89 d1                	mov    %edx,%ecx
801080b0:	29 c1                	sub    %eax,%ecx
801080b2:	89 c8                	mov    %ecx,%eax
801080b4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801080b9:	77 11                	ja     801080cc <loaduvm+0x90>
      n = sz - i;
801080bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080be:	8b 55 18             	mov    0x18(%ebp),%edx
801080c1:	89 d1                	mov    %edx,%ecx
801080c3:	29 c1                	sub    %eax,%ecx
801080c5:	89 c8                	mov    %ecx,%eax
801080c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801080ca:	eb 07                	jmp    801080d3 <loaduvm+0x97>
    else
      n = PGSIZE;
801080cc:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801080d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d6:	8b 55 14             	mov    0x14(%ebp),%edx
801080d9:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801080dc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801080df:	89 04 24             	mov    %eax,(%esp)
801080e2:	e8 c5 f6 ff ff       	call   801077ac <p2v>
801080e7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801080ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
801080ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801080f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801080f6:	8b 45 10             	mov    0x10(%ebp),%eax
801080f9:	89 04 24             	mov    %eax,(%esp)
801080fc:	e8 ec 9c ff ff       	call   80101ded <readi>
80108101:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108104:	74 07                	je     8010810d <loaduvm+0xd1>
      return -1;
80108106:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010810b:	eb 18                	jmp    80108125 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010810d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108114:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108117:	3b 45 18             	cmp    0x18(%ebp),%eax
8010811a:	0f 82 47 ff ff ff    	jb     80108067 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108120:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108125:	83 c4 24             	add    $0x24,%esp
80108128:	5b                   	pop    %ebx
80108129:	5d                   	pop    %ebp
8010812a:	c3                   	ret    

8010812b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010812b:	55                   	push   %ebp
8010812c:	89 e5                	mov    %esp,%ebp
8010812e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108131:	8b 45 10             	mov    0x10(%ebp),%eax
80108134:	85 c0                	test   %eax,%eax
80108136:	79 0a                	jns    80108142 <allocuvm+0x17>
    return 0;
80108138:	b8 00 00 00 00       	mov    $0x0,%eax
8010813d:	e9 c1 00 00 00       	jmp    80108203 <allocuvm+0xd8>
  if(newsz < oldsz)
80108142:	8b 45 10             	mov    0x10(%ebp),%eax
80108145:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108148:	73 08                	jae    80108152 <allocuvm+0x27>
    return oldsz;
8010814a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010814d:	e9 b1 00 00 00       	jmp    80108203 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108152:	8b 45 0c             	mov    0xc(%ebp),%eax
80108155:	05 ff 0f 00 00       	add    $0xfff,%eax
8010815a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010815f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108162:	e9 8d 00 00 00       	jmp    801081f4 <allocuvm+0xc9>
    mem = kalloc();
80108167:	e8 57 aa ff ff       	call   80102bc3 <kalloc>
8010816c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010816f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108173:	75 2c                	jne    801081a1 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108175:	c7 04 24 45 8c 10 80 	movl   $0x80108c45,(%esp)
8010817c:	e8 20 82 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108181:	8b 45 0c             	mov    0xc(%ebp),%eax
80108184:	89 44 24 08          	mov    %eax,0x8(%esp)
80108188:	8b 45 10             	mov    0x10(%ebp),%eax
8010818b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010818f:	8b 45 08             	mov    0x8(%ebp),%eax
80108192:	89 04 24             	mov    %eax,(%esp)
80108195:	e8 6b 00 00 00       	call   80108205 <deallocuvm>
      return 0;
8010819a:	b8 00 00 00 00       	mov    $0x0,%eax
8010819f:	eb 62                	jmp    80108203 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801081a1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081a8:	00 
801081a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801081b0:	00 
801081b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081b4:	89 04 24             	mov    %eax,(%esp)
801081b7:	e8 ea cf ff ff       	call   801051a6 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801081bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081bf:	89 04 24             	mov    %eax,(%esp)
801081c2:	e8 d8 f5 ff ff       	call   8010779f <v2p>
801081c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801081ca:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801081d1:	00 
801081d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
801081d6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081dd:	00 
801081de:	89 54 24 04          	mov    %edx,0x4(%esp)
801081e2:	8b 45 08             	mov    0x8(%ebp),%eax
801081e5:	89 04 24             	mov    %eax,(%esp)
801081e8:	e8 d8 fa ff ff       	call   80107cc5 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801081ed:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801081f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f7:	3b 45 10             	cmp    0x10(%ebp),%eax
801081fa:	0f 82 67 ff ff ff    	jb     80108167 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108200:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108203:	c9                   	leave  
80108204:	c3                   	ret    

80108205 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108205:	55                   	push   %ebp
80108206:	89 e5                	mov    %esp,%ebp
80108208:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010820b:	8b 45 10             	mov    0x10(%ebp),%eax
8010820e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108211:	72 08                	jb     8010821b <deallocuvm+0x16>
    return oldsz;
80108213:	8b 45 0c             	mov    0xc(%ebp),%eax
80108216:	e9 a4 00 00 00       	jmp    801082bf <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010821b:	8b 45 10             	mov    0x10(%ebp),%eax
8010821e:	05 ff 0f 00 00       	add    $0xfff,%eax
80108223:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108228:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010822b:	e9 80 00 00 00       	jmp    801082b0 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108230:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108233:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010823a:	00 
8010823b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010823f:	8b 45 08             	mov    0x8(%ebp),%eax
80108242:	89 04 24             	mov    %eax,(%esp)
80108245:	e8 e5 f9 ff ff       	call   80107c2f <walkpgdir>
8010824a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
8010824d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108251:	75 09                	jne    8010825c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108253:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010825a:	eb 4d                	jmp    801082a9 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
8010825c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010825f:	8b 00                	mov    (%eax),%eax
80108261:	83 e0 01             	and    $0x1,%eax
80108264:	84 c0                	test   %al,%al
80108266:	74 41                	je     801082a9 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010826b:	8b 00                	mov    (%eax),%eax
8010826d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108272:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108275:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108279:	75 0c                	jne    80108287 <deallocuvm+0x82>
        panic("kfree");
8010827b:	c7 04 24 5d 8c 10 80 	movl   $0x80108c5d,(%esp)
80108282:	e8 b6 82 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108287:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010828a:	89 04 24             	mov    %eax,(%esp)
8010828d:	e8 1a f5 ff ff       	call   801077ac <p2v>
80108292:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108295:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108298:	89 04 24             	mov    %eax,(%esp)
8010829b:	e8 8a a8 ff ff       	call   80102b2a <kfree>
      *pte = 0;
801082a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801082a9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801082b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801082b6:	0f 82 74 ff ff ff    	jb     80108230 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801082bc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801082bf:	c9                   	leave  
801082c0:	c3                   	ret    

801082c1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801082c1:	55                   	push   %ebp
801082c2:	89 e5                	mov    %esp,%ebp
801082c4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801082c7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801082cb:	75 0c                	jne    801082d9 <freevm+0x18>
    panic("freevm: no pgdir");
801082cd:	c7 04 24 63 8c 10 80 	movl   $0x80108c63,(%esp)
801082d4:	e8 64 82 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801082d9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801082e0:	00 
801082e1:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801082e8:	80 
801082e9:	8b 45 08             	mov    0x8(%ebp),%eax
801082ec:	89 04 24             	mov    %eax,(%esp)
801082ef:	e8 11 ff ff ff       	call   80108205 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801082f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801082fb:	eb 3c                	jmp    80108339 <freevm+0x78>
    if(pgdir[i] & PTE_P){
801082fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108300:	c1 e0 02             	shl    $0x2,%eax
80108303:	03 45 08             	add    0x8(%ebp),%eax
80108306:	8b 00                	mov    (%eax),%eax
80108308:	83 e0 01             	and    $0x1,%eax
8010830b:	84 c0                	test   %al,%al
8010830d:	74 26                	je     80108335 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010830f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108312:	c1 e0 02             	shl    $0x2,%eax
80108315:	03 45 08             	add    0x8(%ebp),%eax
80108318:	8b 00                	mov    (%eax),%eax
8010831a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010831f:	89 04 24             	mov    %eax,(%esp)
80108322:	e8 85 f4 ff ff       	call   801077ac <p2v>
80108327:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010832a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010832d:	89 04 24             	mov    %eax,(%esp)
80108330:	e8 f5 a7 ff ff       	call   80102b2a <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108335:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108339:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108340:	76 bb                	jbe    801082fd <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108342:	8b 45 08             	mov    0x8(%ebp),%eax
80108345:	89 04 24             	mov    %eax,(%esp)
80108348:	e8 dd a7 ff ff       	call   80102b2a <kfree>
}
8010834d:	c9                   	leave  
8010834e:	c3                   	ret    

8010834f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010834f:	55                   	push   %ebp
80108350:	89 e5                	mov    %esp,%ebp
80108352:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108355:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010835c:	00 
8010835d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108360:	89 44 24 04          	mov    %eax,0x4(%esp)
80108364:	8b 45 08             	mov    0x8(%ebp),%eax
80108367:	89 04 24             	mov    %eax,(%esp)
8010836a:	e8 c0 f8 ff ff       	call   80107c2f <walkpgdir>
8010836f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108372:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108376:	75 0c                	jne    80108384 <clearpteu+0x35>
    panic("clearpteu");
80108378:	c7 04 24 74 8c 10 80 	movl   $0x80108c74,(%esp)
8010837f:	e8 b9 81 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108384:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108387:	8b 00                	mov    (%eax),%eax
80108389:	89 c2                	mov    %eax,%edx
8010838b:	83 e2 fb             	and    $0xfffffffb,%edx
8010838e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108391:	89 10                	mov    %edx,(%eax)
}
80108393:	c9                   	leave  
80108394:	c3                   	ret    

80108395 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108395:	55                   	push   %ebp
80108396:	89 e5                	mov    %esp,%ebp
80108398:	53                   	push   %ebx
80108399:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010839c:	e8 b8 f9 ff ff       	call   80107d59 <setupkvm>
801083a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801083a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801083a8:	75 0a                	jne    801083b4 <copyuvm+0x1f>
    return 0;
801083aa:	b8 00 00 00 00       	mov    $0x0,%eax
801083af:	e9 f8 00 00 00       	jmp    801084ac <copyuvm+0x117>
  for(i = 0; i < sz; i += PGSIZE){
801083b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801083bb:	e9 c7 00 00 00       	jmp    80108487 <copyuvm+0xf2>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801083c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083ca:	00 
801083cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801083cf:	8b 45 08             	mov    0x8(%ebp),%eax
801083d2:	89 04 24             	mov    %eax,(%esp)
801083d5:	e8 55 f8 ff ff       	call   80107c2f <walkpgdir>
801083da:	89 45 ec             	mov    %eax,-0x14(%ebp)
801083dd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801083e1:	75 0c                	jne    801083ef <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
801083e3:	c7 04 24 7e 8c 10 80 	movl   $0x80108c7e,(%esp)
801083ea:	e8 4e 81 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P)){
801083ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083f2:	8b 00                	mov    (%eax),%eax
801083f4:	83 e0 01             	and    $0x1,%eax
801083f7:	85 c0                	test   %eax,%eax
801083f9:	0f 84 80 00 00 00    	je     8010847f <copyuvm+0xea>
      //panic("copyuvm: page not present");
      continue;
    }
    pa = PTE_ADDR(*pte);
801083ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108402:	8b 00                	mov    (%eax),%eax
80108404:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108409:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
8010840c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010840f:	8b 00                	mov    (%eax),%eax
80108411:	25 ff 0f 00 00       	and    $0xfff,%eax
80108416:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108419:	e8 a5 a7 ff ff       	call   80102bc3 <kalloc>
8010841e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108421:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108425:	74 71                	je     80108498 <copyuvm+0x103>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108427:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010842a:	89 04 24             	mov    %eax,(%esp)
8010842d:	e8 7a f3 ff ff       	call   801077ac <p2v>
80108432:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108439:	00 
8010843a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010843e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108441:	89 04 24             	mov    %eax,(%esp)
80108444:	e8 30 ce ff ff       	call   80105279 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108449:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010844c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010844f:	89 04 24             	mov    %eax,(%esp)
80108452:	e8 48 f3 ff ff       	call   8010779f <v2p>
80108457:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010845a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010845e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108462:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108469:	00 
8010846a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010846e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108471:	89 04 24             	mov    %eax,(%esp)
80108474:	e8 4c f8 ff ff       	call   80107cc5 <mappages>
80108479:	85 c0                	test   %eax,%eax
8010847b:	78 1e                	js     8010849b <copyuvm+0x106>
8010847d:	eb 01                	jmp    80108480 <copyuvm+0xeb>
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P)){
      //panic("copyuvm: page not present");
      continue;
8010847f:	90                   	nop
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108480:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108487:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010848a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010848d:	0f 82 2d ff ff ff    	jb     801083c0 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108493:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108496:	eb 14                	jmp    801084ac <copyuvm+0x117>
      continue;
    }
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108498:	90                   	nop
80108499:	eb 01                	jmp    8010849c <copyuvm+0x107>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
8010849b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010849c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010849f:	89 04 24             	mov    %eax,(%esp)
801084a2:	e8 1a fe ff ff       	call   801082c1 <freevm>
  return 0;
801084a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801084ac:	83 c4 44             	add    $0x44,%esp
801084af:	5b                   	pop    %ebx
801084b0:	5d                   	pop    %ebp
801084b1:	c3                   	ret    

801084b2 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801084b2:	55                   	push   %ebp
801084b3:	89 e5                	mov    %esp,%ebp
801084b5:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801084b8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801084bf:	00 
801084c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801084c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801084c7:	8b 45 08             	mov    0x8(%ebp),%eax
801084ca:	89 04 24             	mov    %eax,(%esp)
801084cd:	e8 5d f7 ff ff       	call   80107c2f <walkpgdir>
801084d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801084d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d8:	8b 00                	mov    (%eax),%eax
801084da:	83 e0 01             	and    $0x1,%eax
801084dd:	85 c0                	test   %eax,%eax
801084df:	75 07                	jne    801084e8 <uva2ka+0x36>
    return 0;
801084e1:	b8 00 00 00 00       	mov    $0x0,%eax
801084e6:	eb 25                	jmp    8010850d <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801084e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084eb:	8b 00                	mov    (%eax),%eax
801084ed:	83 e0 04             	and    $0x4,%eax
801084f0:	85 c0                	test   %eax,%eax
801084f2:	75 07                	jne    801084fb <uva2ka+0x49>
    return 0;
801084f4:	b8 00 00 00 00       	mov    $0x0,%eax
801084f9:	eb 12                	jmp    8010850d <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801084fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084fe:	8b 00                	mov    (%eax),%eax
80108500:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108505:	89 04 24             	mov    %eax,(%esp)
80108508:	e8 9f f2 ff ff       	call   801077ac <p2v>
}
8010850d:	c9                   	leave  
8010850e:	c3                   	ret    

8010850f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010850f:	55                   	push   %ebp
80108510:	89 e5                	mov    %esp,%ebp
80108512:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108515:	8b 45 10             	mov    0x10(%ebp),%eax
80108518:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010851b:	e9 8b 00 00 00       	jmp    801085ab <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108520:	8b 45 0c             	mov    0xc(%ebp),%eax
80108523:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108528:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010852b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010852e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108532:	8b 45 08             	mov    0x8(%ebp),%eax
80108535:	89 04 24             	mov    %eax,(%esp)
80108538:	e8 75 ff ff ff       	call   801084b2 <uva2ka>
8010853d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108540:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108544:	75 07                	jne    8010854d <copyout+0x3e>
      return -1;
80108546:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010854b:	eb 6d                	jmp    801085ba <copyout+0xab>
    n = PGSIZE - (va - va0);
8010854d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108550:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108553:	89 d1                	mov    %edx,%ecx
80108555:	29 c1                	sub    %eax,%ecx
80108557:	89 c8                	mov    %ecx,%eax
80108559:	05 00 10 00 00       	add    $0x1000,%eax
8010855e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108561:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108564:	3b 45 14             	cmp    0x14(%ebp),%eax
80108567:	76 06                	jbe    8010856f <copyout+0x60>
      n = len;
80108569:	8b 45 14             	mov    0x14(%ebp),%eax
8010856c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010856f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108572:	8b 55 0c             	mov    0xc(%ebp),%edx
80108575:	89 d1                	mov    %edx,%ecx
80108577:	29 c1                	sub    %eax,%ecx
80108579:	89 c8                	mov    %ecx,%eax
8010857b:	03 45 e8             	add    -0x18(%ebp),%eax
8010857e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108581:	89 54 24 08          	mov    %edx,0x8(%esp)
80108585:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108588:	89 54 24 04          	mov    %edx,0x4(%esp)
8010858c:	89 04 24             	mov    %eax,(%esp)
8010858f:	e8 e5 cc ff ff       	call   80105279 <memmove>
    len -= n;
80108594:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108597:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010859a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010859d:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801085a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085a3:	05 00 10 00 00       	add    $0x1000,%eax
801085a8:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801085ab:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801085af:	0f 85 6b ff ff ff    	jne    80108520 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801085b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801085ba:	c9                   	leave  
801085bb:	c3                   	ret    
